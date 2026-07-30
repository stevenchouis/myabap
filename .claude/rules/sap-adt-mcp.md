# sap-adt MCP 已知限制與 Workaround

> 2026-07-03 實測（本機 `adt-rfc-bridge`，`http://127.0.0.1:8410`，sap-client=130）。
> `adt-rfc-bridge` 是本機的 Python 橋接程式：接收 MCP Server（Eclipse Plugin「SAP ADT MCP Server for Claude Code」）以 HTTP 傳來的 ADT API 請求，轉成 RFC 呼叫（用自己保存的 Host IP/User/Password/Client/Router String）連進 SAP Host 再把結果回傳——這是 `.mcp.json` 裡 `sap-adt` 位址（區網固定 IP，如 `192.168.68.56:3000`）的**下一層**，只有跑 MCP Server 的那台電腦看得到，架構全貌見 README.md「架構說明」。
> bridge 埠號可能因環境而異；MCP server / bridge 版本更新後請重新驗證並更新本檔。

## 1. `sap_get_source` / `sap_object_structure` 讀不到 INCLUDE（HTTP 404）

工具一律組 `programs/programs` 路徑，但 INCLUDE 的 ADT 資源路徑是 `programs/includes`。

**Workaround**：直接對代理呼叫正確路徑：

```bash
curl 'http://127.0.0.1:8410/sap/bc/adt/programs/includes/<include名>/source/main?sap-client=130&sap-language=EN'
```

## 2. `sap_search_object` 永遠回 0 筆

對已知存在的物件（如 ZDQM0001）也查無結果，工具的搜尋包裝有問題（ADT 本身正常）。

**Workaround**：直接打 ADT quickSearch API，回 XML（含物件 URI、類型、套件）：

```bash
curl 'http://127.0.0.1:8410/sap/bc/adt/repository/informationsystem/search?operation=quickSearch&query=ZDQM*&maxResults=100&sap-client=130'
```

## 3. `sap_sql_query` 回空結果

連 T000 都查不到資料（columns/rows 皆空），SQL 查詢失效或無權限，目前無 workaround，勿依賴此工具。

## 4. `sap_syntax_check` 一律 HTTP 500（uriMappingError）

**Workaround**：直接呼叫 ADT checkruns API（POST 需先 GET `/sap/bc/adt/discovery` 帶 `x-csrf-token: fetch` 取得 token 與 cookie）：

```bash
curl -b "$JAR" -H "x-csrf-token: $TOKEN" \
  -H 'Content-Type: application/vnd.sap.adt.checkobjects+xml' \
  -X POST 'http://127.0.0.1:8410/sap/bc/adt/checkruns?reporters=abapCheckRun&sap-client=130' \
  --data '<?xml version="1.0" encoding="UTF-8"?><chkrun:checkObjectList xmlns:chkrun="http://www.sap.com/adt/checkrun" xmlns:adtcore="http://www.sap.com/adt/core"><chkrun:checkObject adtcore:uri="<物件URI>" chkrun:version="inactive"/></chkrun:checkObjectList>'
```

檢查 INCLUDE 時物件 URI 要帶 context 主程式：`/sap/bc/adt/programs/includes/<include>?context=%2fsap%2fbc%2fadt%2fprograms%2fprograms%2f<主程式>`。

## 5. 寫入/啟用 INCLUDE 的注意事項

- `sap_set_source` **可以**寫 INCLUDE（寫入成功），但自動啟用會失敗；`sap_activate` 對 INCLUDE 報「REPORT/PROGRAM statement is missing」。
- 啟用 INCLUDE 要用 activation API + `programs/includes` URI + context 主程式（格式同上），或請有 SAP GUI 的人在 SE38 啟用 inactive 版本。
- `sap_set_source` 留下的 ENQUEUE 鎖可能不釋放（SM12 顯示 MCP 連線帳號持鎖），導致後續啟用一直 403；SM12 清鎖無效時可能要重啟 MCP server 或改走 SE38。
- **2026-07-04 實測有效的清鎖法**：`sap_set_source` 每次都因自己殘留的鎖啟用 403（訊息「User XXX is currently editing …」）。同一 MCP session 用 `sap_lock` 重新取鎖拿到 lockHandle → `sap_unlock` 釋放 → 再打 activation API 就會成功，不用進 SM12。
- `sap_activate` 工具對 CLAS/INTF/PROG 也一律回 `{"success":false,"messages":[]}`（不只 INCLUDE），啟用一律走 activation API（token 固定是 `ADT-RFC-BRIDGE`，GET `/sap/bc/adt/discovery` 帶 `x-csrf-token: fetch` 可取得）。
- 傳給 `sap_set_source` 的原始碼是**原樣寫入**，不要對 `<>` 等符號做任何 HTML/XML 轉義；寫入後務必讀回 inactive 版本核對。
- 多物件（主程式＋INCLUDE）可以在**一個 activation 請求**裡放多個 `objectReference` 批次啟用。

## 6. 建立物件的限制與 workaround

- `sap_create_object` 只支援 `PROG/P`、`CLAS/OC`、`INTF/OI`、`FUGR/F`，且 **FUGR 實測回 400**（工具送出的 XML 無效）。
- INCLUDE / Function Group / FM 都要走 ADT API 直接 POST：
  - INCLUDE：POST `/sap/bc/adt/programs/includes`（Content-Type `...programs.includes.v2+xml`）
  - FUGR：POST `/sap/bc/adt/functions/groups`（`...functions.groups.v2+xml`）
  - FM：POST `/sap/bc/adt/functions/groups/<grp>/fmodules`（`...functions.fmodules.v3+xml`，body 帶 `containerRef`）
- **curl 傳中文會變 Big5 被 ADT 拒收（406 CharacterSetNotAcceptable）**：物件描述用英文，或把 body 先用 Write 工具存成 UTF-8 檔再 `--data-binary @file`。
- FM 原始碼寫入沒有 MCP 工具，要走完整 lock 流程：stateful session → POST `?_action=LOCK&accessMode=MODIFY` 取 lockHandle → PUT `source/main?lockHandle=...` → POST `?_action=UNLOCK` → activate。
- FM 原始碼**不可包含 `*"` 開頭的參數註解區塊**（HTTP 400 FUNC_ADT028），介面直接用 `FUNCTION name IMPORTING ... EXCEPTIONS ....` 的 inline 語法定義。

## 7. 類別 Test Classes include（CCAU）的建立與讀寫（2026-07-04 實測）

- 全域類別的測試類別放 testclasses include，沒有 MCP 工具，走 ADT API（stateful session + 類別的 lockHandle，流程同 FM 寫入）：
  1. 主類別先啟用（include 建立前若主類別全新未啟用，PUT 會回 500「CCAU does not have any inactive version」）
  2. **建立 include**：POST `/sap/bc/adt/oo/classes/<class>/includes?lockHandle=...`，Content-Type `application/vnd.sap.adt.oo.classincludes+xml`，body `<class:abapClassInclude ... adtcore:name="<CLASS>" class:includeType="testclasses"/>`
  3. **寫入**：PUT `/sap/bc/adt/oo/classes/<class>/includes/testclasses?lockHandle=...`（text/plain; charset=utf-8）
  4. UNLOCK 後整個類別一次 activation
- **讀取** testclasses 是 GET `/sap/bc/adt/oo/classes/<class>/includes/testclasses`（**不加** `/source/main`，加了回 404）。
- 快照檔名比照 abapGit：`<類別名>.clas.testclasses.abap`。
- `sap_run_unit_test` 工具正常可用，回 JSON 的逐方法 passed/failed。

## 8. DDIC 物件與 Message Class 的建立（2026-07-05 實測）

- **Domain**：POST `/sap/bc/adt/ddic/domains`（Content-Type `application/vnd.sap.adt.domains.v2+xml`），body 用 `doma:domain`（namespace `http://www.sap.com/dictionary/domain`），一次 POST 可帶 typeInformation/outputInformation/valueInformation（值域區間放 `doma:fixValue` 的 low+high，**區間會存但 `doma:text` 說明文字會被丟掉**）。建立後為 inactive，需再 activation。
- **Data Element**：POST `/sap/bc/adt/ddic/dataelements`（`...dataelements.v2+xml`），root 是 `blue:wbobj`（namespace `http://www.sap.com/wbobj/dictionary/dtel`）＋內層 `dtel:dataElement`。**schema 嚴格且欄位順序固定**：typeKind/typeName 之後必須有 dataType/dataTypeLength/dataTypeDecimals，四組 label 各自要 Label/Length/**MaxLength** 三件套，缺任一元素回 400 並指名缺什麼（照錯誤訊息補即可）。中文 label 用 UTF-8 檔 `--data-binary` 傳沒問題。
- **DE 的 POST 會收下 XML 但 Field Label 不落地**（201 回應會回聲標籤、實際沒存，SE11/SM30 看到 `+`）：POST 之後必須再走 lock+PUT 同一份 XML 才會存（2026-07-05 踩到，SM30 欄位標題全是 `+` 才發現）。
- **DDIC 物件的 LOCK 要用舊式 Accept**：`Accept: application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result`（messageclass 用的 `application/vnd.sap.adt.lock.result+xml` 對 dataelements 會回 NotAcceptable「Unsupported Media Type」）。
- **透明表**：source-based。先 POST `/sap/bc/adt/ddic/tables`（`...tables.v2+xml`，root `blue:blueSource`，只帶 name/description/packageRef 建空殼），再用 `sap_set_source`（objectType `TABL`）寫 DDL（`define table ... { }` 語法）。寫入後同樣殘留鎖，走 sap_lock→sap_unlock 清鎖再 activation。
- **Message Class**：POST `/sap/bc/adt/messageclass`（`application/vnd.sap.adt.messageclass.v1+xml`，root `mc:messageClass`，namespace `http://www.sap.com/adt/MessageClass`）。**POST 只收 metadata，body 裡的 `mc:messages` 會被忽略**；訊息要另走 stateful session：POST `?_action=LOCK&accessMode=MODIFY` 取 lockHandle → PUT 整份 XML（含所有 `mc:messages`，`&1` 寫成 `&amp;1`）→ UNLOCK。中文訊息文字同樣走 UTF-8 檔案上傳。
- Domain/DE/表可以放進**同一個 activation 請求**批次啟用，系統會自己排相依順序。
- **程式的 Text Symbols / Selection Texts 沒有 ADT REST API**（discovery 只有 SAP GUI 連結 `/sap/bc/adt/vit/wb/...`），只能在 SE38 → Goto → Text Elements 手動維護。缺 text-nnn 不擋啟用與語法檢查（只算警告），程式可先啟用再補文字。

## 9. 工具名稱與 `.claude/settings.json` 權限清單（2026-07-05 校正）

CLAUDE.md 的待補清單原本列著「確認 sap-adt 實際暴露的工具名稱是否跟 settings.json 一致」——實測發現**確實不一致**：settings.json 舊版寫的是駝峰式（`getObjectSource`、`setObjectSource`、`createObject`、`activateObjects`、`lock`／`unLock`…），但這個 MCP server 實際暴露的是底線式 `sap_xxx`（`sap_get_source`、`sap_set_source`、`sap_create_object`、`sap_activate`、`sap_lock`／`sap_unlock`…）。已於本次校正 settings.json，分類原則：

- **allow**（唯讀、無副作用，或改列為可逆操作免確認）：`sap_get_source`、`sap_object_structure`、`sap_syntax_check`、`sap_search_object`、`sap_usage_references`、`sap_run_unit_test`、`sap_inactive_objects`、`sap_abap_docu`、`sap_sql_query`（雖然第 3 節提到它目前回空，但語意上仍是讀取）、`sap-docs__*`、`sap_activate`、`sap_lock`、`sap_unlock`——這三個原本歸在 ask，但正常開發流程幾乎每次寫完程式都要跑一次（尤其第 5 節記載的殘留鎖 workaround：`sap_set_source` → `sap_lock` → `sap_unlock` → curl activation，一次寫入就要連續呼叫兩三次），且都是可逆的（重新鎖定、重新啟用都行，不會真的遺失東西），逐次確認只拖慢節奏、沒有多攔到風險，2026-07-12 改為 allow（同步更新 CLAUDE.md 措辭）；`sap_set_source`、`sap_create_object` 2026-07-13 起也改為 allow（使用者直接指示），理由同上——寫入/建立物件本身也是可逆操作（物件可以再次覆寫、$TMP 套件的訓練物件刪不掉也無妨，真正不可逆的刪除/釋放已經是 deny），逐次確認同樣只拖慢節奏；仍維持「動作前在對話中列出內容」的審核習慣，只是不再依賴權限彈窗。
- **ask**：`sap_atc_run`（會實際觸發 ATC 檢查跑批次，有執行成本，維持逐次確認）。
- **deny**：`sap_delete_object`、`sap_transport_release`、`sap_transport_delete`——**這三個是命名猜測的預留位**，目前這版 sap-adt MCP 並未實際暴露對應工具（截至 2026-07-05 的 `ToolSearch` 清單裡沒有刪除物件或傳輸釋放/刪除的工具，也沒有獨立的「建立傳輸請求」工具——`sap_create_object` / `sap_set_source` 的 `transport` 參數已內建代收傳輸單號）。若之後版本新增了對應工具，**務必先用 `/mcp` 或 `ToolSearch` 確認實際工具名稱**再更新這份 deny 清單；在那之前，刪除物件與釋放/刪除傳輸請求這類操作若真的需要執行，只能透過本檔前面章節寫的「直接呼叫 ADT API」workaround 手動進行，一律視為需要先給使用者確認的高風險操作，不得自主執行。

## 10. 外鍵（Foreign Key）、Search Help、資料預覽 API（2026-07-06 實測）

- **Domain 建立即使不設值域，也要帶空的 `<doma:fixValues/>`**：`doma:valueInformation` 底下缺這個元素會 400 `ExceptionInvalidData: System expected the element fixValues`（第 8 節原文只示範了有值域的情境，這裡補上無值域的情況）。
- **DDIC 表格 DDL 的外鍵語法**（`DEFINE TABLE` 內）：`WITH FOREIGN KEY` 子句是**同一個欄位宣告陳述式的一部分**，中間不能出現分號，分號只出現在整個 `WHERE` 子句最後：
  ```abap
  @AbapCatalog.foreignKey.label : 'Check Against Class'
  @AbapCatalog.foreignKey.screenCheck : true
  klasse : ztr21_klasse
    with foreign key [0..*,1] ztr21_class
      where mandt  = ztr21_stud.mandt
        and klasse = ztr21_stud.klasse;
  ```
  `[n,m]` 是 cardinality：`n`（外鍵表這側）可以是 `1` 或 `[0..1]`；`m`（檢查表這側）可以是 `1`、`[0..1]`、`[1..*]`、`[0..*]`。多筆 detail 對應 1 筆 header（如本例學生對班級）就是 `[0..*,1]`——SAP 官方文件 `ABENDDICDDL_DEFINE_TABLE_FORKEY` 用的範例正好是 `SPFLI` 外鍵到 `SCARR`，可直接套用同一套語法。這個修改走跟表格建立一樣的流程（`sap_get_source` 讀現況 → 整份改寫用 `sap_set_source` → 清鎖 → activation），**不會**清掉表裡既有的資料列（已實測確認）。
- **DDIC 外鍵只在畫面輸入（Dynpro/SM30）層級生效，Open SQL 完全不受影響**：`screenCheck : true` 不是資料庫層 constraint，程式用 `INSERT`/`UPDATE`/`MODIFY` 塞一個檢查表沒有的值一樣 `sy-subrc = 0` 會成功。這點容易讓人誤會 SAP DDIC 外鍵跟一般 RDBMS 的 FK constraint 一樣會擋寫入，實際上要擋程式層的髒資料得自己寫 `SELECT SINGLE` 檢查。
- **Search Help（SHLP）目前這個 MCP server／ADT 環境完全沒有寫入 API**：`/sap/bc/adt/discovery` 的 Dictionary workspace 沒有 searchhelps collection；`GET /sap/bc/adt/ddic/searchhelps/<name>` 一律 404；真正的 ADT 物件型別代碼是 `SHLP/DH`，掛在 `/sap/bc/adt/vit/wb/object_type/shlpdh/object_name/<name>`，但這個路徑只回**唯讀的 metadata stub**（沒有 `source` 或可編輯的 properties 子資源）。跟 Text Symbols 一樣屬於「只能 SE11/SE38 GUI 手動維護」的類別，`sap_get_source`/`sap_set_source` 的 objectType enum 也沒有 SHLP 這個值。
  - 但 **Data Element 的 XML schema 本身已經有 `<dtel:searchHelp>`／`<dtel:searchHelpParameter>` 欄位**（讀既有 DE 的 GET 回應可以看到），代表「掛」一個已存在的 Search Help 到 DE 理論上可以透過 PUT 做到——只是要先在 GUI 把 Search Help 本體建出來，這部分還沒實測驗證過。
- **`sap_sql_query` 回空結果時的替代方案**：ADT 的 Data Preview API 直接可用，能查到真實資料列：
  ```bash
  curl -b "$JAR" -H "x-csrf-token: ADT-RFC-BRIDGE" \
    -H 'Accept: application/vnd.sap.adt.datapreview.table.v1+xml' \
    -X POST 'http://127.0.0.1:8410/sap/bc/adt/datapreview/ddic?rowNumber=100&ddicEntityName=<TABLE>&sap-client=130'
  ```
  回傳 `dataPreview:tableData`/`columns`/`dataSet` 的 XML，可直接讀出欄位與資料列。
- **表格結構剛改完、馬上做 Data Preview 可能會噴 `ExceptionDataPreviewGeneral: Change made to a Dictionary structure while a program was running`**：即使換全新 session/cookie 也一樣，是 RFC bridge 的 preview session 快取了舊 nametab；先打一次 `GET /sap/bc/adt/datapreview/ddic/<TABLE>/metadata` 刷新，之後 Data Preview 就正常了。
- **Open SQL JOIN 的 `ON` 條件不能明寫 client 欄位（MANDT）**：`ON c~mandt = s~mandt AND ...` 會噴語法錯誤 `GYA`「The client field MANDT cannot be specified in the ON condition」——client-dependent 表之間的 JOIN，client 比對由編譯器自動處理，`ON` 子句只需要寫業務欄位。
- **Search Help 的 Selection Method 表，欄位一定要引用 Data Element，不能是內建型別**（2026-07-05 補測）：`ZTR21_CLASS-KLNAME` 一開始用 `abap.char(40)`（無 DE），SE11 建 Search Help 時該欄位當 Parameter 會導致 Activate 失敗（Search Help 需要 DE 才能解析欄位語意）。修法：另建一個 Domain＋DE（如 `ZTR21_KLNAME`），改表欄位型別引用該 DE，兩者都走第 8 節「Domain/DE 建立＋lock+PUT 補標籤」的標準流程，改完表定義後若 `sap_set_source` 回報 activation 403「User X is currently editing」，一樣是殘留鎖，走 `sap_lock`→`sap_unlock` 清鎖再手動打 activation API（第 5 節）即可。

## 11. Data Element 必填元素、Domain 離散固定值、SELECT 語法順序（2026-07-06 實測，ex23）

- **Data Element 建立要帶的元素比第 8 節記載的更多**：除了四組 label 三件套之外，`dtel:dataElement` 底下還必須有 `<dtel:searchHelp/>`、`<dtel:searchHelpParameter/>`、`<dtel:setGetParameter/>`、`<dtel:defaultComponentName/>` 這四個元素（可以是空的自我封閉標籤），缺任一個會 400「System expected the element '...searchHelp'」之類的訊息。保險做法：照抄一個既有 DE（如 `ZTR21_KLASSE`）GET 回來的完整 `dtel:dataElement` 欄位順序，改內容不要刪元素。
- **Domain 多筆離散固定值（跟第 8 節的「區間」不同）**：`doma:fixValue` 不帶 `doma:high`（或帶空的 `<doma:high/>`），只給 `doma:low`（單一合法值，如 `N`/`R`/`C`）+ 遞增的 `doma:position`，可以一次 POST 帶多筆 `doma:fixValue`。這種「單值、無 high」的固定值清單，**`doma:text` 說明文字這次有正確存下來並在啟用後讀得回來**——跟第 8 節記載的「區間 fixValue（low+high 表示範圍）的 text 會被丟掉」正好相反，值得對照：區間型的 fixValue 存不了 text，離散單值型的 fixValue 存得了。
- **`SELECT ... JOIN ... WHERE ... ORDER BY ... INTO TABLE @DATA(...)` 的欄位順序**：`ORDER BY` 要寫在 `INTO TABLE` **之前**，寫在後面會噴語法錯誤 `"ORDER" is not allowed here. "." is expected.`（第 10 節示範的 JOIN 沒有 `WHERE`、也沒把 `ORDER BY` 放在 `INTO TABLE` 之後，這次是帶 `WHERE` 的情境才踩到，保險起見 `ORDER BY` 一律寫在 `INTO TABLE` 前面）。

## 12. Transaction Code（T-code / TSTC）沒有 ADT REST API（2026-07-09 實測）

- 抓取 `/sap/bc/adt/discovery` 全文（約 162KB）搜尋 `transaction`／`tran`／`tstc` 關鍵字，**沒有找到任何 Transaction 物件的 collection**；比對到的字串全部是 CTS 傳輸請求（`/sap/bc/adt/cts/transports`、`/sap/bc/adt/cts/transportrequests`）或 XSLT Transformation，容易誤判但都不是 T-code。`sap_create_object` 工具本身也只支援 `PROG/P`／`CLAS/OC`／`INTF/OI`／`FUGR/F`（見第 6 節），沒有 T-code 型別。
- 結論：跟第 10 節記載的 **Search Help（SHLP）情況相同**，T-code（ADT 物件型別 `TRAN`）屬於「這個 sap-adt MCP／RFC bridge 環境完全沒有寫入 API，只能 SE93 GUI 手動建立」的類別，`sap_get_source`/`sap_set_source` 的 objectType enum 也沒有 TRAN。沒有實測是否存在類似 SHLP 的唯讀 `vit/wb/object_type/...` metadata stub（因為對建立需求沒有意義，未深入查證）。
- **「Report Transaction」type 的 T-code 搭配 Screen 1000 是正常組合，不是設定錯誤**：ABAP 報表程式若用 `PARAMETERS`/`SELECT-OPTIONS` 宣告選取畫面（而非自訂 Dynpro `CALL SCREEN`），系統會自動把該選取畫面視為 **Screen 1000**。所以 SE93 建 T-code 選「Program and selection screen (Report transaction)」、Screen 填 `1000`，對應的是程式的標準選取畫面，程式本身完全不需要有任何 `CALL SCREEN 1000` 或 PBO/PAI module。

## 13. DEC Domain 值域限制、SELECT 子句順序再一坑（2026-07-11 實測，ex25）

- **DEC 型別 Domain 的 Value Range 上下限必須是整數，即使欄位本身有小數位**：`ZTR25_SURPCT`（`DEC` length 6 decimals 2，想設值域 0.00～100.00）第一次帶 `doma:low>0.00</doma:low><doma:high>100.00</doma:high>` 啟用直接報錯 `Fixed value/limit 100.00 for data type DEC must be a whole positive number`——**限定值域的上下限不能帶小數點**，改成整數 `0`／`100` 才啟用成功（欄位本身還是可以存 `15.50` 這種小數值，只有值域邊界卡整數）。
- **DEC Domain 的 `length` 是「含小數點的總顯示字元數」，不是純數字位數**：一開始設 `length=5 decimals=2` 想存到 `100.00`，啟用報 `Length of fixed value/limit 100.00 > maximum number of positions (5)`——`100.00` 顯示要 6 個字元（含小數點），所以 `length` 至少要給 6；跟 INT4 之類整數 Domain「length 就是位數」的直覺不一樣，DEC 類型的 `length` 得把小數點也算進去。
- **`outputInformation-length` 抓不準沒關係，只是 Warning**：`length=6` 配 `outputLength=7` 啟用時系統回 `type="W"`（非 E）「Output length (7) is less than the calculated output length (8)」，**這是警告不是錯誤，照樣啟用成功**——DDIC 自己會用計算出來的正確輸出長度，POST/PUT 帶的 `outputInformation-length` 只是初始建議值，猜不準不影響啟用。
- **Open SQL 的 `UP TO n ROWS` 必須放在 `INTO` 子句之後**，不是接在 `ORDER BY` 後面直接寫：`... WHERE ... ORDER BY ... UP TO n ROWS.`（`INTO` 寫在最前面、跳過 ORDER BY 直接接 UP TO）會報 `"UP" is not allowed here. "." is expected.`；正確順序是 `... FROM ... WHERE ... ORDER BY ... INTO TABLE ... UP TO n ROWS.`——`INTO` 子句要嘛在 SELECT 欄位清單後面（最前段），要嘛在 `ORDER BY` 之後、`UP TO` 之前，兩種都合法，但 `UP TO` 永遠要接在 `INTO` 後面，不能直接接在 `ORDER BY` 後面。
- **欄位清單一旦用逗號分隔的新式寫法（`f~carrid, c~carrname, ...`），就算 `INTO` 用舊式 `CORRESPONDING FIELDS OF TABLE itab`（不帶 `@`），編譯器還是會判定整句進入「新式 Open SQL」模式，要求宿主變數必須加 `@` 跳脫**：不加會報 `If new Open SQL syntax is used, all host variables must be escaped using @. The variable GT_REV is not escaped.`——混用新舊寫法時，只要有一處觸發新式判定（逗號分隔欄位清單、`~` alias 等），全句的宿主變數都要補 `@`，不能只改觸發新式判定的那一段。
- **表格欄位直接用內建型別（如 `abap.char(1)`）在 SM30 會出現「標題是通用符號 `+`、也沒有 F4 選單」**：內建型別沒有 Data Element 可以提供欄位標籤，SM30 Table Maintenance Generator 找不到標籤只好顯示 `+`；也因為沒有 Domain 固定值清單，完全沒有下拉選單。**Workaround（比自建整組 Domain/DE 更省事）**：搜尋 SAP 有沒有現成的通用 Domain 可以重用——例如**通用是/否旗標**已經有標準 Domain `XFELD`（`X`＝ja／空白＝nein 兩個固定值都已內建），但它掛的標準 Data Element `XFELD` 本身故意不帶任何標籤（設計上留給各表自建）。做法：自建一個新 Data Element（`dtel:typeKind=domain`、`dtel:typeName=XFELD`），只補標籤，不用自己重建值域——這樣 SM30 欄位標題正常、F4 選單也順便免費拿到（實測於 `ZTR25_ACTIVE`，ex25）。

## 14. DDIC Table Type（TTYP）建立／修改：Content-Type 錯了會被靜默丟棄（2026-07-11 實測，ex25）

- **Table Type 沒有 MCP 工具**（`sap_get_source`/`sap_set_source` 的 objectType enum 沒有 TTYP），要走跟 Domain/DE 一樣的「stateful session：LOCK → PUT → UNLOCK → activation」流程，物件路徑是 `/sap/bc/adt/ddic/tabletypes/<name>`。
- **關鍵坑**：PUT 時 `Content-Type` 若寫成猜測值（如 `application/vnd.sap.adt.tabletypes.v2+xml`，仿照 Domain/DE 的複數＋v2 慣例），伺服器回 **415 Unsupported Media Type**——這種情況還算好抓；但若寫成別的接近值，實測發現**even worse：伺服器可能回 200 OK，卻把送出的 `ttyp:rowType`（`typeKind=dictionaryType, typeName=<表名>`）整個丟棄，啟用後 active 版本悄悄退回 `typeKind=predefinedAbapType, dataType=CHAR, length=1` 這個預設值，過程完全沒有錯誤訊息**，只有等到程式端用這個 Table Type 宣告 CHANGING 參數、`SELECT * INTO TABLE` 才會在啟用時噴出看似不相干的 `The work area "..." is not long enough.`，很難聯想到根因是 Table Type 本身沒存對。
- **正確 Content-Type**：`application/vnd.sap.adt.tabletype.v1+xml`（**單數** `tabletype`、**v1**，不是 v2）——這個值不是用猜的，是抓 `/sap/bc/adt/discovery` 全文找 `<app:collection href="/sap/bc/adt/ddic/tabletypes">` 底下的 `<app:accept>` 元素得到的，日後遇到其他 DDIC 物件型別 Content-Type 不確定時，優先用這個方法查證，比照抄其他物件的慣例猜測可靠。
- **診斷方法**：懷疑某個 DDIC 物件「寫入後沒真的存進去」時，用該物件的標準/既有物件當範本（本例用標準 Table Type `SFLIGHT_TAB2`，`GET /sap/bc/adt/ddic/tabletypes/sflight_tab2`）逐欄位比對，同時務必用 `?version=active` 讀回自己剛寫入啟用的版本確認欄位值，不要只看 PUT 的回應（PUT 回應可能是 `inactive` 版本、內容正確，但 activation 那一步仍可能因為別的原因跟預期不同）。
- **`ttyp:rowType` 用 `dictionaryType` 時，除了 `typeKind`/`typeName` 之外還要帶 `ttyp:builtInType`（`dataType=STRU`、`length=000000`、`decimals=000000`）與空的 `ttyp:rangeType`**：標準 Table Type 的 GET 回應即使是 dictionaryType 也帶著這個「看似多餘」的 builtInType 區塊，照抄不要省略，省略後系統的行為未知（本次修復是完整照抄 SFLIGHT_TAB2 的結構，沒有另外測試省略 builtInType 是否也會導致問題）。

## 15. `adt-rfc-bridge` 不能拿來測一般 SICF HTTP Service（2026-07-12 實測，REST 課程 rs01/rs02）

- 在 SICF 掛好 Handler Class（`CL_REST_HTTP_HANDLER` 子類）並 Activate 後，若使用者當下不在能連到 SAP Host 內網的環境（例如在外網、只靠 SAP GUI 透過 SAProuter/dispatcher 連線），瀏覽器直接測那個 REST Service URL 會連不到——這是預期行為，不是設定錯誤：SAP GUI 走的是 dispatcher 連線（Activate 這類後端維護動作不受影響），但瀏覽器測 HTTP Service 走的是 ICM 的 HTTP Port，是完全不同的一條連線路徑，目前只有內網（或 VPN）走得通。
- **不能**拿 `adt-rfc-bridge`（`127.0.0.1:8410`）當跳板繞過這個限制：直接 curl 打 `http://127.0.0.1:8410/sap/bc/<自訂 SICF 路徑>`（例如 `/sap/bc/zrest_training/rs01/hello`）會回 `404 No application class found for URI: ...`。這代表 bridge 只認得它自己內部映射的 ADT 專用路徑（`/sap/bc/adt/*`），不是通用的 HTTP-to-RFC 轉發器，沒辦法用來呼叫任意 SICF Service。
- **結論**：自訂 SICF Service（REST 課程、或其他掛 Handler Class 的服務）的瀏覽器/Postman 實測，只能在使用者連得到 SAP Host 內網（或透過 VPN）的環境下進行，沒有繞過內網限制的 workaround；Claude 這邊能做的只有確認物件已建立、已啟用、程式邏輯正確，實際連線測試要等使用者回到內網環境再做。
- **`GET_ROOT_HANDLER` 直接回傳 `CL_REST_RESOURCE` 子類實例（未用 `CL_REST_ROUTER`）時，Resource 完全不檢查剩餘 URI 路徑**：`CL_REST_RESOURCE~DO_HANDLE` 只依 HTTP 方法（GET/POST/…）dispatch，不看路徑，所以像 rs01 這種「一個 service 只有一個資源」的設計，`/sap/bc/zrest_training/rs01`（不帶任何子路徑）跟 `/sap/bc/zrest_training/rs01/hello`（帶任意子路徑）會呼叫到同一個 `GET` 方法、回傳完全一樣的內容——只有用 `CL_REST_ROUTER~ATTACH` 註冊過路由的 Service（如 rs02）才會真的依路徑分流，路徑不對會是 404。

## 16. AMDP／CDS DDL Source（Table Function）建立與簽章規則（2026-07-19 實測，AMDP 課程 am01~am09）

- **AMDP Method 是普通 `CLAS/OC`**，`sap_create_object`/`sap_set_source` 都支援，不需要 workaround；但簽章規則跟一般 ABAP Method 不同：
  - **所有 `IMPORTING`/`EXPORTING` 參數都要 `VALUE(...)`**，不能是傳址參數，違反會在啟用時報 `In an AMDP context, the parameter "..." cannot be defined as a reference parameter`
  - **`DEFAULT` 值只能是常數/字面值，不能是 `sy-mandt` 這類系統欄位**（一般 ABAP Method 允許 `DEFAULT sy-mandt`，AMDP 不允許），報錯訊息是 `the default value of the parameter "..." must be a constant or literal`
  - 只有 `IMPORTING`/`EXPORTING`，沒有 `RETURNING`/`CHANGING`；`EXPORTING` 可以宣告多個 Table Type 參數（一次呼叫回傳多個獨立結果集）
- **AMDP 完全不會像 Open SQL 自動處理 Client（MANDT）**：SQLScript 直接對 HANA 底層實體表操作，`SELECT * FROM <client-dependent 表>` 撈到的是「所有 Client」的資料，訓練/測試系統常常多 Client 灌了同一批示範資料，會撈出重複列——一定要自己在 SQLScript 手動 `WHERE mandt = :iv_mandt`（`iv_mandt` 當作 IMPORTING 參數傳入）。JOIN 條件同理，可以（且通常需要）明寫 `ON a.mandt = b.mandt`——這跟 Open SQL 的 JOIN ON 條件**不能**寫 MANDT（本檔第 10 節）正好相反，因為 Open SQL 那層是 ABAP 編譯器自動處理 Client 比對，SQLScript 沒有這層。
- **AMDP 方法簽章的 `USING` 子句，多個資料庫物件是空白分隔，不是逗號**：`USING scarr sflight.` 才對，`USING scarr, sflight.` 會在 ABAP 編譯階段（不是 SQLScript 階段）報 `Comma without preceding colon (after METHOD ?)`。
- **SQLScript 的 `FOR <var> AS <cursor>` 迴圈，`<cursor>` 必須是先用 `DECLARE CURSOR <名稱> FOR <SELECT>;` 宣告好的具名游標，不能直接內嵌一句 `SELECT`**（`FOR cur_row AS SELECT ... DO` 會報 `sql syntax error: incorrect syntax near "SELECT"`）。
- **⚠️ `WHILE` 迴圈搭配手動 `OPEN`/`FETCH`/`CLOSE` 游標時，不要用 `DECLARE EXIT HANDLER FOR NOT FOUND` 當作「游標撈完了」的判斷依據**——這個寫法在這套系統（HANA 2.0 SPS04）**編譯完全正常、啟用也成功**，但實際執行時 Handler 沒有如預期被觸發，導致結束旗標永遠不變、造成**無窮迴圈**，曾經把整個 `adt-rfc-bridge` 卡到連最基本的 `discovery` 讀取請求都逾時無回應（2026-07-19 實測，AMDP 課程 am03，事後系統自行恢復，過程中無法主動中斷，只能等待或請使用者到 SAP GUI SM50/SM66 手動處理）。**安全的替代寫法**：先用 `SELECT COUNT(*) INTO lv_total FROM ...` 算出固定筆數，`WHILE lv_idx < lv_total DO ... FETCH ...; lv_idx := lv_idx + 1; END WHILE;`——用一個「每圈保證遞增、跟一個固定上限比較」的條件當結束依據，不管 `FETCH`/游標實際行為是否符合預期，迴圈都保證在有限次數內結束，不會無窮迴圈。**任何 SQLScript `WHILE` 迴圈，執行前務必先確認結束條件是不是「不管內部邏輯對不對都保證會終止」，不要依賴一個沒有百分之百把握會被觸發的機制**（例如某個 Handler、Callback）。
- **SQLScript 的行內註解是 `--`，不是 ABAP 的 `"`**：用 `"..."` 會被當成字串字面值語法，跨行會報 `Literals that span lines are not allowed in the body of a method that implements a database procedure`。
- **AMDP 方法本體（SQLScript 部分）只能用 ASCII 7-bit 字元，包含 `--` 註解裡也不行**：放中文（或其他非 ASCII 字元）會在啟用時報警告 `Only ASCII 7 bit characters are allowed in AMDP procedures. Control characters are not allowed.`——雖然只是警告（不擋啟用），但 AMDP／SQLScript 原始碼裡的說明文字一律要用英文，跟一般 ABAP 程式碼可以自由用中文註解不同。
- **SQLScript 用 `SIGNAL` 主動拋錯，條件名稱要先 `DECLARE <名稱> CONDITION FOR SQL_ERROR_CODE <代碼>;` 宣告，不能直接當內建名稱用**（就算取名 `SQLSCRIPT_ERROR` 這種看起來像保留字的名字也一樣，會報 `identifier must be declared`）。ABAP 端呼叫要 `RAISING cx_amdp_error` + `TRY...CATCH cx_amdp_error` 攔截，`get_text( )` 拿到的是技術性訊息（含程序名/行號位置），自訂錯誤文字埋在整段訊息最後面，不適合直接顯示給終端使用者。
- **CDS Table Function（`DEFINE TABLE FUNCTION`）沒有 MCP 工具支援，`sap_create_object`/`sap_get_source`/`sap_set_source` 的 objectType 沒有這個選項**，要走 ADT API workaround：
  - Discovery 文件裡 `ABAP DDL Sources` collection 的 href 是 `/sap/bc/adt/ddic/ddl/sources`，`Accept`/`Content-Type` 是 `application/vnd.sap.adt.ddlSource+xml`
  - POST 建空殼時，body 的 root element **不是**直覺會猜的 `blue:blueSource`（那是表格/其他 DDIC 物件用的），是 `ddlSource:ddlSource`（namespace `http://www.sap.com/adt/ddic/ddlsources`），這個正確 root 是**從第一次 POST 錯誤訊息**（`System expected the element '{...}ddlSource'`）直接得知的，不是用猜的：
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <ddlSource:ddlSource xmlns:ddlSource="http://www.sap.com/adt/ddic/ddlsources" xmlns:adtcore="http://www.sap.com/adt/core"
      adtcore:name="ZTF_XXX" adtcore:type="DDLS/DF" adtcore:description="...">
      <adtcore:packageRef adtcore:name="$TMP"/>
    </ddlSource:ddlSource>
    ```
  - 建好空殼後，用 `sap_set_source`（`objectType: DDLS`）寫入實際的 `define table function ... returns { ... } implemented by method ...;` 內容，跟其他 DDIC 物件一樣會留殘留鎖（`sap_lock` → `sap_unlock` → curl activation 的標準流程，見本檔第 5 節）
  - **DDL Source 跟實作它的 AMDP 類別互相引用**（DDL 的 `implemented by method` 指向類別、類別的 `FOR TABLE FUNCTION` 指向 DDL），兩者要放在**同一次 activation 請求**裡批次啟用，先啟用任一個都會因為對方還不存在而失敗
  - 底層資料如果是 Client 相關的表，`returns` 結構**第一個欄位必須是 `abap.clnt` 型別**（系統自動偵測、要求，報錯訊息 `... is marked as client-specific; type field ... is CHAR (not CLNT)`）；補上 `mandt : abap.clnt;` 放第一位之後，AMDP 方法的 `RETURN SELECT` 欄位清單第一個也要對應是這個 mandt 欄位——**加了這個 CLNT 欄位之後，透過 Open SQL `SELECT ... FROM <table function>` 查詢會自動做 Client 過濾**，這是「AMDP 不自動處理 Client」這條通用規則在 Table Function 情境下的例外（過濾發生在 CDS 框架層，不是 SQLScript 本體）
  - **實作 Table Function 的 AMDP 方法，關鍵字要用 `BY DATABASE FUNCTION`，不是一般 AMDP Method 的 `BY DATABASE PROCEDURE`**（報錯 `"..." implements the CDS table function "...", but "..." is not a database function`），本體最後用 `RETURN SELECT ...;`（單一結果集，沒有 `EXPORTING` 參數）；`FOR TABLE FUNCTION <cds名稱>` 只出現在 `CLASS DEFINITION` 的方法宣告，`IMPLEMENTATION` 裡的方法本體宣告仍是 `FOR HDB LANGUAGE SQLSCRIPT`（複製前者的語法到後者會報 `"HDB LANGUAGE SQLSCRIPT" expected after "FOR"`）
- **`cl_salv_table`／`REUSE_ALV_GRID_DISPLAY` 這類會開全螢幕畫面的呼叫，沒辦法透過 ADT 的無頭 `programrun` API（`/sap/bc/adt/programs/programrun/<程式>`）驗證**：headless 呼叫會卡住等待畫面互動、最終連線逾時（`RFC_CLOSED`）。`programrun` 只能驗證 Classical List（`WRITE`）輸出；有 ALV 的題目要先臨時把輸出換成 `WRITE` 驗證資料邏輯，確認正確後再換回 ALV 版本，畫面效果本身要請使用者在 SAP GUI 手動確認。
- **`cl_salv_table` 的欄位標題是靠 RTTI 讀取欄位對應的 Data Element 說明文字自動生成的**：如果欄位型別是 CDS/ABAP 的內建型別（如 `abap.int4`/`abap.dec(...)`）、沒有掛 Data Element，標題會是空白（不會 fallback 成技術欄位名）——要用 `lo_alv->get_columns( )->get_column( '<欄位名>' )->set_medium_text( '<標題>' )` 手動補；跟 `REUSE_ALV_GRID_DISPLAY` 手動組 `IT_FIELDCAT`（本檔前面 AMDP 課程 am06 教材提到）是同一個根本原因（欄位沒有 Data Element 可用）在兩種 ALV API 上的不同呈現方式。
- **AMDP 第一次呼叫比後續呼叫慢很多**（實測一個 JOIN+CTE 查詢第一次 208ms、後續降到 2~13ms），合理解釋是 HANA 第一次執行某個 Database Procedure/Function 要編譯執行計畫，編譯結果會被快取——這代表 Code-to-Data 下推的效益要考慮呼叫頻率，低頻呼叫（跑一次的批次報表）可能因為編譯成本而「感覺」沒有比 ABAP 迴圈版本快，高頻重複呼叫才會真正吃到快取＋減少資料搬移的雙重好處。

## 17. 字串模板 CASE 格式選項語法、`programrun` API 要用 POST（2026-07-19 實測，基礎課 ex26）

- **字串模板 `{ dobj CASE = ... }` 格式選項不能加括號寫成 `CASE = (UPPER)`**：這是動態參照語法（`(dobj)`，指向一個內容為 `'RAW'`/`'UPPER'`/`'LOWER'` 的變數），系統會去找一個叫 `UPPER` 的資料物件，找不到就在啟用時報 `Field "UPPER" is unknown.`——正確的靜態寫法是不加括號的關鍵字常數 `CASE = UPPER`（`RAW`/`UPPER`/`LOWER` 三選一），跟 `ALIGN = LEFT/RIGHT/CENTER`、`SIGN = LEFT/...` 等其他格式選項的關鍵字用法一致；`(dobj)` 動態語法只有在真的要「執行期才決定用哪個格式」時才用得到。完整格式選項清單可查 ABAP 官方文件 `ABAPCOMPUTE_STRING_FORMAT_OPTIONS`。
- **`sap_activate` 工具回 `{"success":false,"messages":[]}` 不代表真的失敗**：本節踩到 `CASE = (UPPER)` 這個錯誤時，`sap_activate` 只回空陣列（延續第 9 節記載的「這個工具對 CLAS/INTF/PROG 一律回失敗、訊息通常是空的」的已知限制），實際錯誤內容是從**下一次 `sap_set_source`** 的 `activationError` 欄位才看到完整訊息（`HTTP 403` 或實際的編譯錯誤文字）。修正後重新 `sap_set_source` → `sap_lock`→`sap_unlock` 清鎖 → `sap_activate`，`sap_activate` 一樣回空陣列，這時要改用第 4 節的 `checkruns` API 或 `sap_inactive_objects`（回傳空清單代表沒有殘留未啟用版本）才能真正確認啟用成功，不能只看 `sap_activate` 的回應。
- **`programrun` 無頭執行 API 要用 `POST`，不是 `GET`**：`GET /sap/bc/adt/programs/programrun/<程式>` 會回 400/`ExceptionMethodNotSupported`（`Resource controller does not support method GET`）；換成 `POST` 同一個 URL（不帶 body，帶 `x-csrf-token` 與已建立 session 的 cookie）才會實際執行程式並把 Classical List 輸出以純文字回傳。第 16 節記載的「`cl_salv_table`/`REUSE_ALV_GRID_DISPLAY` 沒辦法用 `programrun` 驗證」限制依然成立，這裡補上的是「純 `WRITE` 輸出的程式該怎麼正確呼叫這支 API」。

## 18. `CALL FUNCTION` 不支援 inline `DATA(...)` 宣告、classic FM 的 `VALUE()` 參數在例外路徑會被清空、`datapreview/freestyle` 可以下真正的 WHERE 條件（2026-07-21 實測，Interface 課程 if05）

- **`CALL FUNCTION ... IMPORTING xxx = DATA(lv_yyy)` 語法不合法**：`inline` 宣告（`DATA(...)`）只有 Method 呼叫（`CALL METHOD`／函數式呼叫）支援，`CALL FUNCTION` 的 `EXPORTING`/`IMPORTING`/`TABLES`/`CHANGING` 一律要用**事先宣告好的變數**，啟用時報 `The inline declaration "DATA(LV_YYY)" is not possible in this position.`＋`Field "LV_YYY" is unknown.`（兩則訊息同時出現）。這跟 Method 呼叫可以自由用 `DATA(...)` 是明確的語法差異，容易在把 Method 呼叫的寫作習慣帶進 `CALL FUNCTION` 時踩到。
- **classic Function Module 用 `VALUE()` 宣告的 `EXPORTING` 參數，若該次呼叫因為 `EXCEPTIONS` 對應的例外被 `RAISE` 而提前結束，呼叫端變數還是會被覆寫成 FM 內部那個尚未賦值的空白值，不會維持呼叫前的原值**：這點違反直覺（很多人以為「例外路徑不會動到 EXPORTING 參數」），實測案例是標準 FM `FORMAT_MESSAGE`（`ID`/`NO`/`V1~V4` 找不到對應 `T100` 列時 `RAISE NOT_FOUND`，此時 `EXPORTING VALUE(MSG)` 仍會把呼叫端變數蓋成空白）——**正確寫法是呼叫後明確用 `sy-subrc` 判斷成敗，成功才把輸出參數的值採用，不要依賴「呼叫前先塞一個 fallback 值、指望例外路徑不覆寫它」這種寫法**（`ZCL_IF05_BDC_RUNNER=>format_messages` 一開始就是這樣寫錯，被 ABAP Unit 測試抓到才修正）。
- **驗證「某個訊息類別/號碼在 T100 是否存在」不要用猜的**：意外發現 `00`/`999` 在這套系統真的有資料（`Table extension for compression successful`），代表訊息類別 `00` 幾乎整個 001~999 號碼區間都填滿了，不能假設「隨便挑一個大號碼」就一定不存在。
- **`/sap/bc/adt/datapreview/freestyle` 這支端點可以直接下帶 `WHERE` 條件的 Open SQL `SELECT`**，比第 10 節記載的 `/sap/bc/adt/datapreview/ddic/<TABLE>` 好用（那支只能整表撈前 N 筆，不能篩選）：

  ```bash
  curl -b "$JAR" -H "x-csrf-token: ADT-RFC-BRIDGE" \
    -H 'Accept: application/vnd.sap.adt.datapreview.table.v1+xml' \
    -X POST 'http://127.0.0.1:8410/sap/bc/adt/datapreview/freestyle?rowNumber=20&sap-client=130' \
    --data-binary "SELECT ARBGB, MSGNR, TEXT FROM T100 WHERE ARBGB = '00' AND SPRSL = 'E' AND MSGNR = '999'"
  ```

  回應的 `dataPreview:totalRows` 可以直接拿來確認「這個條件到底有沒有資料」（例如驗證 `ARBGB = 'ZZ'` 真的 0 筆），比自己另外寫一支查詢程式再用 `programrun` 執行更快，之後需要「查一筆資料存不存在」都優先用這支。

## 19. Smartform／Style／SE78 完全沒有 ADT API（2026-07-21 實測，Smartform 課程 sf01 出題前查證）

- **確認方式**：抓 `/sap/bc/adt/discovery` 全文搜尋 `smart`／`style`／`form` 關鍵字，找不到任何 Smartform 或 Style 的 collection（只有 `datapreview/*/freestyle`、DDL formatter 等無關項目，字面剛好命中 `style`/`form` 但語意無關）；再用 `repository/informationsystem/objecttypes` 撈全部物件型別清單，也沒有 `Smart Forms`／`Style` 這個分類。用 ADT quickSearch（第 2 節 workaround）查 `SSF*` 只會找到 Smartform**框架底層**的 DDIC 物件（`SSFAPPL` 等 Data Element/Domain/Table、`SSFA` Function Group、`SSF01`/`SSF02` 程式），這些是 SAP 標準套件本身的元件，不是「使用者自建的某張 Smartform 表單」這個物件層級——ADT 完全不認得「Smartform」「Style」這兩種物件型別本身。
- **結論與 `ABAP_Training_Forms/README.md` 的推測一致**：`sap_create_object`/`sap_get_source`/`sap_set_source` 的 objectType enum 沒有、以後也不會有 Smartform/Style 的選項，這不是「這版 MCP server 還沒做」，是**整個 ADT 協定本身沒有涵蓋 `SMARTFORMS`/`SMARTSTYLES`/`SE78` 這幾個傳統 Dynpro 工具**（跟第 10 節 Search Help、第 12 節 T-code 屬於同一類「GUI-only、無 REST API」的物件，但比它們更徹底——連唯讀的 metadata stub 路徑，如 SHLP 那種 `vit/wb/object_type/...`，都沒找到對應的）。
- **對出題與教學的實務影響**：Smartform 課程（`src/ABAP_Training_Forms/`）裡任何要求「建立/修改 Smartform 本體」的步驟，一律只能寫成**操作指引**（`SMARTFORMS`/`SMARTSTYLES`/`SE78` 逐步該點哪裡、填什麼），由使用者在 SAP GUI 手動執行、Claude 事後靠使用者回報或讀「呼叫端程式」的執行結果做間接驗證；Claude 能直接建立/驗收的只有**呼叫端 ABAP 程式**（`PROG/P` 或 `CLAS/OC`，走 `SSF_FUNCTION_MODULE_NAME` 取得動態函式模組名稱後 `CALL FUNCTION`），這部分跟其他課程一樣可以走完整的 create→set_source→syntax check→programrun 驗證流程。
- **⚠️ 出題時曾誤把 `SE71` 當成 Smartform 的交易碼，被使用者當場抓到（sf01 教材第一版寫錯）**：`SE71` 是**前代 SAPscript**「表單」（SAP 物件分類叫 **Layout Set**）專用的交易碼，`SE72` 是 SAPscript「Style」；Smartform 對應的正確交易碼是**獨立的 `SMARTFORMS`**（表單）與 `SMARTSTYLES`（樣式），兩套系統完全不共用交易碼入口。**已用 ADT quickSearch 查證區分依據**：查 `SE71`/`SE72`/`SE78` 這三個交易碼物件（`TRAN/T` 型別），套件（`adtcore:packageName`）都是 `STXD`（SAPscript 系列）；查 `SMARTFORMS`/`SMARTSTYLES`，套件是 `SMART`——**套件不同就是兩套獨立工具的直接證據**，只有 `SE78`（圖形管理）是 SAPscript／Smartform 真正共用的工具（套件雖是 `STXD`，但功能設計上兩邊都會用到，不受這條「各自獨立」規則影響）。這個錯誤沒有實際執行後果（使用者在照做前發現不對），但提醒：**沒有 ADT API 可查證的 GUI-only 工具（T-code、Search Help、Smartform 這類），交易碼本身也不能憑記憶/直覺寫，一樣要用 ADT quickSearch 查 `TRAN/T` 物件的套件歸屬做交叉比對，不能只驗證「這個物件存在」就假設名稱或用途正確**。

## 20. Enhancement Framework（`ENHS`/`ENHO`/`ENHOXHH`）有 ADT API，但 Classic User-Exit（`SMOD`/`CMOD`）沒有（2026-07-28 實測，Enhancement 課程出題前查證）

- **確認方式**：抓 `/sap/bc/adt/discovery` 全文搜尋 `enh`／`badi` 關鍵字，找到三個正式 collection：`/sap/bc/adt/enhancements/enhoxh`（Enhancement Implementation，`application/vnd.sap.adt.enh.enho.v1+xml`）、`/sap/bc/adt/enhancements/enhoxhh`（Source Code Plugin，`...enhoxhh.v2+xml`）、`/sap/bc/adt/enhancements/enhsxs`（Enhancement Spot，`...enhs.v1+xml`）；`repository/informationsystem/objecttypes` 也列出對應物件型別 `ENHO/XH`、`ENHS/XS`、`ENHC/XF`（Composite Enhancement Implementation）、`ENSC/XT`（Composite Enhancement Spot）。用 ADT quickSearch 查 `ES_*` 能正常撈到系統既有標準 Enhancement Spot（如 `ES_ACE_DOCUMENT`，`adtcore:type="ENHS/XS"`）並取得可用物件 URI，證實這條 collection 至少讀取正常。**這三類（Enhancement Spot／BAdI 定義、Enhancement Implementation／BAdI 實作與 Explicit Enhancement 插入、Source Code Plugin／Implicit Enhancement Point）預期可以走跟 Domain/DE/Table Type 一樣的 stateful session 流程（LOCK→PUT→UNLOCK→activation，見第 5／8／14 節），但實際 XML schema 尚未查證，出題時要先 GET 一個既有標準 Enhancement Spot 當範本（比照 Domain/DE 建立時的做法）。**
- **另外查到 `/sap/bc/adt/businesslogicextensions/badis`（Business Logic Extensions／Key User Extensibility BAdI）＋`badinameproposals`（命名建議 API）**——這是 S/4HANA Cloud／ABAP Cloud 導向的簡化 BAdI 實作管道，跟 classic／new BAdI（SE18/SE19、Enhancement Spot）是不同世代機制，非本次查證重點。
- **Classic User-Exit（`SMOD`/`CMOD`，物件型別 `CMOD/XP`）沒有可寫入的 ADT collection**：discovery 全文找不到 `smod`/`cmod` 的 collection href（只有其他詞彙裡碰巧包含的子字串，如 `isModifiable`），但 `repository/informationsystem/objecttypes` **有**列出 `CMOD/XP`（Enhancement Projects）這個物件型別；quickSearch 查 `objectType=CMOD/XP` 能撈到既有 Project（如 `ZSD00001`），但物件 URI 落在 `/sap/bc/adt/vit/wb/object_type/cmodxp/object_name/<name>` 這種唯讀 metadata stub 路徑——跟第 10 節 Search Help、第 12 節 T-code 是同一類「只能在 objecttypes 目錄查得到、但沒有可寫入 collection」的 GUI-only 物件，Enhancement 指派到 Project、Activate Project 都要使用者在 SAP GUI（`CMOD`）手動操作。
- **✅ 已驗證（原推論成立，見第 21 節 Enhancement 課程 en02 完整案例）**：`CMOD` Project 指派後產生的 Function Exit Include（不論是舊式 `<group>ZZ<後綴>` 命名如 `V05EZZAG`，或新式 `ZX...U<nn>` 命名如 `ZXVBZU01`/`ZXVBZU02`）都是普通 **`PROG/I` Include**，可以用第 1 節「INCLUDE 讀寫 workaround」直接 `sap_get_source`/`sap_set_source` 讀寫。但**光是寫入原始碼並啟用，不代表 Enhancement 真的生效**——`CMOD` 的 Project／Assign／（雙擊 Component 觸發生成）／**Activate Project** 四步驟才是讓 Function Group 真正載入新程式碼的必要條件，缺 Activate Project 這一步，程式碼存在系統裡也不會被執行，這點原本判斷錯誤（見第 21 節「⚠️ 更正」）。

## 21. 用 `datapreview/freestyle` 查 `MODSAP`/`MODACT`/`TNRO`/`NRIV` 反查 Classic Enhancement 歸屬與 Number Range 設定；`ZX` 開頭 Include 是保留命名空間（2026-07-28 實測，Enhancement 課程 en02，批號自動給號真實案例）

- **`ZX` 開頭的 Include 名稱保留給 Exit Function Group 專用，無法用一般 ADT Include 建立 API（第 6 節）生出來**：POST `/sap/bc/adt/programs/includes` 建立一個全新的 `ZXVBZU01` 會被直接拒絕，回 `ExceptionResourceCreationFailure`：「Program names ZX... are reserved for includes of exit function groups」。這跟第 5 節記載的「舊式 `<group>ZZ<suffix>` 命名（如 `V05EZZAG`）可以正常讀寫」不同——`ZX...U<nn>` 這種新式 Customer Function 命名，Include 必須先在 SE37（雙擊該 Function Exit 觸發自動生成）或 CMOD 用 GUI 生出骨架，Claude 才能接著用 `sap_get_source`/`sap_set_source` 讀寫；如果這個骨架从未被任何人生成過，Claude 端目前無法自主建立。
- **classic Function Exit 的 Include 即使已經存在，也可能是「孤兒物件」——沒有掛在任何 CMOD Project 底下**：用 `sap_sql_query` 查不到（第 3 節已知限制），但 `/sap/bc/adt/datapreview/freestyle` 可以直接查兩張標準表反查：
  1. `SELECT * FROM MODSAP WHERE MEMBER = '<Function Exit 名>'` → 拿到 `NAME`（SAP Enhancement 名稱，如 `SAPLV01Z`）
  2. `SELECT * FROM MODACT WHERE NAME = '<Enhancement 名稱>'` → 有幾筆就代表被幾個 CMOD Project 指派過；`0` 筆代表**從未被任何 Project 正式指派**（`DEVCLASS`/`KORRNUM` 等欄位也是空的）

  本次案例：`EXIT_SAPLV01Z_002` 的 Include `ZXVBZU02` 雖然已經是套件 `ZPP` 的真實物件（2023-08-08 由其他使用者建立），但 `MODACT` 查 `SAPLV01Z` 回 0 筆——證實是當年被雙擊觸發自動生成、但沒人接著建 Project／寫程式碼的殘留物件，且 SE10 也查無掛著這支物件的傳輸請求。**這類「已存在但沒人管」的 Include，寫入前務必先用這個方法查證歸屬，不能只看「內容是空的」就假設可以自由使用**——套件仍然是別人的套件，寫入需要對應套件的傳輸請求，且建議跟該套件的實際負責人確認過。
- **Number Range Object（`SNRO`，第 20 節已提過 GUI-only）的設定內容，可以同樣用 `datapreview/freestyle` 查標準表驗證，不用只靠使用者截圖**：
  - `SELECT OBJECT, DOMLEN, BUFFER FROM TNRO WHERE OBJECT = '<物件名>'` → `DOMLEN` 是這個 Number Range Object 的「Number Length Domain」欄位值（建立時 SNRO 畫面會要求填，不知道要填什麼時，可以先查一個功能相近的標準物件的 `DOMLEN` 照抄——本次查標準物件 `BATCH_CLT` 的 `DOMLEN = 'CHARG'`，證實新建的批號類 Number Range Object 應該沿用同一個 Domain）
  - `SELECT OBJECT, NRRANGENR, FROMNUMBER, TONUMBER, NRLEVEL, EXTERNIND FROM NRIV WHERE OBJECT = '<物件名>'` → 確認 Interval 的 From／To／目前用到哪裡（`NRLEVEL`）／是否為 External
- **`NUMBER_GET_NEXT` 的 `number` 輸出參數，不管 Number Range Object 的 Interval 定義多少位數，一律回傳 10 碼、左邊補零的數字字串**：已實測驗證（自建物件 `ZEN02BAT`，Interval `0000000001`~`9999999999`），連續呼叫 3 次分別拿到 `0000000001`／`0000000002`／`0000000003`，程式要自己決定「取哪一段當作實際要用的流水號」（本例取後 4 碼 `+6(4)`），不能假設回傳值長度會依業務需求自動縮短。
- **同一個標準給號流程，可能疊了三代擴充技術，全部依序執行、不互斥**：實測讀 `VB_NEXT_BATCH_NUMBER`（批號自動給號的核心 FM）原始碼，發現依序呼叫：① `GET BADI`/`CALL BADI`（新式 BAdI，走 Enhancement Spot 管理）② `CALL CUSTOMER-FUNCTION '001'`/`'002'`（Classic User-Exit，跟①參數幾乎一樣）③ 呼叫一個 Cloud BAdI 包裝類別（`g_badi_batch_number_cust`，S/4HANA Key User Extensibility）。這證實 SAP 新增擴充技術時**不會拿掉舊的**，同一個標準流程可能同時是三代技術的教學活教材，出題/查證時遇到「這個功能到底該用哪個擴充點」，值得完整讀一次呼叫端原始碼確認是否有多代並存，不要只查到其中一個就下結論。
- **正式套件（非 `$TMP`）物件寫入 `sap_set_source` 需要帶 `transport` 參數**，沒帶會報 `ExceptionParameterNotFound: Parameter corrNr could not be found`；帶了正確的既有傳輸請求號碼（本次為 `S4HK901982`，套件 `ZPP`）就能正常寫入，寫入後的殘留鎖 workaround（第 5 節：`sap_lock`→`sap_unlock`→啟用）對正式套件物件一樣適用。
- **`sap_activate` 對 INCLUDE 一樣報「REPORT/PROGRAM statement is missing」（延續第 5 節），要用第 5 節記載的 activation API + `programs/includes` URI + `context` 查詢參數（主程式或所屬 Function Group 的 `source/main`）手動啟用**；對一般 PROG/P 型別的 `$TMP` 驗證程式，`sap_activate` 依然可能回 `{"success":false,"messages":[]}`（第 9/17 節已知限制），一律改用 `sap_inactive_objects` 回傳空清單確認真正啟用成功，不要只看 `sap_activate` 的回應。
- **確認 `ZX` 開頭 Include 的正確生成方式**：`CMOD` 建 Enhancement Project、Assign Enhancement 之後，**雙擊 Project 底下想用的 Component（如 `EXIT_SAPLV01Z_001`）進去編輯一次，系統會自動生成該 Include 的骨架**（本例 `ZXVBZU01` 就是這樣生出來的，落在套件 `$TMP`，不需要傳輸請求；同一個 Enhancement 底下若有的 Component 早就被生成過如 `ZXVBZU02`，雙擊只是直接開啟既有內容）。生成後 Claude 就能正常用 `sap_get_source`/`sap_set_source` 讀寫，不用再嘗試第 6 節記載會被拒絕的 ADT Include 建立 API。
- **⚠️ 更正（使用者澄清）：Classic Function Exit 的 Include 原始碼寫好＋用 ADT 啟用，不代表這個 Enhancement 真的生效**——`ZXVBZU02` 這次雖然透過 ADT 寫入並啟用成功（`sap_inactive_objects` 回空），但這只代表**原始碼存在系統裡**；Enhancement 要真的運作，必須在 `CMOD` 完整跑過一次：① 建 Enhancement Project ② Assign 對應的 Enhancement（本例 `SAPLV01Z`）③ Activate Project——這一步才是真正讓 Function Group 載入新程式碼的開關，沒做的話即使原始碼已經在系統裡，實際執行的還是舊版本（或完全沒執行到這段程式碼）。本檔先前的推論（第 20 節「CMOD 專案指派是 GUI-only，但程式碼內容可能是 Claude 能自動讀寫的」）**只在「能不能寫入原始碼」這件事上成立，不代表寫完就等於生效**——CMOD 的 Project／Assign／Activate 三步驟一律是 GUI-only、且是 Enhancement 真正啟用的必要條件，不能省略也沒有 ADT API 可以做。

- **`NUMBER_GET_NEXT` 取號是非交易性（non-transactional）的，號碼一定會跳號，這是設計如此不是 bug**（2026-07-29 實測，Enhancement 課程 en02，真實 MIGO Goods Receipt 端對端驗證）：驗證程式 `ZR_EN02_BATCH_DEMO` 測試消耗了 `ZEN02BAT` 的 `1`/`2`/`3` 號，之後使用者在 MIGO 操作過程中（可能按過 `Check` 或重試）又消耗了幾號，最終真正過帳成功的批號序號是 `4`，但事後查 `NRIV` 的 `NRLEVEL` 已經是 `10`——中間 `5`~`9` 永遠消失、不會回收。原因：Number Range 的取號動作不受資料庫交易 COMMIT/ROLLBACK 約束（效能考量，避免並行過帳互相鎖等待），只要程式邏輯執行到取號那一行，號碼就真的被領走，即使該筆交易最後失敗/取消也不會歸還。**用 Number Range Object 產生的任何編號（批號、單號……）天生會有缺號，不能拿來當「總共發生過幾筆交易」的計數依據**；如果業務有「單號必須連號」的法規要求（如某些國家的統一發票），Number Range Object 這套機制從根本上不適用，要用完全不同的交易性＋鎖定機制設計。

## 22. 舊式 Classic BAdI（只有 `SXSD/XD`，沒有 `ENHS/XS`）要用 `cl_exithandler=>get_instance`，不能用 `GET BADI`；DDIC Customer Include（`CI_*`）擴充手法；套件建立後無法透過 API 事後更改（2026-07-29 實測，Enhancement 課程 en03 延伸的真實 PP 客製化：COOIS 加自訂欄位 `ZZEXTWG`）

- **不是所有 Classic BAdI 都有 `ENHS/XS` 影子**：en01 的 `MB_MIGO_BADI`、en03 的 `BADI_MM_MATNR` 都同時有 `SXSD/XD`（舊）＋`ENHS/XS`（新，NW 7.0 統一框架時自動包上的外殼），這種**可以**用新式 `GET BADI`/`CALL BADI` 語法呼叫；但 `WORKORDER_INFOSYSTEM`（PP／COOIS 用）quickSearch **只查到 `SXSD/XD`，完全沒有 `ENHS/XS`**——這種「純舊式」BAdI 用新語法 `GET BADI lo_badi.` 直接在**編譯階段**報錯「"LO_BADI" is not a valid BAdI handle here」，必須改用舊式呼叫慣例：
  ```abap
  DATA go_exit TYPE REF TO if_ex_workorder_infosystem.
  CALL METHOD cl_exithandler=>get_instance
    EXPORTING exit_name = 'WORKORDER_INFOSYSTEM'
    CHANGING  instance  = go_exit
    EXCEPTIONS no_reference = 1 OTHERS = 2.
  IF go_exit IS BOUND.
    CALL METHOD go_exit->method_name ...
  ENDIF.
  ```
  `cl_exithandler=>get_instance` 對 Multi Use BAdI **一律成功回傳一個 bound 的 instance**（它是分派器，內部管理 0～多個實作），即使 0 個生效中的實作也不會報錯，呼叫方法就是安靜地什麼都不做——跟新式 `GET BADI`/`CALL BADI` 對 Single Use 沒實作時會丟 `CX_BADI_NOT_IMPLEMENTED` 是不同的「沒實作」表現方式。**判斷該用哪種語法的方法**：quickSearch 該 BAdI 名稱，看有沒有 `ENHS/XS` 型別的結果，沒有就要用 `cl_exithandler=>get_instance`。
- **一個 Multi Use BAdI 可能同時有好幾個 Implementation，只查一個就下結論會誤判「沒有生效中的實作」**：`BADI_MM_MATNR` 一開始只查到跟 Definition 同名的 1 個 Implementation（剛好 Inactive），誤以為「這個 BAdI 沒人實作」；改用 quickSearch 該 BAdI 名稱＋`objectType=ENHO/XH` 篩選才找到全部 6 個 Implementation（4 個 Active），推翻了原本的結論。**查一個 Multi Use BAdI 的實作狀態，一定要用 quickSearch 撈全部同名前綴的 Implementation，不能只看 GET Enhancement Spot 回應裡（如果有）附帶的單一範例**。
- **DDIC 結構的「Customer Include」擴充手法**（新式 source-based 結構，如 `IOHEADER` 這種 `define structure { ... }` 語法）：很多 SAP 標準結構會預留 `include ci_<結構名>;` 這一行，但這個 `CI_*` 結構本身**尚未存在**（GET 會 404「Error while importing object from the database」）；只要用一般 DDIC Structure 建立流程（POST `/sap/bc/adt/ddic/structures`，Content-Type `application/vnd.sap.adt.structures.v2+xml`，root `blue:blueSource`）把這個 `CI_*` 結構建出來、填入自訂欄位、啟用，**不需要改動原本的標準結構本身**，因為 `include` 這一行早就存在，DDIC 會在讀取結構定義時自動解析進去。這是比 Append Structure 更輕量、SAP 官方預留的擴充機制。
- **⚠️ 套件一旦在建立物件時指定，之後無法透過 ADT API 更改**：不慎把 `CI_IOHEADER` 建到 `$TMP`（應該要建在 `ZPP`）後，嘗試用「LOCK → PUT 帶新 `packageRef` → UNLOCK」想改套件，PUT 回應雖然是 200，但讀回來套件仍然是原本的 `$TMP`，改套件沒有生效；重新 POST 建立同名物件會直接報 `ExceptionResourceAlreadyExists`。目前沒有找到能改變既有物件套件的 ADT API，物件的套件本質上是建立當下就定死的屬性——**這代表建立正式套件物件前，務必先跟使用者確認清楚套件名稱，不要抱著「先建起來、之後再改套件」的心態**，改錯了只能留著（如果是 `$TMP` 這種不影響正式流程的情況）或請使用者到 GUI 手動處理（正式套件目前沒有 ADT 刪除/搬移工具）。
- **DDIC Structure 建立時，`sap_set_source` 的第一次 PUT 若還沒清過殘留鎖，會直接回 `ExceptionResourceAlreadyExists: Can't save due to errors in source`（不是預期中的殘留鎖 403），內容也不會更新**：用 `sap_get_source`／直接 GET `source/main` 讀回來會發現還是建立時系統自動塞的預設樣板欄位（例如 `component_to_be_changed : abap.string(0);`）；照第 5 節標準流程（`sap_lock`→`sap_unlock`）清鎖後**重新呼叫一次 `sap_set_source`**（同樣的內容）就會成功——這代表 DDIC Structure 的殘留鎖有時要清鎖**之後才寫入**，跟一般 Include／Class「先寫入才發現要清鎖」的順序不同，遇到 DDIC 物件寫入報怪異錯誤時，可以先清鎖再重試一次寫入。

## 23. Implicit Enhancement Point（`ENHOXHH` Source Code Plugin）建立是 GUI-only，但內容讀寫走 ADT；動態 `ASSIGN` 跨程式全域變數需要目標程式已載入；GUI Session 快取已啟用物件的舊版本（2026-07-29 實測，Enhancement 課程 en04，標準 FM `CO_ZF_NUMBER_GET` 客製化工單自動給號真實案例）

- **`ENHOXHH`（Source Code Plugin）沒有 ADT 建立 API**：直接 POST `/sap/bc/adt/enhancements/enhoxhh`（Content-Type `application/vnd.sap.adt.enh.enhoxhh.v2+xml`）無論怎麼調整 body 結構（嘗試加 `enho:enhancement` 子元素、各種屬性組合），一律回 `System expected the element '{...}enhancement'`，且系統裡沒有任何既有 `ENHOXHH` 物件可以 GET 下來當範本反查正確 schema（quickSearch 廣泛查詢只找得到 `ENHO/XH`，找不到任何 `ENHOXHH`）——這代表 Source Code Plugin 的**空殼建立**必須在 SE37/SE38 編輯器完成：Function Module／Program 顯示畫面 → **Edit → Enhancement Operations → Show Implicit Enhancement Options**（畫面出現插入點圖示）→ 點選要插入的位置 → **Create → Enhancement Implementation** → 填名稱＋套件 → 存檔，系統會生成空的 `ENHANCEMENT 1  .` ... `ENDENHANCEMENT.` 骨架。跟第 21 節「`ZX` 開頭 Include 保留給 Exit Function Group、CMOD 裡雙擊才會生成」是同一類限制：某個位置/身分需要在 GUI 編輯器裡實際操作過才會產生系統內部的技術 ID，這個 ID 沒有對應的 REST 資源可以憑空 POST 出來。
- **空殼建好之後，內容讀寫、啟用完全可以走 ADT**，流程跟 Domain/DE/Table Type 一樣（LOCK → PUT → UNLOCK → activation，見第 5／8／14 節）：
  - LOCK 用舊式 Accept（同 DDIC 物件）：`Accept: application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result`，POST `/sap/bc/adt/enhancements/enhoxhh/<name>?_action=LOCK&accessMode=MODIFY`
  - PUT `/sap/bc/adt/enhancements/enhoxhh/<name>/source/main?lockHandle=...`，`Content-Type: text/plain; charset=utf-8`
  - GET 這個物件（`/sap/bc/adt/enhancements/enhoxhh/<name>`）回應裡有 `enho:hookImplementation` 元素，`enho:full_name` 屬性會顯示這個插入點的技術路徑（如 `\FU:CO_ZF_NUMBER_GET\SE:BEGIN\EI`，代表「Function Module CO_ZF_NUMBER_GET，Begin，Enhancement Implementation」），可以用這個確認插入點位置是否正確
  - `sap_get_source`/`sap_set_source`/`sap_lock`/`sap_unlock` 工具的 `objectType` enum 都沒有 `ENHO` 這個選項，一律要走上述 curl workaround
- **⚠️ PUT 進去的原始碼，`ENHANCEMENT` 這一行不能自己補上 Enhancement Implementation 的名稱**：GET 回來的空骨架是 `ENHANCEMENT 1  .`（數字後兩個空白直接接句點，沒有名稱），如果「補齊」寫成 `ENHANCEMENT 1  <名稱>.` 送出去，會收到 `ExceptionResourceScanDuringSaveFailure`（"Scan of resource failed"，長文說明要求 `ENHANCEMENT n.` ... `ENDENHANCEMENT.` 的格式）——名稱是物件中繼資料層級管理的，不能寫進原始碼本文，照抄 GET 回來的骨架格式（不含名稱）就對了。
- **動態 `ASSIGN ('(程式名)結構-欄位') TO <fs>` 跨程式讀寫全域變數，前提是目標程式已經在目前 ABAP session 被載入記憶體**：真實案例裡，`CO_ZF_NUMBER_GET`（Function Group `COZF`）的 Enhancement 要讀取**另一個** Function Group（`COKO1`，工單維護主力程式）用 `TABLES: afpod.` 宣告的全域欄位 `AFPOD-WEMPF`。獨立寫測試程式只呼叫 `CO_ZF_NUMBER_GET`（屬於 `COZF`），從未觸碰過 `COKO1` 群組的任何 FM 時，`ASSIGN ('(SAPLCOKO1)AFPOD-WEMPF') TO <fs>` 會**安靜地失敗**（`sy-subrc <> 0`，沒有錯誤訊息或 dump），目標欄位維持初始值，後續依賴這個值的邏輯全部悄悄失效（本題實測：三次呼叫全部 fall through 走標準取號，看起來像 Enhancement 完全沒作用，但其實是這個環節的資料錯誤）。**修法**：測試程式先呼叫該 Function Group 裡任何安全、唯讀、無副作用的 FM 當「暖身呼叫」（本題用 `CO_KO1_GET_HEADER`，只有 `EXPORTING` 參數、呼叫端可以完全不接收），讓程式群組被載入記憶體之後，`ASSIGN` 才會成功。真實交易流程（`CO01`/`COR1`）不會踩到這個問題，因為使用者操作過程中相關程式群組早就被載入了，只有「獨立、繞過正常交易流程」的測試程式才需要這個暖身步驟。
- **⚠️ Enhancement 已用 ADT 啟用成功，不代表使用者當下的 SAP GUI Session 會立刻反映最新版本**：ABAP 執行環境會把已載入過的程式（Generated Code）留在該登入 Session 的記憶體裡，直到 Session 結束。如果使用者在 Claude 修正並重新啟用 Enhancement**之前**，就已經在同一個登入 Session 裡進過相關交易、載入過目標程式，即使背後原始碼已經更新、`sap_inactive_objects` 確認無殘留未啟用版本，這個 Session 剩下的生命週期都會繼續使用**當初載入時的舊版本**。本題實測踩到：先寫了一個「不論任何條件、寫死測試值後 `EXIT`」的診斷版本驗證插入點本身有沒有作用，改回正式邏輯、重新啟用之後，使用者馬上用 `CO01` 建立真實工單，結果訂單號碼變成了診斷版本寫死的字串——不是正式版本沒生效，是那個 GUI Session 記憶體裡還在用診斷版本。**解法：請使用者完全登出再重新登入（或開一個新的 Mode/Session）**，全新 Session 第一次載入該程式群組時才會抓到最新已啟用的版本。ADT 的 `programrun`（每次呼叫都是全新、無狀態的執行環境）不會踩到這個問題，這也是為什麼「先用 headless `programrun` 驗證邏輯正確，再請使用者在 GUI 重新登入後驗證」是比較穩妥的驗收順序——直接請使用者在既有 Session 裡馬上重測，可能會看到誤導性的舊結果。
- **設計「安全閘」讓客製化邏輯只在明確登記的組合下才觸發，測試順序要「先假資料、後真資料」**：本題用一張「啟用總開關表」（Key 存在即代表啟用，見 `ZEN04_PLTAUART`）當第一道防線，第一輪測試刻意選用系統裡保證不存在的廠別/製令類型組合（`ZZ99`/`ZE04`），驗證機制本身無誤後，才切換到真實廠別/製令類型（`1011`/`PP71`，且先跟使用者確認這個製令類型是專門保留給測試用、不會影響其他真實業務流程）。這個順序很重要：本題端對端測試過程中，真實發生過「診斷版本沒有任何條件判斷、寫死測試值」被使用者拿真實 `CO01` 交易測到、系統裡因此真的多了一張訂單號碼是垃圾字串的正式工單——修改標準物件行為時，一定要先用保證不存在的假資料驗證機制本身沒問題，最後才切換到真實資料，且務必提醒使用者這一步涉及真實資料異動、有需要時要有清理/回退方式。

## 24. Enhancement Spot（`ENHS`）建立也是 GUI-only（SE18）；`GET BADI` 的 `TYPE REF TO` 要接 BAdI 名稱本身不是 Interface；`cl_exithandler` 的 `EXIT_NAME` 只有 CHAR20（2026-07-29 實測，Enhancement 課程 en05，真實排錯案例）

- **`ENHS`（Enhancement Spot／BAdI Definition）沒有 ADT 建立 API**：POST `/sap/bc/adt/enhancements/enhsxs`（Content-Type `application/vnd.sap.adt.enh.enhs.v1+xml`，root `enhs:objectData`）不管怎麼依錯誤訊息逐步補齊（`enhs:contentCommon` → `enhs:documentationId` → 完整 URI 參照），最後都停在後端 kernel 層級的 `ADT-RFC bridge error: 3 (rc=3): key=ASSERTION_FAILED`（不是 schema 驗證錯誤，是更根本的失敗，訊息完全沒有內容）。跟第 23 節的 `ENHOXHH` 是同一類限制：**建立空殼一律走 SE18 GUI**，內容讀寫（`GET`/`PUT`/`LOCK`/`UNLOCK`/activation）建好之後可以正常走 ADT。
  - GET 既有 BAdI Definition 確認欄位名稱時，Fallback Class 對應的 XML 元素是 **`enhs:defaultClass`**（不是直覺會猜的 `enhs:fallbackClass`），`enhs:sampleClass` 則是「Implementation Example Class」（SE18 建立時會問「Create fallback class as implementation example class as well?」，選 Yes 就會同時填這個元素，純文件性質、不影響執行邏輯）。
  - **Multi Use BAdI 的 Interface 方法不能有 `RETURNING`/`EXPORTING` 參數**：SE18 填 Interface 時若違反會報 `SEEF_BADI090`「... has methods with returning or exporting parameters」，因為多個 Implementation 依序執行時「哪個回傳值算數」沒有明確定義；資料要靠 `CHANGING` 參數傳遞。
- **⚠️ `GET BADI` 編譯期報 `"<變數>" is not a valid BAdI handle here` 的常見真因：`TYPE REF TO` 宣告成 BAdI Interface 名稱，而不是 BAdI（Enhancement Spot／BAdI Definition）名稱本身**——這是最容易踩、最不直覺的坑，連系統裡運作多年的真實標準 BAdI（`MB_MIGO_BADI`）用 `DATA go_badi TYPE REF TO if_ex_mb_migo_badi. GET BADI go_badi.` 一樣會報這個錯。正確寫法要照 SAP 官方 ABAP Cheat Sheet（`35_BAdIs.md`）逐字比對出來：`DATA go_badi TYPE REF TO <BAdI 名稱本身>. GET BADI go_badi.`（例如 `TYPE REF TO zes_en05_greeting`，不是 `TYPE REF TO zif_en05_flight_greeting`）——Kernel-based BAdI 框架會在 BAdI Definition 啟用時自動生成一個**跟 BAdI 同名、繼承 `CL_BADI_BASE`** 的隱藏類別，`GET BADI` 產生的物件就是這個隱藏類別的實例，型別系統要對到這個才認得。這跟 Classic 語法 `cl_exithandler=>get_instance`（`CHANGING instance TYPE ANY`，慣例上宣告成 **Interface** 型別）的宣告方式剛好相反，兩個世代的呼叫慣例容易搞混。
  - **排錯方法論**：懷疑新物件設定有問題時，先找一個「已知運作正常的標準物件」用同樣語法對照測試（例如任何有 `ENHS/XS` 身分的標準 BAdI）；如果對照組也失敗，代表問題在呼叫語法本身，不是新物件的設定，能快速收斂懷疑範圍、避免在物件設定上反覆瞎試。
- **`cl_exithandler=>get_instance` 的 `EXIT_NAME` 參數型別是 `EXIT_DEF`（Data Element，Domain `EXITDEF`），長度只有 **CHAR20**——這是 Classic Exit（`SMOD`）時代的命名長度限制，即使套用在新式 BAdI／Enhancement Spot 名稱上一樣生效**，超過會在編譯期報「literal is not type-compatible with the formal parameter EXIT_NAME」（一個很容易誤判成別的原因的錯誤訊息，實際就是純粹的長度問題）。取 Enhancement Spot／BAdI 名稱時，若預期會有人用 Classic 語法呼叫，命名要控制在 20 碼以內。
- **BAdI Implementation 的啟用／停用（SE19「Implementation is active」勾選框）即時生效，不會像 en04 學到的「GUI Session 快取程式碼」那樣延遲**：`GET BADI`/`CALL BADI` 每次呼叫都會即時查詢當下哪些 Implementation 是 Active 的，不涉及程式碼重新產生（Generated Code），所以切換 Active／Inactive 後立刻用 `programrun` 重新執行就能看到反映最新狀態的結果——這跟 en04 的 Implicit Enhancement **改程式碼本身**（需要重新產生 Load）是本質不同的兩種變更，不要混淆兩者的「生效時機」。
  - ADT GET 這個物件時，`enho:badiImplementation` 的 **`enho:isActive` 屬性不代表「Implementation is active」這個開關**（實測切換 SE19 的勾選框前後，`isActive` 值不變，一直是 `"true"`）；要看的是 **`enho:runtimeBehaviorShorttext`** 屬性，這個文字（`"The implementation will be called"` / `"The implementation will not be called"`）才會即時反映 SE19 畫面上「Runtime Behavior」欄位顯示的真實狀態。
- **標準 PP 領域真正有 `ENHS/XS` 身分（非純 Classic）的 Enhancement Spot 範例**：quickSearch `WORKORDER*` 可以找到一批，例如 `WORKORDER_UPDATE`（套件 `COBADI`，Multi Use，Interface `IF_EX_WORKORDER_UPDATE`，說明「Business Add-In PM/PP/PS/PI Orders Operation: UPDATE」）——這個 Interface 底下的 `AT_SAVE` 方法（`IMPORTING IS_HEADER_DIALOG`／`EXCEPTIONS ERROR_WITH_MESSAGE`，簽章簡單、符合 Multi Use 限制）是工單存檔時的真實驗證掛勾點，適合當作「用標準既有 Enhancement Spot 建真實 Implementation」的教學案例；但這是系統裡**每天在跑的真實 BAdI**，一旦掛上自訂 Implementation 會對所有真實 PM/PP/PS/PI 工單存檔生效，務必比照 en04 的安全閘設計（只在明確不存在的測試資料組合才觸發邏輯）。

## 25. `ENHO/XH`（BAdI Implementation）建立也是 GUI-only；Multi Use 無 Filter 時所有 Active Implementation 依序執行；**BAdI Implementation 絕對不能下 `COMMIT WORK`**（2026-07-29 實測，Enhancement 課程 en06，真實 `WORKORDER_UPDATE`/`AT_SAVE` 案例）

- **`ENHO/XH`（BAdI Implementation）沒有 ADT 建立 API**：POST `/sap/bc/adt/enhancements/enhoxh` 一路依錯誤訊息補齊 `enho:contentCommon`、`enho:runtimeBehaviorShorttext` 等必要元素後，最終回 `ExceptionResourceCreationFailure: Resource controller does not support method POST`——這個端點本身就不支援 POST（不是資料格式問題），確認跟第 23／24 節的 `ENHOXHH`／`ENHS` 是同一類限制：**空殼建立一律走 SE19**，內容讀寫（含指定 Interface 每個方法的邏輯）建好之後可以正常走 ADT stateful session workaround。
- **Multi Use BAdI 沒有 Filter 時，`CALL BADI` 會依序呼叫全部 Active Implementation，不是只挑一個**：實測建了兩個 Implementation 掛在同一個 Multi Use BAdI Definition 底下，都對同一個 `CHANGING` 參數做處理（第二個在第一個的結果後面追加文字），呼叫一次 `CALL BADI` 後兩個都真的執行了（依序疊加）。這是 en05 學到的「Multi Use 不能用 `RETURNING`/`EXPORTING`」規則存在的原因——資料流向設計成「多個 Implementation 可以依序疊加處理同一份資料」，不是「多選一」。
- **⚠️⚠️ BAdI Implementation／被呼叫的子程式，絕對不能自己下 `COMMIT WORK`**：實測在 Implementation 方法裡寫完自訂邏輯後加了一行 `COMMIT WORK.`（想著「保險起見存進去」），結果使用者一觸發真實呼叫（本例是 `CO01` 訂單存檔）就整個系統 Dump：
  ```
  Category           ABAP programming error
  Runtime Errors      MESSAGE_TYPE_X
  ABAP Program        SAPLCOZV
  * Unexpected COMMIT WORK!!!
  * there should be no COMMIT WORK in order processing before
  * fm CO_ZV_ORDER_POST was executed, since this might lead to
  * inconsistencies!!!
  ```
  **原因**：Implementation 是在呼叫者（本例是訂單存檔框架）尚未完成的 LUW（邏輯工作單元）裡面執行的，`COMMIT WORK` 只能由「擁有這個 LUW 的最上層呼叫者」下達；子程式/Implementation/Function Module 自己下 `COMMIT WORK`，等於把目前已做的變更提前釘死，框架後續若因某個檢查失敗需要 ROLLBACK，已提前 COMMIT 的部分**沒辦法撤銷**，會讓資料庫停在不一致狀態。許多 SAP 標準框架（本例 `SAPLCOZV`）會主動偵測這個風險並讓程式直接 Dump，寧可讓開發者立刻發現，也不讓不一致資料悄悄進資料庫——**這條規則不是本例特有，適用所有「被別人呼叫」的程式碼**：Function Module、Method、BAdI Implementation、User-Exit 都不該自己下 `COMMIT WORK`，除非你確定自己就是這次呼叫鏈最上層、真正擁有這個 LUW 的呼叫者。拿掉 `COMMIT WORK` 後，Implementation 裡的 `INSERT`／`UPDATE` 會跟著呼叫者本身的交易一起被最上層框架 COMMIT，不需要（也不能）自己額外處理。
- **驗證有風險的真實 BAdI Implementation，建議先做「不透過真實派送的單元測試」，再做真實交易測試**：本題先寫一支測試程式直接 `CREATE OBJECT`＋呼叫 Interface 方法（完全繞過 `GET BADI`/`CALL BADI` 派送機制），確認安全閘邏輯正確後，才請使用者用真實交易（`CO01`）測試——這個順序讓「先前那次 `COMMIT WORK` 誤植」造成的傷害範圍限縮在「單元測試執行結果不符預期」，而不是真的讓使用者的真實交易當機（雖然 ABAP Dump 會自動 ROLLBACK 不留壞資料，但仍是不必要的失敗體驗）。**修正 `COMMIT WORK` 之後，本題仍然是先重跑單元測試確認邏輯無誤，才請使用者重新做真實交易測試**——多一層驗證，少一次風險。
- **查證 BAdI 方法參數的底層型別，可能發現能直接沿用之前課程已驗證過的安全閘設計**：`WORKORDER_UPDATE`／`AT_SAVE` 的 `IS_HEADER_DIALOG` 型別 `COBAI_S_HEADER_DIALOG`（`COBAI` Type Group 裡定義，讀 Type Group 原始碼 `/sap/bc/adt/ddic/typegroups/<name>/source/main` 可以看到 `LIKE CAUFVD`）——跟第 21～24 節（en04）用過的 `CAUFVD` 完全同一個結構，代表可以直接沿用已驗證過的安全閘測試值（`WERKS='1011'`／`AUART='PP71'`），不用重新查證一組新的測試資料。
- **BAdI 掛勾點的呼叫時機會影響能拿到的資料完整度，不能只看文件猜**：本題真實驗證發現，`AT_SAVE` 觸發當下 `IS_HEADER_DIALOG-AUFNR` 顯示 `%00000000001` 這種內部暫時性編號格式（不是最終的 12 碼工單號），代表這個掛勾點的資料還沒完全定型。設計客製化邏輯前，若需要用到「最終確定的資料」（如正式工單號），最好先用類似本題的方式實際觸發一次、印出/記錄實際拿到的值，確認資料完整度是否符合需求，不要只憑方法名稱或參數型別猜測。

## 26. Explicit Enhancement Point/Section：一旦程式有 Explicit Enhancement，ADT `sap_lock` 永久失效；建立 Spot 必須從 SE38 Create Option 觸發，SE18 做不到（2026-07-29 實測，2026-07-30 更正，Enhancement 課程 en07）

- **`ENHANCEMENT-POINT`/`ENHANCEMENT-SECTION ... SPOTS <spot>` 語句本身可以直接用 ADT 寫進程式原始碼**（跟一般 ABAP 陳述式一樣），但 `SPOTS` 參照的 Enhancement Spot 若還不存在，`checkruns` 會報 `Enhancement spot <name> is unknown`——這個 Spot 一樣沒有 ADT 建立 API（POST 一律失敗），必須走 SE38 GUI。
- **⚠️ 根本原因確認（2026-07-30 使用者親自實測更正）：SE18 只能建立 BAdI Definition 類型的 Enhancement Spot，Source Code Plug-In 類型必須從 SE38 GUI 建立**——這不只是「SE18 畫面剛好沒開放這個選項」的表面現象，而是**兩種 Spot 類型的本質差異**：BAdI Definition 型的 Spot 是獨立物件，不依附任何特定程式的特定位置，SE18 這種獨立管理介面可以完整建立它；但 Source Code Plug-In 型的 Spot（`ENHANCEMENT-POINT`/`ENHANCEMENT-SECTION` 用的那種）**本質上需要記錄一個「錨點」——它綁定在某支程式原始碼的某個確切位置**，這個錨點資訊只有在**該程式的編輯器（SE38）裡、對著實際的原始碼位置操作**才能被正確捕捉並寫入；SE18 是脫離任何程式上下文的獨立畫面，天生就沒有「這個 Spot 該錨定在哪支程式的哪一行」這個資訊來源，所以從設計上就不可能建出這種類型。之前（2026-07-29）一路踩到的 `ED291 Creating nested enhancements is not supported`／`Enhancement spot <name> defines enhancement spot in another object` 這類誤導性錯誤，真正根因是**誤用了 SE18 建立的 BAdI Definition 型 Spot（沒有錨點資訊）**去套用到 Explicit Point/Section（需要錨點）；當時誤把修正歸因於「要先按 Enhance 切換按鈕」，這個歸因**不準確**，見下一條的更正說明。
- **✅ 正確建立流程（2026-07-30 端對端驗證成功，`ZR_EN07_SECTION_DEMO`＋`ZES_EN07_SECTION_V1`）——Point 跟 Section 都適用**：
  1. SE38 開啟目標程式 → **Change**（一般編輯模式，**不用**切到 Enhance 模式）
  2. 游標放在想插入 Point 的那一行，或選取想包成 Section 的那段程式碼區塊
  3. 右鍵 → **Enhancement Operations → Create Option**
  4. 彈出的 Create Enhancement Option 對話框：Type and Name 選 **Enhancement Point** 或 **Enhancement Section** 並填 Option 名稱；Binding in Source Code 選 "as conditional call"（可執行程式碼用這個）；**Enhancement Spot 欄位直接輸入一個全新、從未用過的名稱**（不要填 SE18 建立的既有 Spot——型別不合會導致上面那些誤導性錯誤），按 Enter 觸發「是否建立」提示，確認建立
  5. 存檔／**Activate**：`Inactive Objects` 清單會同時出現這個新建的 **`ENHS`**（Enhancement Spot）跟 **`PROG`/`REPS`**（程式本身），一次批次啟用即可，代表 Spot 是跟著 Create Option 這個動作自動生成、自動 Binding 到目前這支程式，不需要（也不能）另外用 SE18 事先準備
  6. 驗證 Binding 是否正確：SE18 Display 這個新建的 Spot，**Attributes 頁籤的 Enhancement Method 會正確顯示「Source Code Plug-In」**（不是 BAdI Definition，證實 SE18 沒辦法直接建出這個結果，只能靠 SE38 這條路徑產生）；**Technical Details 頁籤的 Referenced Objects 會列出該 Program（Object Type=Program／Report Source，Main Object=該程式名稱）**，證實已正確綁定
  7. **視覺確認**：Binding 成功後，SE38 編輯器左側裝訂線（行號左邊那條窄欄）會在 `ENHANCEMENT-POINT`/`ENHANCEMENT-SECTION` 那個區塊對應的位置多出一個**螺旋狀小圖示**，代表這一段已經跟一個真實存在且綁定成功的 Enhancement Spot 連結，可以用「有沒有這個圖示」快速判斷 Binding 是否成功，不用每次都跑去 SE18 查 Technical Details——反之，還沒 Binding 或 Binding 失敗（如誤用型別不合的 Spot）就不會出現這個圖示
- **⚠️ 「Include Bound」不是「追加 vs 整段取代」的控制項（2026-07-30 更正）**：Create Enhancement Option 對話框裡確實有「Include Bound」核取方塊（Enhanceable Object 區塊），但**當 Enhanceable Object Type 是 Program 時，這個欄位整個灰階、無法勾選**（實測 `ZR_EN07_SECTION_DEMO`），Create Implementation 對話框本身也沒有任何額外開關（只問名稱／套件）。`ENHANCEMENT-SECTION` 的 Implementation 到底是「保留原邏輯疊加」還是「整段取代」，這套系統裡實際由什麼機制決定**尚未查證**，不要照抄官方文件對 `INCLUDE BOUND` 的籠統描述當作這個灰階欄位的作用——遇到這類「文件提到某個關鍵字/開關，但畫面上對應欄位是灰階或根本找不到」的情況，同樣要靠實測（建 Implementation、跑出來看結果）confirm，不要用文件字面意思腦補 UI 行為。
- **⚠️ 「Enhance」切換按鈕的正確角色（2026-07-30 更正並完整驗證）：Create Option（建立宣告＋Spot）不需要切到 Enhance 模式；Create Implementation（編輯 Enhancement 實際內容）才需要**——2026-07-29 記錄的「任何操作前必須先按 Enhance 按鈕」這個結論不準確，真正的變因是有沒有誤用 SE18 建的錯誤型別 Spot。正確順序：① Create Option 階段全程用一般 Change 模式（見上一條），完成後編輯器裝訂線出現螺旋圖示；② **看到螺旋圖示、確認 Binding 成功之後，才按工具列的「Enhance」切換按鈕**，畫面標題會變成「Change Enhancements for ...」；③ 在切換後的模式下，游標點在該 `SPOTS` 那一行 → 右鍵 → Enhancement Operations → **這時候 `Create Implementation` 才會是可用（非灰階）選項**，因為系統已經認得這個位置且已經 Binding 到程式，可以掛 Implementation 上去；未切換 Enhance 模式或 Binding 還沒成功時，`Create Implementation` 不會正確作用。這個流程已用截圖完整驗證（`ZR_EN07_SECTION_DEMO`）。
- **⚠️⚠️ 一旦程式碼裡有了正式建立的 Explicit Enhancement（Create Option 完成後），這支程式的 `sap_lock`（含後續所有 ADT 寫入）永久失效**：實測對已經有 `ENHANCEMENT-POINT` 宣告並成功建立 Option 的程式呼叫 `sap_lock`，一律回 `HTTP 405 ExceptionResourceIsEnhanced: The editor does not support enhanced objects (use SAP GUI instead)`——這是本課程目前遇過最徹底的 ADT 限制，比 en04/en05/en06 的「空殼建立需要 GUI、內容讀寫可以走 ADT」更嚴格：**這裡是連內容都無法用 ADT 讀寫，之後所有修改（不管是不是跟 Enhancement 相關的部分）都只能回 SAP GUI 進行**。GET（唯讀）不受影響，仍可正常讀取合併後的原始碼（但讀不到 Enhancement Implementation 本身塞入的程式碼內容）。
- **Enhancement Implementation 的內容（`ENHANCEMENT n <名稱>. ... ENDENHANCEMENT.` 區塊）完全無法透過 ADT 讀寫**：`GET /sap/bc/adt/enhancements/enhsxs/<spot>` 回 `Enhancement technology HOOK_DEF is not supported yet`；嘗試組出對應 `ENHOXHH` 路徑讀取 Implementation 原始碼回 `uriMappingError: URI-Mapping cannot be performed due to invalid workbench object`。只能請使用者直接在 SE38 的 Enhancement 編輯區塊手動輸入程式碼，Claude 只能提供程式碼文字讓使用者貼上，無法代為寫入或事後讀取驗證內容（只能透過 `programrun` 執行結果間接驗證邏輯是否正確）。
- **對照 en04（Implicit Enhancement／Source Code Plugin）**：兩者建立空殼都是 GUI-only，但 en04 的 `ENHOXHH` 建好之後內容可以完全用 ADT 讀寫、程式本身也不受影響仍可用 `sap_lock`；這題的 Explicit Enhancement 不只內容要 GUI，連**外層程式本身**都被 ADT 拒絕編輯。這代表「要不要在自己維護的 Z 程式上加 Explicit Enhancement Point」是一個需要跟團隊溝通清楚的技術取捨：加了之後，這支程式從此對 ADT/Claude 自動化流程關閉。

## 匯出 SAP 原始碼到 src/ 的慣例

- 檔名採 abapGit 格式：`<物件名小寫>.<類型>.abap`（如 `zdqm0001.prog.abap`；INCLUDE 也是 `.prog.abap`）。
- 主程式要連同其 INCLUDE 一起匯出；多支程式共用的 INCLUDE 只存一份。
- `src/` 是**單向快照**：SAP 端修改後需重新匯出；本地修改要用 `sap_set_source` 寫回系統才算數。
