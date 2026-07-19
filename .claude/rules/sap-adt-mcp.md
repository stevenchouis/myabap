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

## 匯出 SAP 原始碼到 src/ 的慣例

- 檔名採 abapGit 格式：`<物件名小寫>.<類型>.abap`（如 `zdqm0001.prog.abap`；INCLUDE 也是 `.prog.abap`）。
- 主程式要連同其 INCLUDE 一起匯出；多支程式共用的 INCLUDE 只存一份。
- `src/` 是**單向快照**：SAP 端修改後需重新匯出；本地修改要用 `sap_set_source` 寫回系統才算數。
