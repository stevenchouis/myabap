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

## 15. `adt-rfc-bridge` 不能拿來測一般 SICF HTTP Service（2026-07-12 實測，REST 課程 rs01/rs02；2026-08-02 「外網打不到」結論已推翻，見下方更正）

- ⚠️ **2026-08-02 更正：「外網連不到 ICM HTTP Port」這個結論是錯的，原始測試當時很可能用錯了主機名稱／Port**。RAP 課程查證階段，使用者在確認自己身處外網的情況下，直接瀏覽器打 `https://erpdemo01.itts.com.tw:44300/sap/bc/zrest_training/rs01/hello`（這個系統對外的正式 HTTPS 位址＋Port 44300），**正常回傳 `Hello REST! 現在伺服器時間是 ...`**，代表這個 REST 課程的 SICF Service 從一開始就是外網可達的，不需要等回到內網／VPN。原本 2026-07-12 測試「連不到」的真正原因不明（推測是當時 curl／瀏覽器打的是內網固定 IP `192.168.68.56` 或其他錯誤的 Port，不是這個系統真正對外開放的 `erpdemo01.itts.com.tw:44300`），不是 ICM HTTP Port 本身外網不可達。
- **底下第一、二點（`adt-rfc-bridge` 不能當 SICF 跳板）依然成立，只是原因跟「外網限制」無關**：直接 curl 打 `http://127.0.0.1:8410/sap/bc/<自訂 SICF 路徑>`（例如 `/sap/bc/zrest_training/rs01/hello`）會回 `404 No application class found for URI: ...`——這是 `adt-rfc-bridge` 本身的限制（只認得自己內部映射的 ADT 專用路徑 `/sap/bc/adt/*`，不是通用的 HTTP-to-RFC 轉發器），跟使用者在哪個網路無關，Claude 這邊永遠沒辦法透過 bridge 直接呼叫任意 SICF Service（包含 OData 服務，見第 40.8/40.10 節）。
- **正確結論**：只要使用者知道正確的對外主機名稱＋Port（這個系統是 `erpdemo01.itts.com.tw:44300`，HTTPS），SICF Service／OData Service **在外網也能直接用瀏覽器/Postman 測試**，不需要內網或 VPN；`adt-rfc-bridge` 的限制純粹是「Claude 端沒有一個通用管道能主動呼叫任意 HTTP 端點」，跟使用者自己用瀏覽器/Postman 測試完全是兩回事，不要混為一談。之前 REST 課程 README（`src/ABAP_Training_REST/README.md`）與教材裡任何「只能內網測試」的措辭都需要一併更正。
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
- **✅ `ENHANCEMENT-SECTION`（Program 型別）實測確認：只有整段取代，沒有追加（2026-07-30 端對端驗證）**：Create Enhancement Option 對話框裡確實有「Include Bound」核取方塊（Enhanceable Object 區塊），但**當 Enhanceable Object Type 是 Program 時，這個欄位整個灰階、無法勾選**（實測 `ZR_EN07_SECTION_DEMO`），Create Implementation 對話框本身也沒有任何額外開關（只問名稱／套件）——這套系統沒有開放「追加」這個入口。建立 Implementation（`ZEI_EN07_SECTION_APPEND`）後有兩層證據：① Implementation 程式碼引用原邏輯區塊內宣告的區域變數會報 `Field "..." is unknown`，代表兩者編譯期作用域是分開的；② **實際執行後，原邏輯的 `WRITE` 輸出完全沒出現**，代表原邏輯在執行期整段沒有被觸發——②才是能排除「追加」、坐實「整段取代」的關鍵證據，①只能證明作用域隔離，不能單獨排除追加的可能性（作用域隔離也可能發生在追加模式下）。**方法論提醒：編譯期錯誤只能證明靜態結構，要確認執行期行為必須實際跑一次看輸出**，不要憑語法檢查結果就下執行期行為的結論。官方文件對 `INCLUDE BOUND`／「追加」能力的描述，在這套系統的 Program 型別情境下不適用，不要照抄文件字面意思腦補 UI 行為或執行期行為，兩者都要靠實測 confirm。
- **⚠️ 「Enhance」切換按鈕的正確角色（2026-07-30 更正並完整驗證）：Create Option（建立宣告＋Spot）不需要切到 Enhance 模式；Create Implementation（編輯 Enhancement 實際內容）才需要**——2026-07-29 記錄的「任何操作前必須先按 Enhance 按鈕」這個結論不準確，真正的變因是有沒有誤用 SE18 建的錯誤型別 Spot。正確順序：① Create Option 階段全程用一般 Change 模式（見上一條），完成後編輯器裝訂線出現螺旋圖示；② **看到螺旋圖示、確認 Binding 成功之後，才按工具列的「Enhance」切換按鈕**，畫面標題會變成「Change Enhancements for ...」；③ 在切換後的模式下，游標點在該 `SPOTS` 那一行 → 右鍵 → Enhancement Operations → **這時候 `Create Implementation` 才會是可用（非灰階）選項**，因為系統已經認得這個位置且已經 Binding 到程式，可以掛 Implementation 上去；未切換 Enhance 模式或 Binding 還沒成功時，`Create Implementation` 不會正確作用。這個流程已用截圖完整驗證（`ZR_EN07_SECTION_DEMO`）。
- **⚠️⚠️ 一旦程式碼裡有了正式建立的 Explicit Enhancement（Create Option 完成後），這支程式的 `sap_lock`（含後續所有 ADT 寫入）永久失效**：實測對已經有 `ENHANCEMENT-POINT` 宣告並成功建立 Option 的程式呼叫 `sap_lock`，一律回 `HTTP 405 ExceptionResourceIsEnhanced: The editor does not support enhanced objects (use SAP GUI instead)`——這是本課程目前遇過最徹底的 ADT 限制，比 en04/en05/en06 的「空殼建立需要 GUI、內容讀寫可以走 ADT」更嚴格：**這裡是連內容都無法用 ADT 讀寫，之後所有修改（不管是不是跟 Enhancement 相關的部分）都只能回 SAP GUI 進行**。GET（唯讀）不受影響，仍可正常讀取合併後的原始碼（但讀不到 Enhancement Implementation 本身塞入的程式碼內容）。
- **Enhancement Implementation 的內容（`ENHANCEMENT n <名稱>. ... ENDENHANCEMENT.` 區塊）完全無法透過 ADT 讀寫**：`GET /sap/bc/adt/enhancements/enhsxs/<spot>` 回 `Enhancement technology HOOK_DEF is not supported yet`；嘗試組出對應 `ENHOXHH` 路徑讀取 Implementation 原始碼回 `uriMappingError: URI-Mapping cannot be performed due to invalid workbench object`。只能請使用者直接在 SE38 的 Enhancement 編輯區塊手動輸入程式碼，Claude 只能提供程式碼文字讓使用者貼上，無法代為寫入或事後讀取驗證內容（只能透過 `programrun` 執行結果間接驗證邏輯是否正確）。
- **對照 en04（Implicit Enhancement／Source Code Plugin）**：兩者建立空殼都是 GUI-only，但 en04 的 `ENHOXHH` 建好之後內容可以完全用 ADT 讀寫、程式本身也不受影響仍可用 `sap_lock`；這題的 Explicit Enhancement 不只內容要 GUI，連**外層程式本身**都被 ADT 拒絕編輯。這代表「要不要在自己維護的 Z 程式上加 Explicit Enhancement Point」是一個需要跟團隊溝通清楚的技術取捨：加了之後，這支程式從此對 ADT/Claude 自動化流程關閉。

## 27. Filter-dependent BAdI：Filter 是 SE18 右鍵「Create Filter」獨立建立，Filter Type 只能選五種基本型別分類，SE19 建立順序是先填 Spot 名稱（2026-07-30 實測，Enhancement 課程 en06 補課）

- **BAdI Definition 畫面的「Limited filter use」核取方塊不是啟用 Filter 的開關**，它在 Usability 區塊，跟「Multiple Use」並列，但實測勾選後**不會**跳出任何 Filter Type 輸入欄位——這個核取方塊的真正用途是「限制 Filter 值只能是預先列出的固定清單」，前提是已經有 Filter 存在，不是用來建立 Filter 本身。
- **真正建立 Filter 的入口：在 SE18 左側樹狀節點的 BAdI Definition 上右鍵 → Create Filter**，彈出「Create Filter for BAdI」對話框，欄位：
  - **BAdI Filter**：自訂名稱（如 `CARRID`）
  - **Filter Type**：⚠️ **這是單一字元欄位**，F4 只會列出 5 個內建分類：`I`（Integer）／`C`（Character-like）／`S`（String）／`N`（Numeric）／`P`（Packed）——**不是**填一個完整的 Data Element 名稱（一開始直覺填 `S_CARR_ID` 這種 Data Element 名稱是錯的，欄位長度只有 1 碼放不下，也不會被接受）；要對照實際需要過濾的資料型別選最接近的分類（3 碼字元代碼如航空公司代碼、公司代碼、廠別代碼都選 `C`）
  - **Description**、**Constant filter value in call**（勾選代表這個 Filter 值是寫死常數，不勾才能在執行期動態傳不同值）
  - **Filter Value Check for BAdI Implementations**：`No Check`／`Automatically by dictionary`（要對照 Data Element 的檢查表驗證合法性）／`By separate program`
  - 建立後 Filter 會成為 BAdI Definition 樹狀節點下的獨立子節點（跟 Interface、Implementations 平行），GET 該 Enhancement Spot 的 ADT XML 可以看到 `<enhs:filters><enhs:filter enhs:filterName="CARRID" enhs:filterType="C" enhs:onlyConstantFilterValues="false"/></enhs:filters>`，證實 Filter 是掛在 `enhs:badiDefinition` 底下的獨立結構，不是 Usability 的屬性。
- **SE19 建立 Filter-dependent Implementation 的操作順序，容易憑直覺搞反**：正確順序是**先在 SE19 初始畫面的「Create Implementation」區塊填 Enhancement Spot 名稱**（不是先想 Implementation 要叫什麼），按 Create 後才依序：① 彈出「Create Enhancement Implementation」對話框，填**容器層級**的 Enhancement Implementation 名稱＋Short Text；② 再彈出「Create BAdI Implementations for Existing BAdI Definitions」表格，這時候才填實際的 **BAdI Implementation 名稱**、**Implementation Class 名稱**，並從下拉選單選 **BAdI Definition**（因為理論上一個 Spot 可以掛多個 BAdI Definition）。這代表**外層有兩層命名**：Enhancement Implementation（容器，ENHO 物件本身的名稱）與 BAdI Implementation（容器裡的實際實作項目名稱），兩者可以不同名，教學上容易只注意到後者、忽略前者也要命名。
- **建好 Implementation 後，指定 Filter 值走「Enh. Implementation Elements」樹底下的「Filter Values」節點**：Create Combination → 在表格填 `Filter`（選剛才 SE18 建的 Filter 名稱，如 `CARRID`）／`Comparator`（`=`）／`Value 1`（實際比對值，如 `LH`）。多個 Implementation 各自建各自的 Filter Combination，值不同即可分流。
- **`GET BADI ref FILTERS <filter名> = <值>.` 語法確認可用**，`<filter名>` 對應 SE18 建的 Filter 名稱（不分大小寫），可以跟方法本身的參數同名（如都叫 `carrid`）但**是兩件獨立的事**——Filter 值只影響「該呼叫哪個 Implementation」，不會自動變成方法呼叫時的參數值，方法的 `EXPORTING`/`CHANGING` 參數還是要自己在 `CALL BADI` 那行明確傳遞。
- **實測驗證（`ZES_EN06_FILTER_DEMO`＋`ZIM_EN06_FILTER_LH`／`ZIM_EN06_FILTER_AA`）**：`CARRID=LH`／`CARRID=AA` 分別正確觸發對應 Implementation；`CARRID=UA`（沒有任何 Implementation 掛這個 Filter 值）呼叫 `CALL BADI` 後，呼叫前設定的哨兵值（`cv_text = 'UNCHANGED'`）維持不變，證實「沒有符合 Filter 條件的 Implementation」時 `CALL BADI` 安靜地不執行任何邏輯，不報錯——是 en03 學到的「Multi Use 沒有生效中的 Implementation 也不會報錯」規則在 Filter 情境下的具體體現。
- **驗證技巧：用「哨兵值」（sentinel value）排除歧義**——呼叫前先把 `CHANGING` 參數設成一個「正常邏輯絕對不會產生」的值（如字面字串 `'UNCHANGED'`），呼叫後如果這個值還在，才能明確證明「沒有任何 Implementation 的程式碼被執行到」，而不是「有執行、但恰巧算出同樣結果」——這個技巧在測試「0 個生效中 Implementation」這類「什麼都不做」的情境特別重要，光看輸出是不是空值/初始值容易有歧義。

## 28. 權限物件（Authorization Object，SU21）完全沒有 ADT 路徑，比 Search Help／T-code 更徹底（2026-07-30 實測，Enhancement 課程 en08 出題前查證）

- 抓 `/sap/bc/adt/discovery` 全文（166KB）搜尋所有 `<atom:title>`，找不到任何「Authorization Object」「Authorization」相關的 collection（唯一命中的是不相關的 "Security Reentranceticket"）。
- 用 ADT quickSearch 查已知確實存在的標準權限物件 `K_ORDER`（已用 `datapreview/freestyle` 查 `TOBJ` 表證實存在，`OCLSS='CO'`，欄位 `FIEL1~FIEL5 = RESPAREA/AUFART/AUTHPHASE/CO_ACTION/KSTAR`），quickSearch **回空結果**（`<adtcore:objectReferences/>`）。
- 嘗試用已知的物件型別代碼猜測 vit stub 路徑（`/sap/bc/adt/vit/wb/object_type/susoo/object_name/K_ORDER`）也只回空的 `<adtcore:mainObject/>`，代表**連猜測的物件型別代碼都是錯的／根本沒有對應路徑**。
- **結論**：權限物件（`SU21` 維護）比本課程之前記載的 Search Help（第 10 節）、T-code（第 12 節）**更徹底 GUI-only**——那兩者至少 `repository/informationsystem/objecttypes` 目錄查得到物件型別、或 quickSearch 能命中已知物件；權限物件連這些都沒有，`sap-adt` MCP／ADT 協定完全不涵蓋這塊，自訂權限物件只能在 `SU21` GUI 手動建立，Claude 完全無法查詢或建立，只能請使用者建好後告知欄位/物件名稱，靠使用者回報或 `AUTHORITY-CHECK` 執行結果間接驗證。
- **查證方法論延續本檔一貫做法**：不要因為「查不到就假設不存在」，要先用 `datapreview/freestyle` 查對應的字典表（`TOBJ` 查權限物件本身、`TOBJT` 查文字說明）確認物件真的存在，再拿確定存在的物件去測 ADT 路徑，這樣「ADT 查不到」才是真正的 ADT 限制，而不是查詢方式錯誤或物件真的不存在導致的偽陰性。

## 29. Message Class 訊息內容寫入：正確 schema 找到了，但 PUT 回 200 OK 卻沒有真的存進去（2026-07-30 實測，Enhancement 課程 en08 出題）

- **正確的訊息巢狀 schema（跟第 8 節原本記載的猜測不同，已更正）**：`mc:message` 元素要**直接當 `mc:messageClass` 的子元素**，不能包一層 `mc:messages` 容器；屬性是 **`mc:msgno`**／**`mc:msgtext`**（不是 `mc:number`／`mc:shortText`，也不是獨立的 `msg:` namespace）：
  ```xml
  <mc:messageClass xmlns:mc="http://www.sap.com/adt/MessageClass" xmlns:adtcore="http://www.sap.com/adt/core"
    adtcore:name="ZEN08" adtcore:type="MSAG/N" adtcore:description="...">
    <adtcore:packageRef adtcore:name="$TMP"/>
    <mc:message mc:msgno="001" mc:msgtext="Plant &amp;1 has no authorization for cost analysis"/>
  </mc:messageClass>
  ```
  這個 schema 是靠 GET 個別訊息子資源 `/sap/bc/adt/messageclass/<class>/messages/<no>`（對不存在的訊息也會回一個空白樣板）反查出正確屬性名稱（`msg:msgno`/`msg:msgtext`，但這是**個別訊息子資源**的 namespace，class 層級 PUT 內嵌訊息時要換回 `mc:` 前綴＋同樣的 `msgno`/`msgtext` 屬性名）。
- **個別訊息子資源（`/messages/<no>`）自己的 LOCK 疑似有 bug**：對這個子資源呼叫 LOCK，不管重試幾次都回傳**完全相同的 LOCK_HANDLE**（不是每次重新產生的隨機值），且緊接著用這個 handle 呼叫 PUT 一律報 `ExceptionResourceInvalidLockHandle`（"is not locked"）——這暗示這個子資源的 LOCK 沒有真的在後端註冊。改回對 **Message Class 本身**（`/sap/bc/adt/messageclass/<class>`）做 LOCK，用該 lock handle PUT 整個 class（訊息當直接子元素，見上一條），才拿得到正常、可用的 lock handle 並讓 PUT 回 200。
- **⚠️⚠️ 即使 PUT 回 200 OK，訊息內容依然沒有真的存進去**：PUT 完之後不管是 GET class 本身（`changedAt` 時間戳完全沒變，跟建立當下一模一樣）還是 GET 個別訊息子資源（`msgno`/`msgtext` 都還是空字串），都證實**這次 PUT 沒有任何實際效果**；額外嘗試對 Message Class 呼叫 activation API（`POST /sap/bc/adt/activation?method=activate`）也一樣回 200 但完全沒有改變讀回的結果。這是本課程第二次遇到「PUT／POST 回 200/201，但實際資料沒有落地」的情況（第一次是第 14 節 Table Type 用錯 Content-Type 時），但這次已經確認 schema 正確、Content-Type 正確（`application/vnd.sap.adt.messageclass.v1+xml`），仍然存不進去，目前判斷是這個 RFC bridge／MCP server 版本對 Message Class 訊息內容寫入這塊**有實際的功能缺陷**，不是操作方式錯誤。
- **結論／Workaround**：Message Class 本身（空殼，`adtcore:name`/`adtcore:description`/套件）可以用 ADT 建立且會真的生效（第一次 POST 建立、GET 讀回確認 `version="active"`）；但**訊息文字（T100 的實際內容）目前這個環境無法透過 ADT 寫入，必須請使用者到 `SE91` 手動維護**——跟 Text Symbols／Search Help／T-code／權限物件同一類「GUI-only 收尾」的限制，但這次連「schema 對、Content-Type 對」都救不回來，是目前記錄過最頑固的一個案例。程式碼裡照樣可以直接寫 `MESSAGE e001(zen08) WITH ...`，只要訊息類別／編號存在（哪怕文字是空的），語法檢查跟啟用都不會擋，只是執行時顯示的文字要等使用者在 SE91 補上才會正確顯示。

## 30. 標準程式（如 `RM07MLBS`）Explicit Enhancement Point 消費者視角實戰：一支程式多個插入點對應 Report Event、`sap_get_source` 讀取已生效的 Explicit Enhancement 可能是快取舊值（2026-07-30 實測，Enhancement 課程 en08 案例三）

- **確認消費者視角可行**：真實標準程式 `RM07MLBS`（`MB52` 底層報表）裡同時存在幾十個 `ENHANCEMENT-POINT`/`ENHANCEMENT-SECTION`，全部 `SPOTS es_rm07mlbs`（同一個 Spot），且其中幾個已經被別的開發者掛了真實 Implementation（如 `MGV_LAMA_RM07MLBS` 加 `mfrpn` 欄位）——證實「消費者視角：找 SAP 已留好的插入點掛新 Implementation」在真實標準程式上是可行的，不需要（也不能）碰 `ENHANCEMENT-POINT`/`ENHANCEMENT-SECTION` 宣告本身。
- **一支程式裡的多個 Explicit Enhancement Point，位置對應 ABAP Report Event 階段**：`RM07MLBS` 的插入點不是隨機分布，而是精準對應到「選取畫面宣告區」（`STATIC`，給 `PARAMETERS`/`SELECT-OPTIONS` 用）、「內部資料結構宣告區」（`STATIC`，卡在 `DATA: BEGIN OF ... END OF ...` 中間，給擴充內部結構用）、`INITIALIZATION` 事件內（非 `STATIC`，給設定預設值/動態調整畫面文字用）、`START-OF-SELECTION` 之後的主要處理常式內（`ENHANCEMENT-SECTION`，給修改實際查詢邏輯用）——找插入點時可以先判斷「要加的東西屬於 Report 的哪個階段」，大幅縮小搜尋範圍，不用整支程式盲目找。
- **一個 Enhancement Implementation 可以包含多個 `ENHANCEMENT n` 區塊**：實測 `ZMB52_EE` 這一個 Implementation 物件內部同時掛了三個 `ENHANCEMENT n ... ENDENHANCEMENT.` 區塊，分別對應三個不同的插入點（選取欄位宣告／畫面文字設定／主查詢邏輯取代），比拆成三個各自獨立的 Implementation 物件更能表達「這是同一件客製化需求」的語意，SE38 Global Search 對這個 Implementation 名稱可以同時列出全部區塊。
- **⚠️ `sap_get_source` 讀取已被 Explicit Enhancement 過的標準程式，內容可能是快取的舊版本**：使用者已在 SE38 完成 Create Implementation 並 Activate 成功（SE38 Global Search 能查到新物件、`sap_inactive_objects` 回 0 筆），但同一時間用 `sap_get_source` 重新讀取該標準程式的合併原始碼，完全看不到任何新增內容（沒有新宣告的欄位、沒有新的 Enhancement 標記）。這跟第 10 節記載的「Data Preview 快取舊 nametab」是同一類現象——**這類物件的 ADT 讀取有自己的快取層，不能只憑「ADT 讀不到」就判斷使用者的 GUI 操作沒有真的生效**，真正的驗證要以 SAP GUI 實際畫面/執行結果為準（本案例最終是靠使用者在 `MB52` 畫面截圖＋實際查詢結果確認三個插入點都真的生效）。
- **掛在真實共用標準物件上的殘留 Implementation，跟掛在 `$TMP` 訓練物件上的殘留，清理急迫性完全不同**：本次意外發現使用者先前自己測試時留下的 `ZRM07MLBS3`（同樣宣告 `SELECT-OPTIONS: s_dispo for marc-dispo.`，指向同一個底層欄位，且確認是 Active），導致 `MB52` 選取畫面同時出現兩個重複的「MRP Controller」欄位——**這個殘留物件此刻正在影響所有正在使用 `MB52` 這個真實共用標準交易的人**，跟本檔一貫記載的「`$TMP` 訓練物件留著也無妨」是完全不同的風險等級，發現後應提醒使用者盡快清理，不能套用訓練物件的寬鬆標準。
- **`SELECT-OPTIONS` 宣告的變數用在 `WHERE ... IN` 條件時，使用者完全不輸入＝該欄位不生效**：這是 ABAP 語言本身的內建行為（空的 range table 用在 `IN` 條件會匹配所有值），不需要像 en04/en06 那樣額外手寫 `IF` 判斷特定條件才決定要不要套用篩選——只要新增的篩選條件本身是用 `SELECT-OPTIONS` 型別的變數（而非普通 `PARAMETERS`），「使用者沒填就不影響既有查詢行為」這個安全閘天生就內建在語言機制裡。

## 31. Source-based Class 存檔 `ExceptionResourceScanDuringSaveFailure`：錯誤訊息完全文不對題，兩個真正根因（2026-07-30 實測，Enhancement 課程 en08 案例一）

- **現象**：`sap_set_source`／PUT `/sap/bc/adt/oo/classes/<name>/source/main` 對某些內容一律回 `HTTP 400 ExceptionResourceScanDuringSaveFailure`，訊息宣稱「The class can't be separated into its different source parts (public-, protected-, (package-,) private section or method implementation)」——**這個訊息幾乎完全沒有診斷價值**，因為真正的根因跟 SECTION 能不能拆分毫無關係，靠系統性地從「全空方法」開始逐步加回內容才排除出來。
- **根因① `PROTECTED SECTION.` 這個區塊即使空白也必須明確存在**：把 `PUBLIC SECTION` 後面直接接 `PRIVATE SECTION`（完全省略 `PROTECTED SECTION.` 這一行）會讓這個 source-based 存檔的解析器整個崩潰，回上述誤導性錯誤。修法：即使用不到 protected 成員，`PROTECTED SECTION.` 這行也要保留（空的即可，緊接著寫 `PRIVATE SECTION.` 沒問題，不用留空行）。
- **根因② `CLASS-METHODS`／`METHODS` 的 `IMPORTING`／`EXPORTING`／`RETURNING`／`CHANGING` 參數宣告，型別不能用 `TYPE STANDARD TABLE OF <結構>` 這種 inline 寫法**——這種「`OF <結構>`」inline 語法**只能用在區域變數的 `DATA`/`TYPES` 陳述式**，用在 Method 正式參數宣告的 `TYPE` 子句上，會讓同一個 source-based 解析器崩潰、報出跟根因①一模一樣的誤導性錯誤（兩種完全不同的根因，卻共用同一句籠統錯誤訊息，這是本檔記錄過最難排錯的案例之一）。同樣的限制也適用於 **`FIELD-SYMBOLS` 宣告**（但錯誤訊息不同——`FIELD-SYMBOLS: <fs> TYPE STANDARD TABLE OF <結構>` 編譯期直接報 `"," expected after "TABLE"`，語法錯誤訊息至少還算精確）。
  - **正確 workaround**：Method 簽章維持泛型 `TYPE STANDARD TABLE`（不寫 `OF`）；方法內部若需要靜態型別化存取（例如要用 `SELECT ... FOR ALL ENTRIES IN <itab>` 這類需要編譯期知道 row type 的語句），先用具名 `TYPES tt_xxx TYPE STANDARD TABLE OF <結構>.` 定義一個型別，再讓 `FIELD-SYMBOLS: <fs> TYPE tt_xxx.` 參照這個具名型別（不能 inline），最後用一般 `ASSIGN <參數> TO <fs>.`（**不需要** `CASTING`，因為 `<fs>` 本身已經是靜態具體型別，直接指派即可讓執行期檢查是否相容）取得可用的靜態型別化存取。
  - **`ASSIGN ... CASTING TYPE STANDARD TABLE OF <結構>` 這招對 `SELECT ... FOR ALL ENTRIES` 沒用**：`CASTING` 只能讓 `ASSIGN COMPONENT` 這類**執行期動態**存取生效，Open SQL 的 `FOR ALL ENTRIES`／直接用 `<itab>-欄位` 這種**編譯期靜態**存取，`CASTING` 給的執行期型別資訊幫不上忙，一律要用「具名 TYPES＋FIELD-SYMBOLS 參照具名型別」這條路才行。
- **排錯方法論**：遇到這類「錯誤訊息籠統到像是騙人」的存檔失敗，不要照著錯誤訊息字面意思去改（例如去反覆檢查 SECTION 順序），改成**從已知可行的最小骨架開始，逐段加回內容，每加一段就存一次**，用二分法快速定位真正出錯的那一行/那個語法結構——這題最終是靠比對「哪一次改動」讓 200 OK 變成 400，才鎖定兩個根因分別是「拿掉 PROTECTED SECTION」和「Method 參數型別加了 OF」。

## 32. 新建的 Domain/DE 若未啟用就拿去給表格引用，表格存檔會報跟真正原因無關的錯誤（2026-07-30 實測，Enhancement 課程 en08 案例一）

- **現象**：POST 建立自訂 Domain（`ZEN08_SEQ`）＋Data Element（`ZEN08_SEQ`）都回 201 成功，但**沒有另外呼叫 activation**（POST 回應的 `adtcore:version` 其實是 `new`，不是 `inactive`，這個狀態比「未啟用」更早一個階段）；接著建立引用這個 DE 的表格（`ZEN08_COMPLOG`），`sap_set_source` 寫入內容後存檔一律回 `ExceptionResourceAlreadyExists: Can't save due to errors in source`——這句錯誤訊息**完全沒有指出「因為 DE 還沒啟用」**，容易誤判成鎖的問題或欄位命名問題（花了好幾輪排查殘留鎖、欄位型別才鎖定真因）。
- **排查方法**：對懷疑的新建 DE／Domain 直接 GET 讀回，檢查 `adtcore:version` 屬性——`"new"` 代表從未啟用過，`"inactive"` 代表存過但沒啟用，`"active"` 才是可以被其他物件正常引用的狀態。`sap_inactive_objects` 這個 MCP 工具**不會列出**這類剛建立、還處於 `new` 狀態的 DDIC 物件（目前只在使用者/物件被明確鎖定編輯時才會出現在清單裡），所以「`sap_inactive_objects` 回 0 筆」不能當作「所有相依物件都已啟用」的證據。
- **修法**：新建的 Domain／Data Element 建立後，**在拿去給任何表格/結構引用之前，先手動呼叫一次 activation API**（`POST /sap/bc/adt/activation?method=activate`，body 帶 `adtcore:objectReference` 指向該 Domain／DE 的 URI，可以把 Domain 跟 DE 放在同一個請求批次啟用），確認 GET 讀回 `adtcore:version="active"` 後，再建立/修改引用它們的表格。這是本檔第 8 節「Domain/DE/表可以放進同一個 activation 請求批次啟用」原則的具體應用——重點是**引用方（表格）動手之前，被引用方（Domain/DE）必須先確認是 `active` 狀態**，不能假設「POST 201 成功」就等於「已經可以被引用」。

## 33. Lock Object（ENQU）ADT 有唯讀 GET，但不是 source-based；CMOD Function Exit Include 就是普通 PROG/I（2026-07-30 實測，Enhancement 課程 en08 案例一收尾）

- **Lock Object 有 ADT collection**（discovery 找得到 `/sap/bc/adt/ddic/lockobjects/sources`），GET `/sap/bc/adt/ddic/lockobjects/sources/<name>` 可以正常讀到完整結構化 XML（`enqu:lockobject`，含 Primary Table／Lock Mode／Lock Parameters／自動產生的 Enqueue-Dequeue FM 清單／`adtcore:version`），可以用來確認 Lock Object 是否 `active`、Lock Parameters 是否正確——這點跟第 10 節「Search Help 完全沒有 ADT 路徑」不同。
- **但 Lock Object 不是 source-based**：GET `/sap/bc/adt/ddic/lockobjects/sources/<name>/source/main` 回 `No suitable resource found`，代表沒有像 Table DDL 那樣的純文字原始碼可讀寫，只有這份結構化 XML（也沒有 `sap_get_source`/`sap_set_source` 的 objectType 選項）。**匯出到 `src/` 時不適用 `.abap` 慣例**，改存一份 pretty-print 過的 `.enqu.xml`（比照 abapGit 對非 source-based DDIC 物件用 XML 序列化的慣例），純粹當作唯讀快照留存 Lock Mode／Lock Parameters 設定內容，不是可寫回系統的原始碼。
- **CMOD Project 底下、雙擊 Component 生成的 Function Exit Include（如 `ZXCO1U01`），本質就是一般 `PROG/I` Include**，第 1 節記載的「INCLUDE 讀寫走 `programs/includes` 路徑」workaround 直接適用，讀寫上沒有任何特殊之處——延續第 21 節已經記載過的結論（`ZX` 開頭 Include 只是建立方式特殊，需要 CMOD 雙擊觸發生成，生成後就是普通 Include），這裡再次確認：**這類 Include 一樣要匯出進 `src/`**，用 `<include名小寫>.prog.abap` 命名，跟主程式的 INCLUDE 匯出慣例一致。

## 匯出 SAP 原始碼到 src/ 的慣例

- 檔名採 abapGit 格式：`<物件名小寫>.<類型>.abap`（如 `zdqm0001.prog.abap`；INCLUDE 也是 `.prog.abap`）。
- 主程式要連同其 INCLUDE 一起匯出；多支程式共用的 INCLUDE 只存一份。
- **CMOD Project 底下生成的 Function Exit Include（如 en02 的 `ZXVBZU01`/`ZXVBZU02`、en08 案例一的 `ZXCO1U01`）也適用這條慣例**：本質是普通 `PROG/I`，一樣用 `<include名小寫>.prog.abap` 匯出，不需要額外記錄 CMOD Project 本身（CMOD Project／Assign／Activate 是 GUI-only 設定，沒有可匯出的原始碼）。
- **Lock Object（ENQU）不適用 `.abap` 慣例**：它是結構化 DDIC 物件、沒有純文字原始碼，改存 `.enqu.xml`（GET 該物件 ADT 回應的 pretty-print 版本），見上方第 33 節。
- **DDIC Structure（STRU）是 source-based（`DEFINE STRUCTURE` DDL），適用 `.abap` 慣例**：存成 `<物件名小寫>.stru.abap`（如 `ztr15_flight_rev.stru.abap`），跟 Table（`.tabl.abap`）同一類。
- **DDIC Table Type（TTYP）不是 source-based**（第 14／39 節），沒有純文字原始碼，改存 `<物件名小寫>.ttyp.xml`（GET 該物件 ADT 回應的精簡版，只留 `rowType`/`accessType`/`primaryKey` 等有意義欄位，省略 API 回應裡的靜態列舉值清單）。
- Function Module（FUGR/FF）沒有獨立物件字尾慣例，用 `.func.abap`（如 `z_tr15_calc_revenue_tab.func.abap`），跟既有的 `z_tr15_calc_revenue.func.abap` 一致。
- `src/` 是**單向快照**：SAP 端修改後需重新匯出；本地修改要用 `sap_set_source` 寫回系統才算數。

## 34. 「以可重建角度全面 Review」的方法論，與非 `.abap` 快照的完整命名規則（2026-07-30 實測，Enhancement 課程 en01~en08 收尾稽核）

**背景**：課程做到 en08 收尾時，使用者要求「以可以參考重建的角度」全面 Review 整個 Enhancement 課程，檢查是否有 ABAP Object 沒有備份回 `src/`。這帶出一個先前沒有系統化處理過的問題：**課程中有好幾類物件既不是純文字原始碼（不適用 `.abap`），也完全不是 GUI-only（有 ADT 讀取路徑），過去只顧著匯出 Class/Program/Table，漏掉了這一整類「結構化但可讀」的物件**。稽核方法：不要憑印象或記憶檔案的敘述判斷「已經備份」，要逐一對每個課程中出現過的 Z 物件名稱實際打 ADT GET／TADIR quickSearch 驗證，因為記憶檔案可能記錄的是「設計/講義寫的」而非「系統裡實際存在的」。

**本次稽核結果與補齊的物件**：

| 物件類型 | ADT 端點 | 內容型態 | 檔名慣例 | 本次補齊物件 |
|---|---|---|---|---|
| BAdI Definition／Enhancement Spot（`ENHS/XS`，`toolType=BADI_DEF`） | `GET /sap/bc/adt/enhancements/enhsxs/<name>` | 結構化 XML（Interface／Fallback Class／Filter 定義） | `.enhs.xml` | `zes_en05_greeting.enhs.xml`／`zes_en06_filter_demo.enhs.xml` |
| BAdI Implementation 容器（`ENHO/XH`，`toolType=BADI_IMPL`） | `GET /sap/bc/adt/enhancements/enhoxh/<name>` | 結構化 XML（指向哪個 Class／哪個 Spot／Filter 組合值） | `.enho.xml`（**注意跟 Source Code Plugin 內容的 `.enho.abap` 副檔名不同**，這裡是純 metadata 沒有文字原始碼） | `zim_en05_greeting.enho.xml`／`zim_en06_greeting2.enho.xml`／`zim_en06_workorder_atsave.enho.xml`／`zim_en06_filter_aa.enho.xml` |
| Source Code Plugin／Explicit Enhancement 內容（`ENHO/XHH`，`toolType` 非上述兩者） | `GET /sap/bc/adt/enhancements/enhoxhh/<name>/source/main` | **純文字**（可以直接讀寫，跟第 23 節記載一致） | `.enho.abap` | `zim_co_cost_auth.enho.abap`（en08 案例二 Implicit Enhancement 內容）／`zmb52_ee.enho.abap`（en08 案例三，含 3 個 `ENHANCEMENT n` 區塊）／`zei_en07_section_append.enho.abap`（en07 用來證明「只有整段取代沒有追加」的反證測試物件，保留當作反面教材） |
| Domain | `GET /sap/bc/adt/ddic/domains/<name>` | 結構化 XML | `.doma.xml` | `zen08_seq.doma.xml` |
| Data Element | `GET /sap/bc/adt/ddic/dataelements/<name>` | 結構化 XML | `.dtel.xml` | `zen08_seq.dtel.xml` |
| Message Class | `GET /sap/bc/adt/messageclass/<name>` | 結構化 XML（**含訊息文字**，見下方重要更正） | `.msag.xml` | `zen08.msag.xml` |

**⚠️ 重要更正：第 29 節記載的「Message Class 訊息文字 ADT 寫入失敗」只代表 PUT 失敗，不代表 GET 讀不到**——本次重新 GET `zen08` 這個 Message Class，訊息 `001` 的 `mc:msgtext` 屬性正確顯示使用者事後在 SE91 補上的完整中文文字（「沒有權限顯示廠別 &1 的成本分析」），代表**使用者用 SE91 手動維護過的內容，之後可以正常用 ADT GET 讀回**，只是「用 ADT 寫入」這條路走不通，讀取沒有問題。之前只顧著記錄寫入失敗，沒有回頭驗證「GUI 補完之後能不能讀」，是這次稽核才補上的驗證缺口。

**⚠️ Explicit Enhancement 的 Spot 定義本身（`toolType` 實際是 `HOOK_DEF`，涵蓋 Explicit Point 跟 Section 兩種）目前這版環境完全無法 GET**（一律 `HTTP 500 Enhancement technology HOOK_DEF is not supported yet`），這是第 26 節已經記載過的限制，這次針對 en07 的 point（`ZES_EN07_V3`）與 section（`ZES_EN07_SECTION_V1`）兩種都重新驗證過，確認限制對兩者一致套用——**這個 Spot 本身沒有任何快照方式，只能靠講義文字描述＋使用者的 SAP GUI 畫面截圖佐證存在**；但掛在它上面的 Implementation 內容（`ENHO/XHH`，上表第三列）不受影響，可以正常快照。

**確認完全無法備份、原因是物件本身沒有 ADT 內容（非本次稽核缺失）**：
- **`ZWORKORDER_INFO`**（en03，Classic BAdI Implementation，物件型別是 `SXCI/XI`）：quickSearch 只回一個 `vit/wb/object_type/sxcixi/...` 唯讀 metadata stub 連結，沒有任何 `source`／`content` 子資源——這是 Classic（`SXSD/XD`）BAdI 的 Implementation 對應物件，跟 SMOD/CMOD 同一類「純 GUI」限制，符合第 20 節記載的模式（`CMOD/XP` 也只有 metadata stub）。實際邏輯已經完整在 `ZCL_IM_WORKORDER_INFO`（已備份）裡，這個 SXCI/XI 容器本身只是「哪個方法對應哪個 Class」的指標，遺漏它不影響能不能重建邏輯，只是要記得**重建時這一步（SE19／哪個方法委派給哪個 Class）沒有文字紀錄，得靠講義敘述手動重做**。
- **Explicit Enhancement Spot（`HOOK_DEF`）本身**：見上一段。

**✅ 已解決（2026-07-30 補課）：`ZIM_EN06_FILTER_LH` 補建完成，且揭露 BAdI Implementation 的 TADIR 登記名稱規則**——原本 `SELECT OBJ_NAME FROM TADIR WHERE OBJECT='ENHO' AND OBJ_NAME LIKE 'ZIM_EN06%'` 查不到 `ZIM_EN06_FILTER_LH`，是因為**這個查詢的假設本身就錯了**：TADIR 登記的是 SE19「Create Enhancement Implementation」對話框裡填的**容器層級名稱**，不是後面「Create BAdI Implementations for Existing BAdI Definitions」表格裡填的 BAdI Implementation 名稱——兩者是同一個操作流程的兩層包裝，`ZIM_EN06_FILTER_AA` 案例當初剛好兩層都取同名，所以查起來像是「BAdI Implementation 名稱」，但 `LH` 案例容器取名 `ZEI_EN06_FILTER_LH`，TADIR／`GET /sap/bc/adt/enhancements/enhoxh/<容器名>` 只認得到容器名，回應 XML 裡的 `enho:badiImplementation` 元素才是實際 Filter 設定（`enho:name`／`enho:filterTree` 等）。使用者在 SE19 補建後，`programrun` 重跑 `ZR_EN06_FILTER_DEMO` 確認 `LH`／`AA`／`UA` 三種情境全部正確（分別觸發對應 Implementation／哨兵值不變），快照存為 `zei_en06_filter_lh.enho.xml`。**教訓：查證某個 BAdI Implementation 是否存在，要用「容器名稱」去查 TADIR／ADT，不能只用「BAdI Implementation 名稱」去查，兩者不一定相同。**

**發現但刻意不處理的殘留/廢棄物件（不在這次備份範圍內，屬於課程過程中的死路徑）**：
- en07 除錯過程留下三個未使用的 Enhancement Spot（`ZES_EN07_EXPLICIT_DEMO`／`ZES_EN07_POINT_DEMO`），實際生效的是 `ZES_EN07_V3`（`ZR_EN07_EXPLICIT_DEMO` 的 `ENHANCEMENT-POINT ... SPOTS` 子句證實）——這些是第 26 節「使用者初版結論被推翻」那次除錯過程中的失敗嘗試，`$TMP` 套件、不影響任何人，跟本課程一貫的「訓練殘留物無妨」原則一致，不特別清理也不特別備份。
- en08 案例三的 `ZRM07MLBS3`（掛在真實共用 `MB52` 交易上，非本課程物件）——延續先前已記載的結論，這是使用者自己的殘留測試物件，待使用者清理，不屬於「本課程 Z 物件備份」範圍。

**✅ 已修正（2026-07-30）**：`zen04_pltauart`/`zen04_rule`/`zen04_seq`/`zen06_atsave_log` 四張表的 Client 欄位已全部改為 `key mandt : mandt not null;`（引用標準 DE `MANDT`），使用者確認後逐一修正並重新啟用，過程詳見第 35 節。

## 35. 全面把課程既有表格欄位補上 Data Element：既有資料型別轉換不會遺失、但「跑測試程式前忘記同步推送新版原始碼」會（2026-07-30 實測，Enhancement 課程 en04/en06 收尾）

- **DDIC 表格欄位從 Builtin Type 改成引用「底層型別完全相同」的 Data Element（如 `abap.char(4)` → `WERKS_D`），不需要 SE14 資料轉換、既有資料表列數不受影響**——本次把 `zen04_pltauart`/`zen04_rule`/`zen04_seq`/`zen06_atsave_log` 四張表的所有欄位（除了已修正的 `mandt`）都從 Builtin Type 改成標準或自建 Data Element，每次 `sap_set_source`→清鎖→activate 後都有用 `datapreview/freestyle` 的 `SELECT COUNT(*)` 確認資料列數不變，全部確認資料完整保留。**這跟第 14 節記載的「Table Type 用錯 Content-Type 會靜默把內容退回預設值」是不同性質的風險**——這裡驗證過，只要新舊型別的底層資料型態一致，DDIC 型別變更是安全的。
- **有語意相符的標準 Data Element優先重用**（`WERKS`→`WERKS_D`、`AUART`→`AUFART`、`FEVOR`→`FEVOR`、`AUFNR`→`AUFNR`，四者的底層型別/長度都跟原本的 Builtin Type 完全一致，可以直接查 `GET /sap/bc/adt/ddic/dataelements/<name>` 確認 `dtel:dataType`/`dtel:dataTypeLength` 相符再套用）；**沒有語意相符標準 DE 的課程自訂欄位（`ZGRTYPE`/`LEADCODE`/`STNUM`/`ZYEAR`/`ZMONTH`/`NUMNO`），沿用 en08 案例一 `ZEN08_SEQ` 的模式，各自新建一組 Domain+DE**（`ZEN04_ZGRTYPE`/`ZEN04_LEADCOD`/`ZEN04_STNUM`/`ZEN04_ZYEAR`/`ZEN04_ZMONTH`/`ZEN04_NUMNO`，`ZEN04_LEADCOD` 少打一個 `E` 純屬命名失誤，$TMP 物件無法改名，直接沿用不影響功能）。**多個 Domain／多個 DE 可以各自單獨 POST 建立，再合併成一個 activation 請求批次啟用**（本檔第 8 節原則的再次驗證，這次是 6 組 Domain+DE 一次性批次處理）。
- **⚠️⚠️ 真正造成資料遺失的不是 DDIC 型別變更，是「以為程式已經改好、其實系統上還是舊版本」**：本次在幫 `ZR_EN06_ATSAVE_UNIT_TEST` 加一段 `NUMBER_SWITCH` 驗證邏輯時，先用 `Edit`/`Write` 工具改了**本地檔案**，接著就直接呼叫 `programrun` 執行——但改完本地檔案之後，忘記先呼叫 `sap_set_source` 把新版本推回 SAP！執行到的其實是**系統上還沒被覆蓋的舊版本**，而舊版本的第一段程式碼是 `DELETE FROM zen06_atsave_log WHERE werks = '1011' AND auart = 'PP71'.`（沿用課程早期為了「方便重跑測試」寫的清理邏輯，用業務條件而非測試專屬值篩選），這一執行就把資料表裡兩筆真實 CO01 存檔留下的稽核記錄（分別是 7/29、7/30 建立的兩張不同真實工單）永久刪除且 `COMMIT WORK` 過，無法復原。**教訓與修正做法**：
  1. **任何會執行 `DELETE`/`UPDATE`/`COMMIT WORK` 的驗證/測試程式，修改後、執行前，一定要先確認 `sap_set_source` 真的成功推送且已啟用**（`sap_get_source(version=active)` 讀回來跟本地檔案逐字比對，或至少確認有呼叫過 `sap_set_source`），不能只改了本地 `.abap` 快照檔案就假設系統上也同步了——這兩者是完全獨立的兩份拷貝，`Edit`/`Write` 工具永遠只碰本地檔案，只有 `sap_set_source` 才會真的觸及 SAP 系統。
  2. **任何測試程式的「清理舊記錄」邏輯，只應該鎖定測試專屬的值域**（例如特定前綴、特定字面值如 `UNITTEST001`），不應該用 `werks`/`auart` 這種跟真實業務資料同一個值域的條件做 `DELETE`——否則這支測試程式本質上對「這個安全閘條件下的所有真實資料」都是一顆不定時炸彈，每次重跑都可能清掉不相干的真實稽核記錄。事後已把 `ZR_EN06_ATSAVE_UNIT_TEST` 兩處 `DELETE` 都改成只鎖定測試用 `AUFNR`（`UNITTEST001`/`UNITTEST002`/`%TESTTEMP01`/`UT_FINAL001`），不再用 `werks`/`auart` 全面刪除。
  3. **這個資料遺失沒有復原手段**（$TMP 訓練表、沒有備份、DB 層級的 `DELETE`+`COMMIT` 無法復原），只能誠實記錄、更新講義說明「這兩筆記錄已遺失」，並改用單元測試（不消耗真實 Number Range、不建立真實工單）補上等效的驗證證據。
- **`WORKORDER_UPDATE`／`AT_SAVE` 的 `AUFNR` 在新建工單情境下是暫時號碼（如 `%00000000001`），每次新建工單都從這個暫時號碼重新起算，不同真實工單會共用同一個暫時號碼**——這不是隨機巧合或 bug，是 SAP 標準機制：`IF_EX_WORKORDER_UPDATE` 介面本身就有一個專用方法 `NUMBER_SWITCH(I_AUFNR_OLD, I_AUFNR_NEW, I_AUFPL_OLD, I_AUFPL_NEW, I_AUTYP)`，在真正的號碼從 Number Range 確定後另外呼叫，通知「暫時號碼 → 真實號碼」的對應。**任何在 `AT_SAVE`（或類似「存檔當下」的掛勾點）記錄新建物件編號的稽核/Log 設計，都要檢查該 BAdI Interface 是否也提供類似的「號碼確定後」回呼方法，否則記錄下來的編號可能只是暫時佔位值，同一個值會被不同的真實物件重複使用，讓稽核記錄失去可追溯性**——這個模式（先給暫時號碼、確定後再廣播真實號碼）在 SAP 許多「建立時前端就要顯示編號、但編號要等交易確定才能寫死」的物件類型（生產工單、部分銷售單據等）都存在，不是 `WORKORDER_UPDATE` 獨有。
- **`I_AUFPL_OLD`/`I_AUFPL_NEW`（途程 Routing Plan 編號）在 `NUMBER_SWITCH` 簽章裡是必填參數（沒有 `OPTIONAL`），即使呼叫端邏輯用不到也必須傳值**（傳 `'0000000000'` 這種安全佔位值即可，不影響邏輯），漏傳會在啟用時報 `No value was passed to the mandatory parameter`。

## 36. `sap_set_source` 內建的自動啟用步驟回報「User XXX is currently editing」403，可能是工具本身的 bug，不是真實鎖——SM12 查無 Lock Entry 時直接改用手動 curl activation（2026-07-31 實測，基礎課 ex28 收尾）

- **現象**：`ZR_TR28_PARAM_MAINT` 補推送 `dba_sellist` 篩選修正版，連續兩次呼叫 `sap_set_source` 都寫入成功（`status: success`）但自動啟用失敗，回報 `HTTP 403 ExceptionResourceNoAccess: User MONICA is currently editing ZR_TR28_PARAM_MAINT`；中間有照第 5 節標準流程做過 `sap_lock`→`sap_unlock` 清鎖，`sap_unlock` 也回報成功，但下一次 `sap_set_source` 的自動啟用一樣報同一個錯誤，訊息一字不差。
- **關鍵排除證據**：使用者直接在 **SM12 查詢 MONICA 這個使用者的 Lock Entry，結果是空的**——代表 SAP 端根本沒有真正的 ENQUEUE 鎖存在，錯誤訊息裡「User MONICA is currently editing」的診斷文字（本來設計是給「有其他人在 SE38 編輯畫面鎖著」這種情境）在這裡是**誤導性的**，真正原因出在 **`sap_set_source` 工具內部呼叫 activation API 這一步本身有問題**（推測是 CSRF token 沒有正確帶入、或工具內部維護的 session 狀態沒有跟這次呼叫同步），不是 SAP 系統真的鎖住了這支程式。
- **Workaround（繞過工具內建的自動啟用邏輯，改手動兩步 curl）**：
  ```bash
  # 1. 取得 CSRF token 與 session cookie（token 固定回 ADT-RFC-BRIDGE）
  curl -c jar.txt -b jar.txt -H 'x-csrf-token: fetch' 'http://127.0.0.1:8410/sap/bc/adt/discovery?sap-client=130' -o /dev/null -D -

  # 2. 直接呼叫 activation API，物件 URI 用 programs/programs（PROG）或對應型別的路徑
  curl -b jar.txt -H 'x-csrf-token: ADT-RFC-BRIDGE' -H 'Content-Type: application/vnd.sap.adt.activation+xml' \
    -X POST 'http://127.0.0.1:8410/sap/bc/adt/activation?method=activate&preauditRequested=true&sap-client=130&sap-language=EN' \
    --data '<?xml version="1.0" encoding="UTF-8"?><adtcore:objectReferences xmlns:adtcore="http://www.sap.com/adt/core"><adtcore:objectReference adtcore:uri="/sap/bc/adt/programs/programs/<程式名小寫>"/></adtcore:objectReferences>'
  ```
  這次一次就成功（`HTTP 200`，`Content-Length: 0`，無錯誤內容）；事後用 `sap_inactive_objects`（回 0 筆）＋`sap_get_source(version=active)`（內容比對本地檔案逐字相符）雙重確認啟用真的生效，不是誤判。
- **教訓／排錯順序**：`sap_set_source` 回報 activation 403「User XXX is currently editing」時，**不要立刻假設是真實 GUI 編輯畫面造成的殘留鎖、也不要無止盡重試 `sap_set_source`**——這類重試只會不斷重現同一個工具內部 bug，不會自己好（本次案例重試了三次以上、跨越前後兩次對話都失敗）。正確順序：① 先請使用者用 SM12 查證該使用者名稱是否真的有 Lock Entry；② 如果 SM12 是空的，直接跳過 `sap_set_source` 的自動啟用，改用上面這段手動 curl workaround；③ 如果 SM12 確實查到 Lock Entry，才照第 5 節「請使用者關閉 SE38 編輯畫面／SM12 手動刪鎖」的方式處理。
- 這個案例也再次印證第 4 節記載的 `sap_syntax_check` 500 問題與其 workaround（`checkruns` API）：補推送後驗證語法時同樣要繞過工具、改走 curl。

## 37. `REUSE_ALV_GRID_DISPLAY`（Functional ALV）在 `programrun` 無頭環境會自動退化成文字清單，`cl_salv_table`（OO ALV）則會卡住斷線——兩者行為不同，前者可以無頭驗證（2026-07-31 實測，基礎課 ex28 改版）

- **背景**：本檔第 16 節已經記載過「`cl_salv_table`／`REUSE_ALV_GRID_DISPLAY` 這類會開全螢幕畫面的呼叫，沒辦法透過 ADT 的無頭 `programrun` API 驗證」——這個結論其實只精確驗證過 `cl_salv_table`（OO ALV），這次改版 `ZR_TR28_PARAM_LIST` 用 `REUSE_ALV_GRID_DISPLAY`（Functional ALV）意外發現**兩者行為並不相同**。
- **實測**：`ZR_TR28_PARAM_LIST` 用 `REUSE_ALV_GRID_DISPLAY` 顯示 `ZTR28_CDISC` 兩筆資料，透過 `POST /sap/bc/adt/programs/programrun/<程式>` 無頭執行，**沒有卡住、沒有 `RFC_CLOSED`**，直接回傳文字化的清單輸出（欄位標題＋逐列資料，用 ASCII 分隔線排版），可以直接讀出來驗證欄位對不對、資料筆數對不對。
- **推測原因**：`REUSE_ALV_GRID_DISPLAY` 底層在偵測不到真正的 GUI Container／Screen 環境時，會 fallback 成傳統 Classical List（用 `WRITE`／`FORMAT` 系列語句組版），這是 Functional ALV 框架本身就有的相容性設計；`cl_salv_table` 是純物件導向、綁定 Container 的現代 ALV，沒有這種 fallback，偵測不到畫面環境就直接卡住等待。
- **教學上的實務影響**：如果某一門課（如本課程 `ABAP_Training` 基礎課）選用 `REUSE_ALV_GRID_DISPLAY` 而非 `cl_salv_table`，除了跟課程既有進度一致（ex09 已教過 Functional ALV，OO ALV 留給 OOP 課程）之外，還多一個實用好處：**寫完程式可以直接用 `programrun` 驗證 ALV 輸出的資料正確性，不用等使用者到 SAP GUI 才能確認邏輯對不對**，只有真正的畫面呈現效果（顏色、排序點擊、匯出等互動功能）才需要使用者在 GUI 手動確認。
- **不要因此推翻第 16 節的結論**：`cl_salv_table` 卡住斷線的限制依然成立，這兩節要對照著看——第 16 節講的是 OO ALV，這裡新增的是 Functional ALV 的例外情況，選型時如果預期需要無頭驗證，Functional ALV（`REUSE_ALV_GRID_DISPLAY`）會比 OO ALV（`cl_salv_table`）更適合。

## 38. ⚠️ 重要更正／補充：一旦某個特定 PROG 物件的 `programrun` 卡住過一次（`RFC_CLOSED`），這個物件之後會持續卡住，不管怎麼改程式碼都一樣——是物件層級被卡住，不是程式碼問題（2026-07-31 實測，基礎課 ex28，`ZR_TR28_PRICE_CALC`）

- **現象**：第 37 節驗證 `ZR_TR28_PARAM_LIST` 的 `REUSE_ALV_GRID_DISPLAY` 可以無頭驗證之後，緊接著幫 `ZR_TR28_PRICE_CALC` 也加上同樣的 ALV 輸出＋`SELECTION-SCREEN FUNCTION KEY` 按鈕，第一次 `programrun` 就卡住回 `RFC_CLOSED`。之後為了排錯，**連續五次**調整程式碼（加大 `LINE-SIZE`、砍欄位數／砍到只剩 3 欄、砍資料列數到 `UP TO 1 ROWS`、拿掉 `SELECTION-SCREEN FUNCTION KEY`/`sscrfields`、幫 fieldcat 補上 `REF_TABNAME`/`REF_FIELDNAME`）、每次都重新 `sap_set_source`＋手動 curl activation 確認啟用成功，**全部一樣卡住 `RFC_CLOSED`**，連改回最初能正常執行的權限檢查程式 `ZR_TR28_PARAM_MAINT`（原本這次對話稍早才成功跑過）都跟著開始卡住。
- **關鍵排除實驗**：另外建一個全新物件 `ZR_TR28_ALVTEST`（跟卡住版本一模一樣的程式結構：同樣的本地 `TYPES` 結構、同樣的 fieldcat macro、同樣的 `REUSE_ALV_GRID_DISPLAY` 呼叫，只是資料改成寫死一筆），`programrun` **立刻正常執行**、回傳文字化 ALV 清單——證實問題**跟程式碼寫法完全無關**（不是 ALV 欄位寬度、不是列數、不是本地 TYPES 缺 DDIC 型別、不是按鈕/`sscrfields`），而是 `ZR_TR28_PRICE_CALC`（以及巧合下同一時段的 `ZR_TR28_PARAM_MAINT`）這兩個**特定物件**在 SAP 端被卡住了。
- **推測機制**：`programrun` 很可能不是每次都開全新、無狀態的執行環境（如同第 17 節原本假設的），而是**針對同一個「使用者+程式」組合重用某種 Dialog/Session 狀態**；一旦某次呼叫因為程式內部走到需要畫面互動的邏輯（例如 `ZR_TR28_PARAM_MAINT` 這次很可能是因為使用者已經在背景完成 PFCG 授權，導致 `AUTHORITY-CHECK` 通過、程式真的走到 `VIEW_MAINTENANCE_CALL` 這個第 5 節已知會卡住的呼叫）而卡死不返回，**這個卡死的 Session 會被同一支程式之後所有的 `programrun` 呼叫重新接上**，導致後續呼叫看起來像是「這支程式怎麼改都卡住」，實際上是重複打到同一個殭屍 Session。全新物件（沒有卡死歷史）自然不受影響。
- **教訓／排錯方法論**：
  1. **`programrun` 連續卡住 `RFC_CLOSED` 時，不要無止盡調整程式碼猜測原因**——先用一個全新建立的最小化測試物件（結構抄一份，資料寫死）重現同樣的呼叫方式，如果新物件正常，就能直接排除「程式碼邏輯有問題」，把懷疑方向轉成「這個特定物件的 Session 卡住了」。
  2. **懷疑物件被卡住時，檢查是不是曾經呼叫過已知會卡住 headless 環境的邏輯**（`VIEW_MAINTENANCE_CALL`、`cl_salv_table`、或任何會開全螢幕互動畫面的呼叫，見第 5／16 節）——特別是像 `ZR_TR28_PARAM_MAINT` 這種「權限檢查+維護畫面」的 Wrapper 程式，隨著使用者在背景逐步完成 PFCG 授權，同一支程式在不同時間點呼叫可能從「權限不足、快速返回」變成「權限通過、卡在維護畫面」——**程式本身沒有改，但外部狀態（授權是否到位）變了，導致 `programrun` 的行為從能測變成不能測**，這不是 bug，是預期之內的行為轉變。
  3. **目前沒有已知的 ADT 端 workaround 可以清除這個卡住的 Session**（不是 ENQUEUE 鎖，`sap_lock`/`sap_unlock` 對這個無效；也不是 activation 殘留，`sap_inactive_objects` 一路都是 0 筆）。這種情況下：程式碼本身如果已經過 `checkruns` 語法檢查確認無誤、且邏輯已經用其他方式驗證過（例如用一個全新測試物件驗證同樣的呼叫結構能正常執行），就可以合理判斷**程式碼是對的，只是這個物件的 headless 驗證管道暫時不可用**，请使用者改到 SAP GUI（SE38 F8／T-code）直接測試即可，不需要繼續在 ADT 這邊除錯。

## 39. FM 的 `CHANGING`/`TABLES` 介面參數型別不能引用 Function Group Top Include 的本地 `TYPES`，只能是 DDIC 型別或 Type Group（2026-08-02 實測，基礎課 ex15 Part 4）

- **現象**：在 Function Group `ZFG_TR15` 的 Top Include（`LZFG_TR15TOP`）宣告一組本地 `TYPES`（`ty_flight_rev` + `tt_flight_rev TYPE STANDARD TABLE OF ty_flight_rev ...`），確認該 Include 已成功啟用（GET `version=active` 內容正確）後，建立新 FM `Z_TR15_CALC_REVENUE_TAB`，`CHANGING VALUE(ct_flights) TYPE tt_flight_rev` 引用這組本地型別——啟用時一律報 `"TT_FLIGHT_REV" is not a predefined type or a type from a type group.`（出現在系統自動產生的介面展開 Include，如 `LZFG_TR15$02`）。嘗試過：① 分開先啟用 TOP 再啟用 FM、② 整個 Function Group 一起啟用、③ 重新寫入 FM 原始碼再啟用，**全部同樣的錯誤**，確認不是啟用順序或殘留鎖的問題，是真正的語法限制。
- **根本原因**：FM 的正式介面（`IMPORTING`/`EXPORTING`/`CHANGING`/`TABLES` 的型別）必須能被**呼叫端獨立語法檢查**，不能依賴「這支 FM 所屬的 Function Group 是否已經被載入」——Function Group 的 Top Include 只有在該 Group 被載入（呼叫過裡面某支 FM）時才會生效，對「還沒呼叫過、只是要對這次 CALL FUNCTION 做語法檢查」的呼叫端程式來說是不可見的。錯誤訊息裡的「or a type from a type group」是關鍵字：**FM 介面參數合法的型別來源只有 DDIC 型別、或（舊式）Type Group（`TYPE-POOLS`）**，本地 `TYPES`（不管宣告在 Top Include 或 FM 本體）都不算數。DATA 宣告（FM 內部的區域變數）則完全沒有這個限制，可以自由用 Top Include 的本地型別。
- **Workaround**：改用 DDIC Table Type（`TTYP`，第 14 節記載的建立方式：先建 DDIC Structure 當 Line Type，再建 Table Type 指向它）。這也更貼近「CHANGING + Table Type 取代 TABLES」這個教學重點原本想強調的做法——用真正的 DDIC Global Type，而不是包裝在另一種區域型別裡。
- **連帶踩到的 DDIC Structure 建立坑**：
  1. `DEFINE STRUCTURE` 的必填 annotation，官方文件（`ABENDDICDDL_DEFINE_STRUCT_PROPS`）字面寫的是 `@AbapCatalog.enhancement.category`（帶點），但這個系統實際存入 DDL 原始碼、系統自動產生的樣板顯示的是 **`@AbapCatalog.enhancementCategory`（駝峰單詞，不帶點）**——照文件字面抄會導致 PUT 一律回 `ExceptionResourceAlreadyExists: Can't save due to errors in source`（但 `checkruns` 卻回報無錯誤，兩者矛盾，這個矛盾本身就是「annotation 名稱錯但系統沒把它當語法錯誤來報」的線索）。**排錯技巧**：懷疑 annotation 名稱寫錯時，直接 GET 該物件剛建立、還沒寫入內容前的預設樣板（`component_to_be_changed : abap.string(0);` 那種），看樣板裡系統自己產生的 annotation 打法，比照抄官方文件字面更可靠。
  2. 兩個欄位共用同一個金額型 DE（如 `S_PRICE`，`CURR` 型別）時，啟用會報 `ZTR15_FLIGHT_REV-REVENUE (specify reference table AND reference field)`——金額欄位需要一個參考幣別欄位，兩個金額欄位模糊了自動推導。修法：加一個 `CURRENCY : s_currcode;` 欄位，並在每個金額欄位加 `@Semantics.amount.currencyCode : 'ztr15_flight_rev.currency'` annotation 明確指向它。

## 40. RAP（ABAP RESTful Application Programming Model）可行性查證：這個系統是「Classic RAP」世代——沒有 View Entity 語法、沒有 strict mode，但 Managed BDEF 全鏈路可以透過 ADT 建立並啟用；Service Binding「Publish」無 ADT API（2026-08-02 實測，開課前查證，`$TMP` 物件 `ZRAPT01`/`ZI_RAPT01`/`ZRAPT01_SD`/`ZRAPT01_SB`）

**背景**：使用者評估要不要在目前這個系統（GET discovery 顯示 `adtcore:masterSystem="S4H"`，非單純 ECC 1909）開 RAP 課程，先查證這個 MCP／ADT 環境對 RAP 物件（BDEF/DDLX/SRVD/SRVB）的支援程度，用一個最小 Managed RAP BO 端對端驗證。

### 40.1 Discovery 確認四個 RAP 物件型別都有 ADT collection

`/sap/bc/adt/discovery` 找得到：
- `/sap/bc/adt/bo/behaviordefinitions`（BDEF，`Content-Type: application/vnd.sap.adt.blues.v1+xml`，root `blue:blueSource`——跟 Table/Structure 共用同一個 schema 家族）
- `/sap/bc/adt/ddic/srvd/sources`（Service Definition，`application/vnd.sap.adt.ddic.srvd.v1+xml`，root `srvd:srvdSource`，namespace `http://www.sap.com/adt/ddic/srvdsources`）
- `/sap/bc/adt/ddic/ddlx/sources`（Metadata Extension，`application/vnd.sap.adt.ddic.ddlx.v1+xml`）
- `/sap/bc/adt/businessservices/bindings`（Service Binding，`application/vnd.sap.adt.businessservices.servicebinding.v1+xml`，root `srvb:serviceBinding`，namespace `http://www.sap.com/adt/ddic/ServiceBindings`）

quickSearch（`objectType=BDEF/BDO`／`SRVD/SRV`／`SRVB/SVB`／`DDLX/EX`）證實系統裡有大量標準內容（如 `C_SALESORDERMANAGE_SD`），代表這些物件型別在這個系統上是**真實運作中的框架**，不是空殼。

### 40.2 ⚠️ 這是「Classic RAP」——CDS 編譯器不支援 View Entity 語法

用新式語法 `define root view entity ZI_RAPT01 as select from zrapt01 { ... }` 啟用直接報 **`Syntax error: Keyword ENTITY not allowed`**。讀標準物件 `C_SalesOrderManage` 的 DDL 原始碼確認，這系統的 RAP 範例一律用**舊式 CDS View 語法**：`define root view C_SalesOrderManage as select from I_SalesOrder as SalesOrder composition [0..*] of ...`（用 `composition [0..*] of` 表達關聯，不是 View Entity 世代的 `association to`/ON 條件簡化語法）。

**Workaround／正確語法**：拿掉 `entity` 關鍵字，改用 `define root view <name> as select from <table> { key ..., ... }`；根 View 必須加 `@AbapCatalog.preserveKey: true`（缺了會報 `"@AbapCatalog.preserveKey: true" missing for entity in BO structure`，即使用的是舊式 `view` 而非 `view entity`，這個 annotation 一樣要）＋ `@ObjectModel.compositionRoot: true`。

### 40.3 ⚠️ BDEF 不支援 `strict` mode 語法

`strict ( 2 );` 啟用報 `Unexpected character "2"`；改成不帶參數的 `strict;` 也報 `"internal | with" expected, not "strict"`——**這個系統的 BDEF 語法完全沒有 `strict` 子句這個語言元素**（`strict` mode 是後期版本才加入、用來管控哪些檢查該報錯而非警告的語言特性）。Workaround：BDEF header 只留 `managed;`（或 `managed implementation in class ... unique;`），不要寫 `strict` 那一行。

### 40.4 ✅ 完整驗證成功的 Managed RAP 最小鏈路

依序建立、全部走 ADT（Table／CDS View 用 MCP `sap_set_source` 原生支援；BDEF 因下一條記載的工具 bug 改手動 curl）：

1. **Table** `ZRAPT01`（`key client : mandt not null; key root_id : abap.char(10) not null; descr : abap.char(40);`）
2. **CDS Root View** `ZI_RAPT01`（`@AbapCatalog.preserveKey: true` + `@ObjectModel.compositionRoot: true`，`define root view ... as select from zrapt01 { key root_id, descr }`，欄位不加 alias 以免需要額外的 `mapping for` 區塊）
3. **Managed BDEF** `ZI_RAPT01`：
   ```
   managed;

   define behavior for ZI_RAPT01 alias Root
   persistent table zrapt01
   lock master
   {
     create;
     update;
     delete;
   }
   ```
4. **Service Definition** `ZRAPT01_SD`：`define service ZRAPT01_SD { expose ZI_RAPT01 as Root; }`

四個物件全部 `sap_inactive_objects` 回 0 筆、GET `version=active` 內容比對相符，**證實這個環境完全可以建出一個能啟用的 Managed RAP BO**，不需要走「單一 Interface View + 獨立 Projection View」兩層（這系統的標準內容本身也是這種單層模式，Interface View 直接掛 BDEF，Consumption View 只是另一個直接 select 的 View，不是強制要有 `projection;` BDEF 的兩層架構）。

### 40.5 Service Binding：物件可建立，但「Publish」步驟找不到 ADT API

POST `/sap/bc/adt/businessservices/bindings`（root `srvb:serviceBinding`，內嵌 `srvb:services`／`srvb:content`／`srvb:serviceDefinition`／`srvb:binding type="ODATA" version="V4"`）建立成功，GET 讀回 `adtcore:version="active"`（Service Binding 建立後**直接是 active**，不像其他物件需要額外 activation 呼叫）——但 `srvb:published` 屬性固定是 `false`；嘗試：
- 對已建立物件重新 `LOCK`→PUT 帶 `srvb:published="true"` 的 XML → 回 200，但讀回來 `published` 還是 `false`（屬性被伺服器忽略，不是客戶端可寫的欄位）
- GET/POST `/sap/bc/adt/businessservices/odatav4/<name>` 這個子資源 → 一律 `404 No suitable resource found`
- discovery 全文搜尋 `publish` 關鍵字 → 完全沒有命中

**結論**：Service Binding 的「Publish」（讓它變成真正可以打 `/sap/opu/odata4/...` 測試的 OData 端點，SAP GUI／Eclipse 裡是編輯畫面上的一個按鈕）目前這個 ADT／MCP 環境**沒有對應的寫入 API**——跟本檔記載的其他「GUI-only 收尾」模式（第 15 節 SICF、第 19 節 Smartform、第 28 節權限物件）同一類：物件本身（Service Binding 這個 Repository 物件）可以透過 ADT 完整建立，但「讓它在執行期真正生效」這個動作要回 SAP GUI／Fiori 的 RAP Business Services 應用手動按 Publish。

### 40.6 MCP 工具版本已更新過，但 BDEF 的內部路徑有 bug

`sap_set_source`/`sap_lock`/`sap_unlock` 的 `objectType` enum 現在直接列出 `DDLS`／`SRVD`／`DDLX`／`BDEF`（比本檔第 1～39 節撰寫時的版本新，代表 MCP server 有更新過）。TABL／DDLS 用原生工具測試正常（含自動處理殘留鎖 workaround 的 403 → `sap_lock`→`sap_unlock`→手動 curl activation 標準流程，見第 5 節）。但 **`sap_set_source(objectType=BDEF, ...)` 內部組出的 LOCK 路徑是 `/sap/bc/adt/bopf/bdef/sources/<name>`，跟 discovery 記載的真正 collection `/sap/bc/adt/bo/behaviordefinitions` 不一致**，直接報 `HTTP 404 No suitable resource found`——這是工具本身的 bug（沿用了較舊或錯誤的 BOPF 路徑慣例），BDEF 一律要走手動 curl（LOCK 用 `Accept: application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result` 這個舊式 Accept，同第 8 節 DDIC 物件模式）。**沒有驗證過 SRVD／DDLX 用原生工具是否也有同樣的路徑 bug**（這次 SRVD 直接走了手動 curl，未實測原生工具）——之後若要用這幾個新 objectType，先各自測一次原生工具，失敗再套用本節的手動 curl workaround。

### 40.7 對「值不值得在這個系統開 RAP 課程」的結論

- **技術上可行**：Managed RAP 的核心鏈路（Table→CDS View→BDEF→Service Definition）能建、能啟用，框架是真的在跑，不是查不到路徑的空殼限制。
- **但教出來的是「Classic RAP」語法**（無 View Entity、無 strict mode），跟目前 SAP 官方教材／認證（多半基於 2021+ 或 BTP ABAP Environment，預設 View Entity＋strict(2)）有落差，学生之後转去新版系统会需要重新适应两处语法差异（`view entity`關鍵字、`strict`子句）——这点第一輪回覆已經提過，這次查證是**補強證據**，不是推翻。
- **實務練習的最後一哩路（Publish→實際用 Postman/瀏覽器打 OData 端點驗證 CRUD）需要使用者在 SAP GUI／Fiori 手動按 Publish**，跟 REST 課程（第 15 節）的處境一樣——Claude 能做完物件建立與語法驗證，最終的「服務真的能用」需要使用者那端配合一步。
- 若決定開課，內容應該包含：明確告知「這是 Classic RAP 語法，不是最新 View Entity 語法」的說明、`strict` 相關的新舊語法差異需要另外補充講義文字（因為學生查官方文件會看到 `strict(2)` 但這裡用不了）、以及每個練習最後的 Service Binding Publish 步驟要設計成「操作指引＋使用者截圖回報」的形式（比照 Smartform 課程模式）。

### 40.8 ⚠️ 已更正（2026-08-02）：OData 端點外網其實打得到，只是 `adt-rfc-bridge` 這條路徑本身不能拿來當通用 HTTP 轉發器

**原始判斷（下方保留供對照）是錯的**——當時援引第 15 節「SICF 服務外網打不到」的結論，但那個結論本身已經在同一天被推翻（見第 15 節更正）：使用者在確認自己身處外網的情況下，直接瀏覽器打正確的對外位址 `https://erpdemo01.itts.com.tw:44300/sap/opu/odata/sap/ZRAPT01_SB3/`，**正常回傳服務的 Atom Service Document**（列出 `Root` collection，`member-title` 正確顯示 `RAP Test Root Interface View`）。這代表 OData V2 端點**外網直接可達**，不需要內網或 VPN，也不需要下面記載的自我呼叫 workaround 才能測試——**真人使用者拿瀏覽器/Postman 測，直接打對外主機名稱＋Port 就可以了**。

**唯一還成立的部分**：`adt-rfc-bridge`（`127.0.0.1:8410`，Claude 這邊在用的內部橋接）對 `/sap/opu/odata4/...` 與 `/sap/opu/odata/...` 這兩種路徑依然回 `404 No application class found for URI: ...`——但這純粹是 **bridge 自己的限制**（只認得自己內部映射的 `/sap/bc/adt/*` 專用路徑），跟「外網連不連得到」完全無關，是兩個不同層次的問題：**Claude 沒辦法透過 bridge 主動呼叫任意 OData/HTTP 端點**（這條依然成立），但**使用者自己拿瀏覽器/Postman 測是完全沒問題的**（這條原本判斷錯了，已更正）。

**下方原始內容（`cl_http_client` 自我呼叫 workaround）保留參考價值**：這個做法本身沒有錯，仍然是「Claude 端不依賴使用者手動操作、自主驗證 OData 服務」的唯一手段（因為 Claude 沒有通用的外部 HTTP 呼叫工具能直接打 `erpdemo01.itts.com.tw:44300`）；只是它的必要性從「唯一能測的方法」降級成「Claude 想自己驗證時的選項之一」，**使用者手動測試已經不再需要它**，直接拿瀏覽器/Postman 打對外網址即可，比寫一支 ABAP 報表更直接。

---

**原始記載（2026-08-02 早先，判斷有誤，保留供對照）**：

`adt-rfc-bridge` 對 `/sap/opu/odata4/...` 與 `/sap/opu/odata/...` 這兩種路徑（OData V4／V2 標準端點）一律回 `404 No application class found for URI: ...`——**跟第 15 節記載的 SICF REST Service 完全同一個錯誤訊息、同一個成因**：OData 服務本質上也是掛在 SICF／ICM HTTP Port 底下的一個節點，跟自訂 REST Service 走的是同一條連線路徑，`adt-rfc-bridge` 只認得自己內部映射的 `/sap/bc/adt/*` 專用路徑，不是通用的 HTTP-to-RFC 轉發器。

這代表：~~即使之後真的解決了 Service Binding Publish 的問題（第 40.5 節），只要使用者當下是透過 SAProuter／dispatcher 連線（不在能連到 SAP Host 內網或 VPN 的環境），瀏覽器/Postman 直接打這個 OData 端點一樣連不到~~——**已證實不成立**，見上方更正。

**已驗證有效的 workaround（沿用 REST 課程 rs07 的做法）**：寫一支 ABAP 報表，用 `cl_http_client=>create_by_url`（或標準demo程式 `SPROX_HTTP_REQUEST`）在 **SAP 系統內部**呼叫這個 OData 服務自己的 URL。RAP 課程 rap04（Service Definition／Binding 與發布流程）出題時，這支自我呼叫的驗證報表**仍值得納入教材**（作為 Claude 端無頭驗證的手段，見上方更正後的定位），並且理論上可以直接用 `programrun` 無頭執行（報表本身只是呼叫 HTTP API 再 `WRITE` 回應內容，不牽涉畫面互動，符合第 37 節「無頭可驗證」的模式）。

### 40.9 ✅ 已解決：Service Binding 一定要用 Eclipse 官方精靈建立，用 ADT REST API 手動 POST 會缺少後端註冊步驟（2026-08-02 使用者實測確認）

- **現象**：`ZRAPT01_SB2`（用第 40.5 節記載的原始 ADT REST API `POST /sap/bc/adt/businessservices/bindings` 手動建立的 OData V2 Service Binding）不管是透過 ADT API 呼叫 `publishjobs`、還是透過 SAP GUI `/IWFND/MAINT_SERVICE` 的 `Add Selected Services`，都得到同一個具體錯誤：`SAP Backend Error Log`（`/IWBEP/ERROR_LOG`）裡的 Error Context 顯示 **`MSGID = SDDIC_ADT_SRVB`、`MSGNO = 011`**，訊息文字「Service Definition is not available」；`SICF` 底下 `/sap/opu/odata/sap` 完全沒有出現對應節點，代表失敗發生在 Gateway/IWBEP 解析 Metadata 這一步，連 ICF Node 都還沒建立。
- **根本原因（已驗證）**：Eclipse 官方的「New → Service Binding」精靈在建立 Service Binding 時，除了寫入 DDIC Repository 物件本身，背後還會觸發一個**只有精靈流程才會做的後端註冊/模型產生步驟**（把 Service Definition 的 Metadata 編譯登錄進 Gateway 執行期模型快取）。用原始 XML `POST` 手動建立的 Service Binding，即使 DDIC 物件本身完全 Active、Schema 正確，也**缺少這個背景註冊動作**，導致 Gateway 執行期永遠找不到對應的已編譯 Metadata，不管事後怎麼重試 Publish／`/IWFND/MAINT_SERVICE` 都無法補救。
- **✅ 解法（使用者實測成功）**：改在 **Eclipse ADT** 裡，對著已存在的 Service Definition（`ZRAPT01_SD`）右鍵 → `New` → `Other ABAP Repository Object` → 選 **Service Binding**，精靈跑完之後（本例命名 `ZRAPT01_SB3`，Binding Type = `OData V2 - UI`），直接在編輯器裡點 `Publish`——**一次成功**，`Local Service Endpoint` 狀態變成 `Published`，`Unpublish` 按鈕出現，且用編輯器內建的 `Preview...` 按鈕成功開出 Fiori Elements List Report 畫面（顯示 `No data found` 是預期行為，因為 `ZRAPT01` 這張表從頭到尾沒有寫入過任何測試資料，不是失敗）。
- **OData V2 技術服務名稱＝ Service Binding 物件名稱，不是 Service Definition 名稱**：Preview 畫面顯示的 `Service URL` 是 `/sap/opu/odata/sap/ZRAPT01_SB3`（對應 Binding 名稱 `ZRAPT01_SB3`），不是 `ZRAPT01_SD`——這點更正了 40.5／`/IWFND/MAINT_SERVICE` 畫面顯示 `Technical Service Name = ZRAPT01_SD` 一度造成的誤解（那個畫面看到的是尚未成功材料化前、Gateway 用 Service Definition 名稱當佔位顯示的搜尋結果，不是最終正式的技術服務名稱）。
- **結論／教學上的意義**：**RAP 課程 rap04 的 Service Binding 建立步驟，一律要教「Eclipse 精靈手動建立」，不能沿用其他物件類型（Table／CDS View／BDEF／Service Definition）用 ADT REST API workaround 建立的模式**——這是本檔記錄過的所有 GUI-only 案例裡，第一個「表面上物件建立成功（201/Active），但缺少一個完全看不出來、只有精靈才會觸發的隱藏後端步驟，導致下游功能整個失效」的案例，比單純「這個物件型別沒有 ADT API」更隱蔽，值得在教材裡特別強調：**Service Binding 這個物件，Claude 只能負責建立 Service Definition 之前的所有物件並驗證到位，Service Binding 本身務必請使用者在 Eclipse 手動建立＋Publish，不要嘗試用 API workaround 生成。**
- **✅ 補充（2026-08-02，rap04 使用者實際操作截圖比對確認）：實際觸發精靈的路徑比原記錄更直接，而且中間多一個「$TMP 不需要傳輸請求」的畫面**：對著 Service Definition 右鍵，選單裡**直接就有 `New Service Binding` 這個項目**，不需要繞經 `New` → `Other ABAP Repository Object` 精靈再篩選——這個系統的 ADT Plugin 版本已經把常用的 RAP 物件類型（Service Binding／Metadata Extension 等）內建成右鍵選單的直接捷徑。填完 Name／Package／Binding Type／Service Definition 按 **Next**（不是 Finish）之後，會先跳出一個「**Select Transport Request**」畫面——套件是 `$TMP` 時畫面會顯示提示文字「No change recording enabled for package $TMP」，代表不需要傳輸請求，**什麼都不選，直接按 Finish** 即可，不會卡住也不會出錯。這一步在正式套件（非 `$TMP`）底下應該會需要真的選一個傳輸請求，屬於本檔一貫的「正式套件物件寫入需要 `transport` 參數」規則（見第 21 節）在 Service Binding 這個 GUI-only 物件上的對應版本。

### 40.10 `@UI.*` Annotation（Fiori Elements）跟「Classic RAP vs ABAP Cloud RAP」是兩條獨立軸線——這個系統完全支援 `@UI.*`，只是 Metadata Extension（DDLX）語句本身一樣是舊式語法（2026-08-02 查證）

- **背景**：RAP 課程規劃時誤導使用者以為這個系統可能因為是「Classic RAP」而不支援 `@UI.*` Annotation（Fiori Elements 用的 UI 標記，如 `@UI.headerInfo`／`@UI.lineItem`）——這個推論是錯的，已用系統既有標準物件 `C_SETTLMTDOCOPG`（Metadata Extension）驗證推翻。
- **確認結果**：讀取 `GET /sap/bc/adt/ddic/ddlx/sources/c_settlmtdocopg/source/main` 看到完整、大量的 `@UI.headerInfo`／`@UI.facet`／`@UI.fieldGroup`／`@UI.lineItem`／`@UI.selectionField`／`@UI.dataPoint` 實際使用範例——證實 `@UI.*` 這套 Annotation 詞彙**完全不受 View Entity／`strict` 這條「新舊 RAP 語法」軸線影響**，`@UI.*` 其實比 RAP 本身還早出現（源自更早期的 CDS-based Fiori Elements），這個系統上完全可用。
- **但 Metadata Extension 語句本身也是舊式語法**：這份標準物件開頭是 `annotate view C_SettlmtDocOPg with { ... }`——用 `annotate view`，不是 View Entity 世代對應的 `annotate entity`。這是「第 40.2 節 CDS View 用 `define root view` 而非 `define root view entity`」同一種模式在 DDLX 物件上的對應版本，屬於同一條「Classic RAP／Classic CDS」語法軸線，跟 `@UI.*` Annotation 本身能不能用是兩回事——**Annotation 詞彙（`@UI.*` 有哪些欄位可以填）不受影響，但外層包裹這些 Annotation 的語句關鍵字（`annotate view` vs `annotate entity`）會受影響**，跟 CDS View／BDEF 的情況一致。
- **對課程規劃的影響**：本課程範圍不含 UI／Fiori Elements（見 README／rap01 聲明），所以這個發現目前不影響教材內容；但如果之後真的要開一門涵蓋 Metadata Extension／`@UI.*` 的延伸課程，DDLX 的建立要用 `annotate view`（不是 `annotate entity`），跟 rap02 教的 CDS View 語法版本一致，不會有額外的版本落差。

### 40.11 BDEF 的 `etag master <欄位>` 語法在這系統也不支援，正確寫法是 `etag <欄位>`（不帶 `master`）（2026-08-02 實測，rap03）

- **現象**：`ZI_RAP02_TASK` 的 Managed BDEF 寫 `etag master created_at`（官方教材／新式 ABAP Cloud RAP 常見的寫法），啟用直接報 `"authorization | draft | late | { | ~" expected, not "created_at".`——錯誤訊息裡列出的合法後續 token（`authorization`／`draft`／`late`／`{`／`~`）完全沒有 `etag` 這個字，代表這系統的 BDEF 文法根本不認得 `etag master` 這個組合關鍵字。
- **根本原因／查證方法**：回頭比對本節查證階段已經讀過的系統既有標準 BDEF 原始碼（第 40 節開頭列出的 `SCR_E_DBDEV`／`A_ProductionSupplyArea`），兩者都是寫 **`etag chgdAt`／`etag LastChangeDateTime`——單純 `etag <欄位>`，完全沒有 `master` 這個字**。這代表這系統的 Classic RAP／Classic CDS 世代，`etag` 子句本身就沒有「`master`／`dependent`」這種依附在 Composition 階層（區分根節點自己的 etag vs 子節點沿用父節點 etag）的語法分支，一律是最簡單的 `etag <欄位>` 形式，跟 `strict`／View Entity 屬於同一條「較舊、較精簡文法」的軸線。
- **修法**：BDEF header 拿掉 `master`，改成 `etag created_at`（放在 `persistent table` 之後、`lock master`之前或之後皆可，這次實測放在 `lock master` 前面正常啟用）。
- **教訓**：跟 `strict`／View Entity 這兩個已知差異一樣，**遇到 RAP 語法報「預期關鍵字」類型的錯誤時，直接讀錯誤訊息列出的合法後續 token 清單，比死記官方教材寫法更可靠**——這次的錯誤訊息其實已經直接暗示了「這系統的文法不認得 etag 這整個子句要跟 master 連用」，只是需要對照既有標準物件的寫法才能確認正確替代語法是什麼。之後任何 BDEF 新語法元素踩到類似錯誤，優先用這個方法（讀錯誤訊息的合法 token 清單＋比對系統既有標準物件），比憑印象改寫更快找到正確語法。

### 40.12 Service Definition（SRVD）建立空殼的正確 schema：`srvd:srvdSourceType="S"` 屬性，不是猜測的子元素；`sap_set_source(objectType=SRVD)` 沒有第 40.6 節記載的 BDEF 路徑 bug（2026-08-02 實測，rap04）

- **建立空殼**：discovery 找到 `/sap/bc/adt/ddic/srvd/sourceTypes` 這個輔助端點，GET 回傳唯一合法值 `S`（`Service Definition`）；POST `/sap/bc/adt/ddic/srvd/sources`（Content-Type `application/vnd.sap.adt.ddic.srvd.v1+xml`）第一次不帶這個資訊直接回 400「Source type '' does not exist」——**正確位置是 root 元素 `srvd:srvdSource` 上的屬性 `srvd:srvdSourceType="S"`**，不是猜測中的子元素或 body 內容，這個結論是照抄既有標準物件 `C_SALESORDERMANAGE_SD`（quickSearch `C_SALESORDERMANAGE*` 找到）的 GET 回應反查出來的，不是用猜的：
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <srvd:srvdSource srvd:srvdSourceType="S" xmlns:srvd="http://www.sap.com/adt/ddic/srvdsources" xmlns:adtcore="http://www.sap.com/adt/core"
    adtcore:name="ZRAP04_SD" adtcore:type="SRVD/SRV" adtcore:description="...">
    <adtcore:packageRef adtcore:name="$TMP"/>
  </srvd:srvdSource>
  ```
- **寫入內容**：空殼建好後，原生 MCP 工具 `sap_set_source(objectType=SRVD, ...)` 可以正常寫入 `define service ... { expose ... as ...; }` 內容——**第 40.6 節記載「沒有驗證過 SRVD／DDLX 是否也有跟 BDEF 一樣的路徑 bug」，這次確認 SRVD 沒有這個 bug**，跟 TABL／DDLS 一樣走原生工具就能用。自動啟用一樣會踩到殘留鎖 403（`User XXX is currently editing`），走第 5 節標準流程（`sap_lock`→`sap_unlock`→手動 curl activation）即可排除，不是 SRVD 特有的問題。
- **常見警告**：`@EndUserText.label` 這個 annotation 的值上限是 **40 字元**（`String(40)`），超過只會是 Warning（`type="W"`，不擋啟用），但建議還是控制在限制內，訊息比較乾淨。

## 41. ⚠️ 重要：SICF「Test Service」開出的網址是內網主機名稱／Port，Eclipse Service Binding「Preview」開出的才是外網可用的網址——兩者不能混用（2026-08-02 使用者實測發現）

- **現象**：同一套系統，兩個入口點自動產生的測試網址完全不同：
  - SICF 交易碼裡對某個自訂 Service 節點按右鍵 `Test Service`，瀏覽器自動開啟的網址是 `http://s4d1909fps01.itts.com.tw:50000/sap/bc/<service>?sap-client=130`——**主機名稱是系統的內部真實主機名稱（`s4d1909fps01`），Port 50000，純 HTTP**
  - Eclipse 裡對一個 Service Binding 按 `Publish` 之後點 `Preview...`，自動開啟的網址是 `https://erpdemo01.itts.com.tw:44300/sap/bc/adt/businessservices/odatav2/feap?feapParams=...`——**主機名稱是對外別名（`erpdemo01`），Port 44300，HTTPS**
  - 使用者身處外網時，`s4d1909fps01.itts.com.tw:50000` 這組網址**打不通**（甚至連 `sap/bc` 底下其他服務也一樣打不通，即使那個服務本身跟 Test Service 開出來的是同一個），但把主機名稱／Port 換成 `erpdemo01.itts.com.tw:44300` 之後，同一個 `/sap/bc/...` 路徑就**打得通**（實測 `zqm005`／`rs01`／`rs03` 皆確認可通，回應內容正確或至少是應用層級的回應如 `HTTP method GET not supported`，不是網路層級的連線失敗）
- **根本原因（Basis／網路架構層級，非 ADT／MCP 限制）**：這套系統的外網存取是透過 Reverse Proxy／SAP Web Dispatcher／防火牆 NAT 之類的邊界元件轉送進來的——**外部看到的主機名稱與 Port，跟系統內部 ICM 實際監聽的主機名稱與 Port 完全是兩件事，中間的對應關係是 Basis／網管設定的，不會自動同步**。`erpdemo01.itts.com.tw:44300` 是這套系統對外公開的統一入口（Eclipse ADT 遠端連線本來就需要這個入口才能運作），`s4d1909fps01.itts.com.tw:50000` 是系統自己回報的內部真實主機名稱／Port，只有內網／VPN 環境能連到；外部通常在邊界做 SSL Termination，所以外部一律走 HTTPS（如 `44300`），內部維持單純 HTTP（如 `50000`）。
- **⚠️ 這代表 SICF 的「Test Service」按鈕自動組出來的網址，在使用者身處外網時大機率不能直接拿來測試**——它只是老實地把系統自己認知的主機名稱／Port 拼進網址，不會幫你換成對外可用的別名。**Eclipse Service Binding 的「Preview」按鈕之所以能開出正確可用的外網網址，是因為 Eclipse 本身連線這套系統時，用的本來就是 `erpdemo01.itts.com.tw:44300` 這個位址（Eclipse 遠端開發的連線設定），所以它產生的所有網址自然而然沿用同一個對外主機名稱**——不是 Eclipse 這個工具本身比較聰明，純粹是連線來源不同。
- **實務做法**：任何 SICF 服務（不管是自訂 REST Service 還是 OData），只要拿到 SICF「Test Service」自動開出的網址發現連不到，**先嘗試把主機名稱／Port 換成已知可用的外網對外別名（這套系統是 `erpdemo01.itts.com.tw:44300`），保留原本網址裡 `/sap/bc/...` 或 `/sap/opu/odata/...` 那段路徑不變**，再重新測試——這幾乎每次都能解決「明明服務已經建好啟用、卻打不通」的困惑，不需要真的懷疑服務本身有問題。這套系統目前只確認了一個對外別名／Port（`erpdemo01.itts.com.tw:44300`），如果日後要開放其他對外 Port／別名，屬於 Basis／網路團隊的設定範圍，ADT／MCP 這邊完全看不到也管不到，需要的話要直接跟他們提出需求。

## 42. ⚠️⚠️ 已更正（2026-08-02，見第 43／44 節）：「EML 在 `programrun` 會卡住」的原始推測是錯的，真正原因是第 43 節的 Managed Runtime 白名單 Dump

**原始記錄（下方保留供對照）判斷有誤**——當時以為 EML 語句本身有某種 headless 環境相容性問題，跟 `cl_salv_table`／`VIEW_MAINTENANCE_CALL` 同一類。**第 44 節已用 Unmanaged BDEF 的 EML 測試程式（`ZR_RAP03_UMTEST`）在 `programrun` 底下完整成功執行**（沒有卡住、沒有逾時，CREATE／COMMIT ENTITIES／資料庫驗證全部正常回應），證實 **EML 本身完全可以無頭執行**，問題不在 EML 這個語言機制。

真正的原因是第 43 節記載的：**Managed Runtime 在這個系統上被 SAP 標記為「尚未對外釋出」，任何 Managed BDEF 的 CUD 操作執行到底層都會觸發 `MESSAGE ... TYPE 'X'`（Dump 等級）的訊息**——這類致命 Dump 透過 RFC Bridge 傳回時，很可能沒辦法乾淨地轉成一般 HTTP 錯誤回應，而是讓連線卡住、最終逾時／`RFC_CLOSED`。也就是說，`ZR_RAP03_DEMO`（呼又 Managed BDEF `ZI_RAP02_TASK` 的 EML）當初卡住，根本原因不是「EML 語法」，而是「呼叫到了必然會 Dump 的 Managed Runtime」。

**教學上的更正**：EML **可以**用 `programrun` 無頭驗證，前提是背後的 BDEF 是 Managed 且這個系統的 Managed Runtime 沒被鎖住（目前已知被鎖，見第 43 節），**或者 BDEF 是 Unmanaged**（第 44 節證實完全不受這個限制影響）。RAP 課程如果要靠 `programrun` 做無頭驗證，這個系統目前只有 **Unmanaged BDEF 這條路走得通**。

---

**原始記錄（2026-08-02 早先，判斷有誤，保留供對照）**：

- **現象**：為了無頭驗證 rap03 的 Managed BDEF（`ZI_RAP02_TASK`）CRUD 是否真的動得起來，寫了一支 `ZR_RAP03_DEMO` 用 EML（`MODIFY ENTITIES OF zi_rap02_task ENTITY Task CREATE ... COMMIT ENTITIES.`）呼叫 Managed BDEF 的 CREATE／UPDATE／DELETE，語法檢查與啟用都成功，但 `POST /sap/bc/adt/programs/programrun/zr_rap03_demo` 直接回 `502 ADT-RFC bridge error: 6 (rc=6): key=RFC_CLOSED`。**沒有重試**（記取第 38 節教訓：同一物件重試只會反覆打到已經卡死的殭屍 Session），改用第 38 節「建全新最小化物件隔離變因」的方法論，另建一支只含最精簡 EML CREATE 的 `ZR_RAP03_EMLTEST`，結果 `programrun` 直接**逾時（curl exit code 28，20 秒無回應）**，證實問題不是 `ZR_RAP03_DEMO` 這個物件本身卡住，~~是 EML 語句本身在 headless programrun 環境會卡住~~——**已證實不成立，見上方更正**。
- ~~推測原因：跟第 5／16 節記載的 VIEW_MAINTENANCE_CALL／cl_salv_table 同一類……~~——**已證實不成立，見上方更正**。
- **殘留物件**：`ZR_RAP03_DEMO`／`ZR_RAP03_EMLTEST` 這兩個 `$TMP` 物件呼叫 `programrun` 會卡住（因為背後是 Managed BDEF），不要再對它們呼叫 `programrun`；`ZR_RAP03_DEMO` 仍可當 rap03 講義的 Managed 語法範例程式（語法正確），只是實際執行驗證要換成 Unmanaged 版本，或請使用者在 SAP GUI 用 SE38（F8）跑（依然會 Dump，但那是預期中的、已經解釋清楚原因的 Dump）。

## 43. ⚠️⚠️ 重大發現：這個系統的 RAP **Managed Runtime**（寫入／CUD）被 SAP 官方標記為「尚未對外釋出」，任何 Managed BDEF 的 CUD 操作一律 Dump（2026-08-02 實測＋SAP Community 佐證，RAP 課程 rap03）

- **現象**：使用者在 SAP GUI 用 SE38（F8）執行 `ZR_RAP03_DEMO`（呼叫 Managed BDEF `ZI_RAP02_TASK` 的 EML CREATE），得到 Runtime Error：
  ```
  Category: ABAP programming error
  Runtime Errors: MESSAGE_TYPE_X_TEXT
  ABAP Program: CL_CSP_MD_METADATA_FACTORY====CP
  Application Component: BC-ESI-RAP-CSP
  ```
  原始碼摘錄（`LIF_ASSERTER~EXECUTION_ALLOWED` 方法）：
  ```abap
  SELECT obj_name FROM tadir
    WHERE pgmid = 'R3TR' AND object = 'DDLS' AND obj_name = @iv_entity_name AND (
      devclass LIKE 'SBOI_RAP_CSP_TST%' OR devclass IN
      ( '/BOBF/RAP_MIGRATION', '/BOBF/RAP_MIG_ADMINISTRATOR' ) )
    UNION ALL
  SELECT obj_name FROM tadir
    JOIN tdevc ON tdevc~devclass = tadir~devclass
    JOIN df14l ON df14l~fctr_id = tdevc~component AND df14l~as4local = 'A' AND ( df14l~... IN ( 'BC-SRV-NWD-XBR', 'BC-DWB-DIC' ) )
    WHERE tadir~pgmid = 'R3TR' AND tadir~object = 'DDLS' AND tadir~obj_name = @iv_entity_name
    INTO TABLE @DATA(lt_obj_name).

  " *** csp isn't released for public usage until now ***
  IF lt_obj_name IS INITIAL.
    MESSAGE 'Managed runtime is not released for productive usage (entity: ...)' TYPE 'X'.
  ENDIF.
  ```
  這段邏輯（連程式碼裡都留了開發者自己寫的英文註解「csp isn't released for public usage until now」）會檢查：這個 CDS Entity 所在的套件，是不是在一份**硬編碼白名單**裡（`SBOI_RAP_CSP_TST%` 套件前綴，或 `/BOBF/RAP_MIGRATION`／`/BOBF/RAP_MIG_ADMINISTRATOR`，或特定 Application Component `BC-SRV-NWD-XBR`／`BC-DWB-DIC`）——不在清單裡（例如 `$TMP` 或任何自訂客戶套件）就用 `MESSAGE ... TYPE 'X'`（致命訊息，直接 Dump）擋下來。
- **佐證**：用 `mcp__sap-docs__sap_community_search` 查到 SAP Community 一篇 **2019-11-18** 的貼文，一字不差回報同樣的錯誤訊息「Managed runtime is not released for productive usage」，情境也是「Fiori app with ABAP RESTful programming model, everything works except CUD operations」。這個時間點與這套系統的 Eclipse Project 顯示的 **`S4D_1909`**（S/4HANA 1909，2019 年 9 月發行）高度吻合——**這代表 Managed RAP 的通用「寫入」執行期，在 1909 這個版本的初期（甚至可能延續到目前這套系統的 Support Package 等級）仍處於 SAP 內部白名單管控階段，尚未對客戶自訂套件開放**。
- **範圍**：這個檢查只卡在**真正執行到寫入邏輯**的時候（CREATE/UPDATE/DELETE），**純讀取不受影響**——這解釋了為什麼第 40.9 節 Service Binding Publish 之後的 Fiori Elements Preview 能正常顯示「No data found」（那只是 SELECT，沒有觸發這段白名單檢查）。
- **教學上的影響**：這系統上**任何 Managed BDEF 的 CUD 操作都無法真正執行**（不管是透過 EML、OData、Fiori Elements Create 按鈕，走的都是同一套底層 Managed Runtime），只能停留在「語法正確、成功啟用」層級，沒辦法端對端驗證。RAP 課程如果要教「真的能寫入資料」的完整流程，這個系統目前只能靠 **Unmanaged**（見第 44 節，已證實不受這個限制影響）。
- **待確認**：需要使用者／Basis 查證這套系統目前的 `SAP_BASIS`／`S4CORE` Support Package 等級，並視需要向 SAP Support Portal 查詢對應的 OSS Note（搜尋關鍵字 `Managed runtime is not released for productive usage` 或 `CL_CSP_MD_METADATA_FACTORY`）——Claude 這邊沒有 S-user 帳號，查不到官方 Note 編號與解除限制所需的確切 SP／Note。

## 44. ✅ Unmanaged BDEF 完全不受第 43 節的白名單限制影響，已端對端驗證成功（含 `programrun` 無頭驗證）（2026-08-02 實測，RAP 課程 rap03）

- **背景**：第 43 節發現後，用最小化隔離物件驗證「Unmanaged 能不能繞過這個限制」的假說——依據是這系統既有標準物件 `C_SalesOrderManage`（第 40 節查證階段就已確認是 Unmanaged）本身是正常運作中的標準 Fiori 銷售訂單功能，如果 Unmanaged 也被同一個白名單擋住，這個標準功能不可能正常運作，這已經是很強的間接證據。
- **驗證物件**（`$TMP`，全新獨立測試，不影響 rap02/rap03 已發布的 Managed 教材物件）：
  - Table `ZRAP03_UMTEST`（`key client : mandt; key id : abap.char(10); descr : abap.char(40);`）
  - CDS Root View `ZI_RAP03_UMTEST`（跟 Managed 版本同樣的必要 annotation：`preserveKey`／`compositionRoot`）
  - BDEF：`implementation unmanaged in class zbp_i_rap03_um4 unique; define behavior for ZI_RAP03_UMTEST alias Test lock master { create; }`——**注意 Unmanaged BDEF 不寫 `persistent table` 子句**（跟 Managed 不同，因為資料庫存取完全由實作類別自己處理，不是框架生成）
  - 實作類別 `ZBP_I_RAP03_UM4`：Global 類別本體只是空殼＋`FOR BEHAVIOR OF <view>` 子句，真正的 Handler 邏輯寫在 **Local Types Include**（`/sap/bc/adt/oo/classes/<class>/includes/implementations`，跟第 7 節 Test Class Include 走同一套 PUT 路徑，只是換成 `implementations` 這個 include 名稱），內容仿照系統既有標準物件 `CL_SD_BEHV_SALESORDERMANAGE`（`C_SalesOrderManage` 的實作類別）的寫法：
    ```abap
    CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
      PRIVATE SECTION.
        METHODS lock FOR LOCK IMPORTING it_lock FOR LOCK test.
        METHODS create FOR MODIFY IMPORTING it_create FOR CREATE test.
        METHODS read FOR READ IMPORTING it_read FOR READ test RESULT et_result.
    ENDCLASS.
    CLASS lcl_handler IMPLEMENTATION.
      METHOD lock.
      ENDMETHOD.
      METHOD create.
        LOOP AT it_create INTO DATA(ls_create).
          INSERT zrap03_umtest FROM @( VALUE #( client = sy-mandt id = ls_create-id descr = ls_create-descr ) ).
        ENDLOOP.
      ENDMETHOD.
      METHOD read.
        LOOP AT it_read INTO DATA(ls_key).
          SELECT SINGLE id, descr FROM zrap03_umtest WHERE id = @ls_key-id INTO @DATA(ls_data).
          IF sy-subrc = 0.
            APPEND VALUE #( %key = ls_key-%key id = ls_data-id descr = ls_data-descr ) TO et_result.
          ENDIF.
        ENDLOOP.
      ENDMETHOD.
    ENDCLASS.
    ```
  - 啟用時出現一個**警告（非錯誤）**：`The operation "SAVER" for entity "..." is not implemented`——代表沒有實作額外的 Saver 相關 Hook（`check_before_save`／`finalize`／`save`／`cleanup`），但不影響本次最小化測試的啟用與執行，正式課程若要教完整生命週期才需要處理。
  - EML 測試程式 `ZR_RAP03_UMTEST`：`MODIFY ENTITIES OF zi_rap03_umtest ENTITY Test CREATE FIELDS ( id descr ) WITH VALUE #( ( %cid = 'C1' id = 'UM0001' descr = 'Unmanaged Test' ) ) FAILED ... REPORTED ... . COMMIT ENTITIES.`，接著用一般 `SELECT` 讀回資料庫驗證。
- **✅ 結果（`programrun` 無頭執行，非 SAP GUI）**：
  ```
  before EML
  after EML, failed is initial: X
  after commit entities
  DB check OK, descr = Unmanaged Test
  ```
  **完全成功，沒有卡住、沒有逾時、沒有 Dump**，資料真的寫進資料庫。
- **踩到的兩個小語法坑**（過程記錄，供之後參考）：
  1. Local Implementation Include 裡 `VALUE #( mandt = ... )` 寫錯——**表格的 Client 欄位如果自己取名叫 `client`（不是內建型別 `mandt` 這個字面欄位名），VALUE 建構子就要用 `client =`，不是 `mandt =`**，這只是單純的欄位名稱對應錯誤，不是 RAP 語法限制。
  2. READ 方法結果表的技術鍵欄位是 **`%key`**，不是 `%tky`（`%tky` 是另一種情境用的名稱，這系統報錯訊息裡直接建議了 `%key` 這個正確名稱）。
- **重大結論**：
  1. **第 42 節「EML 無法無頭驗證」的推測正式推翻**——EML 本身完全支援 `programrun` 無頭執行，先前的卡住是第 43 節的 Managed Runtime Dump 造成的，不是 EML 的問題。
  2. **這系統要教「完整可執行的 RAP CRUD」，目前只有 Unmanaged 這條路走得通**——Managed BDEF 依然可以教語法、可以啟用，但沒辦法讓學生看到真正的端對端執行結果（第 43 節的白名單會擋住）。
  3. **Unmanaged 實作類別的 Local Implementation Include 可以透過 ADT 手動 curl 建立與寫入**（跟第 7 節 Test Class Include 同一套機制，只是 include 名稱換成 `implementations`），不需要依賴 Eclipse 精靈才能建立——這點跟 Service Binding（第 40.9 節，精靈是必要條件）不同，Unmanaged 實作類別是可以完全交給 Claude 自動化建立的。

## 45. ⚠️ 自我呼叫（`cl_http_client=>create_by_destination('NONE')`）透過 `programrun` 讀取「真實 RAP/OData 資料」會卡死斷線，跟哪個服務無關——`$metadata` 不受影響，但真正的 Entity GET 一律觸發跟第 38 節同樣的 `RFC_CLOSED`（2026-08-02 實測，RAP 課程 rap04）

- **背景**：rap04 發布 `ZRAP04_SB` 後，用第 40.8 節記錄過的自我呼叫技巧（`ZR_RAP04_SELFTEST`）想無頭驗證 OData CRUD，第一次執行就 `502 RFC_CLOSED`。
- **隔離排查（比照第 38 節「建全新最小化物件排除變因」的方法論）**：
  1. 縮到只剩一行 `GET TaskManaged?$top=1` 的探測程式（`ZR_RAP04_PROBE2`）——一樣卡住 `RFC_CLOSED`。
  2. **改打查證階段已經確認能正常運作、Eclipse Preview 也顯示過資料的既有服務 `ZRAPT01_SB3`**（`GET Root?$top=1`）——**一樣卡住**。這排除了「`ZRAP04_SB` 這個服務本身有問題」的可能性，證實是**自我呼叫讀取真實 RAP Entity 資料**這件事本身在這套系統上會卡死，不分服務、不分 Managed/Unmanaged。
  3. 對照組：同一個 session 稍早用一模一樣的自我呼叫手法打 `ZRAPT01_SB3` 的 **`$metadata`**（純中繼資料，不觸發 CDS/RAP 執行期），是 200 OK 秒回、完全正常（見第 40 節查證階段）。
- **推測機制**：`programrun` 本身是透過 RFC 呼叫進 ABAP，佔用這套小型系統本來就有限的 Dialog Work Process；`cl_http_client` 的自我呼叫是**對同一個 Instance 再發一個新的 HTTP 請求**，這個新請求要能被處理，一樣需要一個空出來的 Dialog Work Process——如果系統可用的 Dialog Work Process 數量很少（這種訓練/開發用的小型系統很常見），觸發真正需要跑 RAP/CDS 執行期邏輯的資料 GET，會需要**在原本那個呼叫尚未釋放的情況下**再拿到一個新的 Work Process，形成自我等待的僵局（deadlock），最終被 RFC Bridge 的逾時機制切斷連線回報 `RFC_CLOSED`。`$metadata` 之所以不受影響，合理推測是 Gateway 把 EDMX 中繼資料快取住、用更輕量的方式回應，不需要走到這一層資源競爭。
- **嘗試過的替代方案／已排除**：
  - 加大 `cl_http_client->send( timeout = ... )` 沒有意義——如果真的是 Work Process 僵局，拉長 Client 端逾時只會讓卡住的時間更久，最終還是被 RFC Bridge 自己的逾時切斷，不會讓自我呼叫真的完成。
  - 改用 `WebFetch`（Claude 端直接打外網網址 `https://erpdemo01.itts.com.tw:44300/...`）想繞過自我呼叫，改成完全獨立的外部連線路徑——結果 `WebFetch` 直接回 `unable to verify the first certificate`（外部工具不信任這套系統的憑證鏈），且就算憑證問題解決，OData 呼叫通常還需要登入帳密，`WebFetch` 也沒有管道處理認證，這條路目前對 Claude 端不可行。
- **結論／教學上的影響**：**這系統上，Claude 沒有任何可靠的無頭管道能驗證「已發布 Service Binding 的真實資料讀寫」**——第 40.8 節記錄的自我呼叫技巧，適用範圍要更正縮小為「只能驗證 `$metadata` 這類輕量、不觸發完整執行期的請求」，不能拿來驗證實際 Entity 資料的 CRUD。真正的資料驗證只能靠：① 使用者在 Eclipse 用 **Preview** 直接操作看結果（本課程既有做法）；② 使用者自己用瀏覽器/Postman 打外網網址（第 41 節），Claude 都無法越俎代庖。**跟第 38 節的教訓合起來看：這套系統只要牽涉「從系統內部反過來呼叫自己」的模式（不管是自我呼叫 HTTP、還是某支程式卡過一次 Dump 之後的殭屍 Session），都要優先懷疑是系統資源／Work Process 層級的限制，不是程式碼邏輯錯誤，不要浪費時間重試或改寫程式碼去排查。**
- **後續処理**：`ZR_RAP04_SELFTEST`／`ZR_RAP04_PROBE`／`ZR_RAP04_PROBE2` 三支程式都保留在 `$TMP`（語法正確、有教學/記錄價值），但講義要更正：不要再嘗試用 `programrun` 執行 `ZR_RAP04_SELFTEST` 的完整版本（GET 真實資料那幾段一律會卡住），改成請使用者直接在 Eclipse Preview 操作驗證。

**✅ 更正（2026-08-02，同日稍晚）：在 SE38（真人 GUI Session，F8 執行）跑同一支 `ZR_RAP04_SELFTEST`，讀取（GET）完全成功、沒有卡住**——證實上面「Work Process 僵局」的推測方向正確，卡住的關鍵變因是 **`programrun`／RFC Bridge 這條執行管道本身**，不是「自我呼叫」這個技巧不可行。`programrun` 透過 RFC 呼叫佔用的 Dialog Work Process，跟使用者自己在 GUI 登入 Session 裡執行報表佔用的 Work Process，是兩種不同的資源池／連線路徑，後者不會卡在同一個僵局裡。**更正後的結論**：自我呼叫讀取真實資料，在 **SE38 手動執行**是可行的；只有透過 **`programrun`** 執行才會卡死。之後如果需要驗證「自我呼叫技巧能不能動」，優先请使用者在 SE38 跑一次，不要只靠 `programrun` 就判定整條路不通。

**⚠️⚠️ 但緊接著在 SE38 遇到第二層、獨立的問題：CSRF Token 驗證失敗**——GET 部分完全正常（`TaskManaged`／`TestUnmanaged` 都讀到真實資料），`X-CSRF-Token: Fetch` 也順利換到看起來合法的 Token，但接下來的 `POST`（Create）一律回 `403 Forbidden` / `CSRF token validation failed`。已嘗試**明確擷取 Token 換發回應裡的 `Set-Cookie`，手動組成 `Cookie` Header 附加在 `POST` 請求上**（不依賴 `cl_http_client` 內建的隱式 Cookie Jar），結果仍然一樣失敗——代表問題不是「Cookie 沒有帶到」這麼單純。合理推測（未完全查證根因）：這系統可能是多台 Application Server 的架構，Gateway 的 CSRF Token 快取／驗證可能綁定在**核發 Token 當下那台 App Server**，而自我呼叫的 GET（換 Token）與 POST（送出 Token）兩次獨立的 HTTP 請求，即使 Session Cookie 一致，也可能被 Message Server／負載平衡分派到不同的 App Server 節點處理，導致後者驗證不到前者核發的 Token（這是 SAP Gateway 多節點环境常見的已知痛點，通常要靠 Server Affinity／Sticky Session 機制解決，`cl_http_client` 對 `destination='NONE'` 這種自我呼叫的連線，不保證有這種親和性）。
- **結論／教學上的影響**：**自我呼叫技巧在這系統上，「讀取」（GET）可靠（前提是用 SE38 而非 `programrun`），但「寫入」（POST/PUT/DELETE，涉及 CSRF）目前找不到可靠的 workaround**，且這是比第 45 節前段記載的「Work Process 僵局」更難排查、可能牽涉系統底層架構（多節點 Session 親和性）的問題，投入產出比低，**不建議繼續深挖**。任何課程如果需要驗證「真的能透過 OData 寫入資料」，最終手段一律是**使用者透過 Eclipse Fiori Elements Preview 或瀏覽器/Postman 手動操作**（這些走的是正常瀏覽器 Session，天生具備 Server 親和性，不會遇到這個自我呼叫特有的限制）。

## 46. Fiori Elements（OData V2）Preview 端對端排錯全紀錄：`@UI.facet` 語法放錯位置、內建型別無 Data Element 導致標籤空白、List Report 不按 Go 會誤判成無資料（2026-08-02 實測，RAP 課程 rap04 收尾，`ZI_RAP03_UMTEST`）

rap03 建立 `ZI_RAP03_UMTEST` 時完全沒有做 UI Annotation（當時重點是驗證 Unmanaged BDEF 能不能跑，不是畫面），到了 rap04 用 Eclipse Fiori Elements Preview 實際點 `TestUnmanaged` 的 `Create` 才第一次暴露出畫面層的問題，依序踩過三層坑：

1. **⚠️ 完全沒有 Metadata Extension（DDLX）時，List Report 能顯示、但 Create 按下去整頁空白**：`GET /sap/bc/adt/repository/informationsystem/search?...ZI_RAP03_UMTEST*` 查證確認當時只有 `DDLS/DF`＋`BDEF/BDO`，沒有 `DDLX/EX`。Fiori Elements 沒有任何 `@UI.*` 標記可用時，List Report 至少能用欄位技術名稱當標題硬顯示出來，但 Object Page（Create／Detail）完全不知道要排版什麼，直接空白，也沒有任何錯誤訊息——**這跟第 43 節的 Managed Runtime Dump 是完全不同的兩種「空白/失敗」，前者是白名單擋下來的 Dump 畫面，這裡是純粹「沒有 UI 中繼資料可畫」的靜默空白，畫面上看起來很像，但成因、修法都不同，遇到空白畫面不要直接套用第 43 節的結論**。
2. **✅ 建了 DDLX＋`@UI.identification` 之後，List Report 有欄位標題了，Object Page 還是空白**：這系統版本（S/4HANA 1909）的 Fiori Elements OData V2 範本，`@UI.identification` 單獨存在**不會**自動生成 Object Page 的欄位區塊（比較新版本的 UI5 才有這種自動生成的便利功能），必須額外明確加 `@UI.facet`（`type: #IDENTIFICATION_REFERENCE`）才會把標了 `@UI.identification` 的欄位實際排到畫面上。
3. **⚠️⚠️ `@UI.facet` 的正確語法位置，跟直覺猜測的不一樣，猜錯兩次才找到**：
   - 猜測 1（錯）：放進 `@UI: { headerInfo: {...}, facet: [...] }` 這種組合物件裡——啟用報 `Annotation 'UI.facet.id' used at wrong position (wrong scope)`。
   - 猜測 2（錯）：拆成獨立的 `@UI.facet: [...]` 一行，但放在 `annotate view X with` **之前**（跟 `@UI.headerInfo` 同一層）——一樣報 `wrong scope`。
   - **✅ 正確**：`@UI.facet: [...]` 要放在 `annotate view X with { ... }` 區塊**裡面**，當作第一個「浮動」的區塊層級標記（不綁在任何特定欄位上，寫在第一個欄位宣告之前）：
     ```abap
     annotate view ZI_RAP03_UMTEST with
     {
       @UI.facet: [
         { id: 'GeneralInformation', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General Information', position: 10 }
       ]

       @UI.identification: [{ position: 10 }]
       id;
       ...
     }
     ```
     這跟 `@UI.headerInfo`（維持在 `annotate view` **外面**）的放置規則剛好相反，兩個標記位置不能類推，遇到「wrong scope」錯誤，優先懷疑是不是放錯了內/外層，不要照抄另一個標記的位置。
4. **✅ Object Page 欄位區塊出現後，欄位還是沒有標題文字**：根因是底層表格欄位用內建型別（`abap.char`）沒有掛 Data Element——這正是專案 `abap-style.md` 記載的硬性規則背後的實務後果（不只 SM30 欄位標題會變 `+`，Fiori Elements 的篩選欄位／表格欄位／Object Page 欄位標籤全部都會是空的）。**修法**：不需要另外建 Domain／Data Element，直接在 CDS View 的欄位上加 `@EndUserText.label: '...'` 即可（CDS 層級的欄位標籤標記，跟 Data Element 的效果等價，Fiori Elements 兩者都認）：
   ```abap
   @EndUserText.label: 'ID'
   key id,

   @EndUserText.label: 'Description'
   descr
   ```
5. **⚠️ 修完標籤後，實際 Save 存檔會讓畫面變空白，容易誤判成又失敗了**：對 `TestUnmanaged` 按 `Create`、填欄位、按 `Save`，畫面立刻變空白（跟前面幾層的「空白」外觀類似，但這次背景其實已經存檔成功）——**這是這個舊版 Fiori Elements（S/4HANA 1909）Save 後導轉頁面的顯示小毛病，不是功能性失敗**。判斷方法：回到 List Report 按 `Go` 重新查詢，資料真的有進去就代表存檔成功，畫面空白純粹是導轉/渲染的 Cosmetic 問題，不用當作錯誤繼續排查。
6. **⚠️ List Report 預設不會主動查詢，容易誤判成「沒有資料」**：這個 OData V2 List Report 範本的初始狀態固定顯示「To start, set the relevant filters.」，必須明確按 `Go`（或 Enter）才會真正送出查詢——過程中好幾次看到「Tests (0)」都只是因為還沒按 `Go`，不是資料庫真的沒資料，任何「Fiori Elements 畫面顯示零筆」的回報，第一件事都要先確認有沒有按過 `Go`，不要直接當作資料庫層級的問題來排查。

**總結／方法論**：這五層坑外觀高度相似（畫面空白／零筆／沒有欄位），但成因完全不同（Dump／缺 Metadata Extension／缺 Facet／缺 Data Element 標籤／導轉 Cosmetic 問題／忘記按 Go），**每一層都要靠實際截圖＋逐步排除，不能看到「畫面空白」就套用先前某一次的結論**，這也是這次排錯反覆來回好幾輪才收斂的主因。

## 47. ⚠️⚠️ Eclipse ADT 的「New Table Index」精靈在這系統上對長表名（>10 碼，幾乎涵蓋所有 `ZRAPnn_` 命名的表）根本無法使用；改用 SE11 才是可靠路徑（2026-08-02 使用者實測，RAP 課程 rap02 補課）

- **對著 Table（或套件）按右鍵，選單裡直接有 `New Database Table`／`New Data Definition`／`New Table Index`／`New Extension Index`／`New Customer Data Browser Object`／`New Append Structure` 這些項目**，不需要繞經 `Other ABAP Repository Object` 精靈再篩選——這是這個 ADT Plugin 版本的一貫模式（第 40.9 節記過 Service Binding 也是同樣道理），常用的 DDIC／CDS 物件類型都被內建成右鍵選單的直接捷徑，之後任何課程要教「怎麼在 Eclipse 建立某個物件」，優先假設「對著相關物件或套件按右鍵可能就有直接捷徑」，不用預設一定要走 `Other ABAP Repository Object` 這條路。
- **⚠️⚠️ `New Table Index` 精靈的 `Name` 欄位是一個組合了兩種語意、互相矛盾的欄位，導致長表名根本填不進去**：
  1. 這個欄位長度上限只有 **10 個字元**，比一般 Z 物件（Table／CDS View／Class 等通常可以到 30 碼）短很多——實測 `ZRAP02_TASK_I1`（14 碼）直接被 ADT 擋下，錯誤訊息 `14 characters exceed the maximum of 10 characters in field 'Name'`。
  2. **這個欄位的預設值就是你右鍵點的那張表本身的名稱**（對著 `ZRAP02_TASK1` 右鍵，`Name` 預設帶出 `ZRAP02_TASK1`）——證實這個欄位背後其實是被當成「要建索引的目標表名」在用，不是「新索引物件自己的名字」。
  3. 矛盾點：這系統的表名慣例（`ZRAPnn_<實體>`）幾乎必然超過 10 碼（連 `ZRAP02_TASK` 都已經 11 碼），代表**這個欄位的預設值本身就會先觸發 10 碼上限錯誤，你唯一能做的只有硬改成一個更短、但不是真表名的字串**（例如 `ZRAP02IX1`）。
  4. **後果**：硬填一個假名稱過關後，精靈會切到一個內嵌的傳統 `Dictionary: Change Index` 畫面（透過「Start workbench application」內嵌 SAP GUI 顯示），畫面上的 `Table Name`／`Index Name` 兩個欄位會顯示你剛才填的假名稱，且**完全鎖死無法編輯**（連只改 Description 都不受影響、但 Table Name／Index 代號的部分是灰的）；接著點 `Table Fields` 選欄位時，系統會報 `Table <假名稱> is not active in ABAP Dictionary`——因為那根本不是一張真實存在的表。**這條路徑在這系統上對於 11 碼以上的表名是死路，沒有已知的 workaround 能在 ADT 精靈內部修正。**
- **✅ 確認可行的替代方案：直接用 SAP GUI 的 `SE11` 交易碼建，完全繞過 ADT 精靈**（已實測成功，`ZRAP02_TASK1~001`，`Status: Active／Saved`）：
  1. `SE11` → **Database table** 輸入完整表名（可以超過 10 碼，SE11 沒有這個限制）→ **Display**。
  2. 選單 **Goto → Indexes**（或畫面上的 **Indexes** 按鈕）。
  3. **Create** → **Index ID** 填 3 碼英數字（自訂的 Z 表，Index ID 不能用 `Y`／`Z`／`J`／`H` 開頭，用數字最安全，例如 `001`）。
  4. 填 Short Description，勾選要索引的欄位。
  5. 存檔 → Activate。
- **教訓**：這是本檔記錄過的又一個「Eclipse ADT 精靈表面上支援某個物件類型，但欄位設計本身有 bug／限制，導致特定情境（本例是長表名）完全走不通」的案例，跟第 34 節「Table Type 用錯 Content-Type 會靜默丟資料」、第 45 節「自我呼叫 CSRF 驗證失敗」同一類——**遇到 ADT 精靈卡住或行為詭異時，不要無止盡在精靈內部試錯，適時改用對應的傳統 SAP GUI 交易碼（本例 `SE11`）往往是更快、更可靠的路**，尤其是這類已經存在數十年、功能成熟穩定的經典 DDIC 維護畫面。

## 48. ⚠️⚠️ CDS View 的「DDL View Name」跟「SQL View Name」該用哪個，要看工具是不是比 CDS 更早存在——一開始整理成「一律用 DDL Name」是錯的，已被使用者實測推翻（2026-08-02，RAP 課程 rap02 補課）

- **背景**：CDS View（`define view`，V1 舊式語法）有兩個名字——`define view <名稱>` 的 **DDL View Name**（邏輯名稱，最長 30 碼，寫 ABAP 程式／Eclipse ADT／quickSearch 都用這個）跟 `@AbapCatalog.sqlViewName` annotation 指定的 **SQL View Name**（資料庫底層實體物件名稱，最長 16 碼，官方文件稱為「purely technical helper construct」）。
- **原始（錯誤）結論**：查證官方文件（`ABENABAP_SQL_CDS_OBSOLETE`／`ABENCDS_ACCESS_OBSOLETE`）確認 Open SQL 一定要用 DDL Name（直接用 SQL View Name 在 Open SQL 裡是 Obsolete、ABAP 7.62 Strict Mode 甚至禁止），因此一開始**類推**「SE11 應該也是用 DDL Name」——這個類推沒有實際驗證，只是邏輯推論。
- **✅ 已被使用者實測推翻**：
  - SE11 對著 `ZI_RAP02_TASK` 這個 CDS View 做 Display，查詢欄位本身就明確標示 **`DDL SQL View`**，實際要輸入的是 **SQL View Name**（`ZIRAP02TASK`）才查得到；查到之後的畫面上另外有個 **`DDL Source`** 欄位（顯示 `ZI_RAP02_TASK`）回頭告訴你這個底層 SQL View 對應哪個 CDS DDL 定義。
  - SQ02（InfoSet／SAP Query）的「Table join using basis table」欄位輸入 DDL Name（`ZI_RAP02_TASK`）直接報 `Table ZI_RAP02_TASK is not in ABAP Dictionary`——同樣只認 SQL View Name。
- **真正的規則**：**這個工具是不是「比 CDS 更早就存在的傳統交易碼」**——SE11 的 View 瀏覽畫面、SQ02 InfoSet 這類工具的機制是直接對應資料庫底層的物理物件，CDS View 只是後來「掛」進這套舊機制，查詢入口天生認的是實體名稱（SQL View Name）；Open SQL、Eclipse ADT、quickSearch、Where-Used 這類 CDS 之後才有（或跟 CDS 一起演進）的現代化管道，才是用 DDL View Name。**Table 物件沒有這個問題**（技術名稱只有一個，沒有雙名字設計），只有 View（含 CDS-based View）才有這個分裂，容易誤判成「DDIC 物件查詢都用同一種名字」。
- **教訓**：**類推出來的結論（沒有實際操作驗證過的）要明確標記成「推論」而不是「確認」，遇到新工具／新畫面優先假設「可能跟預期不一樣」，等使用者實際操作回報後才真正寫進「已確認」的結論**——這次的錯誤本身沒有造成操作損失（只是文件講錯），但如果換成教別的、有副作用的操作步驟，這種「邏輯類推當結論」的習慣可能會更早導致誤導使用者做錯事。
- **通用化**：SQ02／SQ01 InfoSet 只認 SQL View Name 這條規則**不是 `ZI_RAP02_TASK` 這個特定 View 的個案，適用任何掛在 `define view`（V1）物件上的 CDS View**——包含 AMDP 課程（第 16 節）教過的「Code to Data」設計（邏輯下推到資料庫執行的 CDS View／CDS Table Function），只要最終物件型別是 V1 `define view`，InfoSet 要串接就一律要用 `@AbapCatalog.sqlViewName` 那個 SQL View Name，不能填 CDS DDL 邏輯名稱。
- **⚠️ 附帶確認：這系統的 ADT SQL Console 沒有內建 Explain Plan／執行計畫分析功能**——依序找過工具列 `Run` 按鈕旁的下拉箭頭、最上方選單列的 `Run`、查詢文字上按右鍵，都只有 `Check`／`Run`（F8，真的會執行）兩個選項，`Run As` 子選單展開後是 `(none applicable)`。開啟 SQL Console 的正確路徑也一併確認：要對著 **Project 最上層節點**（不是 `$TMP` 套件、不是帳號節點）按右鍵才有這個選項。判斷這系統這個版本的 SQL Console 是比較輕量的實作，Explain Plan 這類分析功能通常要靠獨立的 **SAP HANA Database Explorer**（另一個工具／Perspective），這系統沒有配置，之後遇到「要看查詢執行計畫」的需求，不要再嘗試從 ADT SQL Console 裡找，直接跟使用者說明這系統做不到。

## 49. ⚠️⚠️ 已更正：`SE80`（Object Navigator）能完整唯讀顯示 RAP 現代物件（DDLX／BDEF／SRVD／SRVB）的原始碼，不是只有基本資訊——原本的猜測太保守，已被使用者實測推翻（2026-08-03，RAP 課程 rap02 補課）

- **背景**：`SE11` 已確認查不到 Metadata Extension（DDLX）——因為它不是 DDIC／資料庫層物件，`SE11` 天生就不認得這種型別（見第 48 節記載的「Table 有 SQL/DDL 雙名字、DDLX 連資料庫物件都沒有」的脈絡）。原本推測 `SE80` 大概也差不多，最多只能查到「物件存在、屬於哪個套件」這種基本資訊，看不到 `@UI.*` 實際內容——**這個推測沒有實測驗證，只是邏輯類推，已被使用者實測推翻**。
- **✅ 已被使用者實測推翻**：`SE80` 的 Repository Browser，展開套件（`$TMP`）之後，樹狀結構裡有**專屬的 `Metadata Extensions` 節點**，跟 `Behavior Definitions`／`Service Bindings`／`Service Definitions` 平行並列；點開 `ZI_RAP02_TASK`（Metadata Extension）會開啟「Display Metadata Extension」畫面，**`Source Code` 頁籤直接完整顯示 DDLX 的原始碼**（`@UI: { headerInfo: {...} }`、`annotate view ... with { ... }` 整段都看得到），唯讀（Display 模式）但內容完整不打折扣。畫面上還有一個 **`ADT Link`** 欄位（例如 `adt://S4H/sap/bc/adt/ddic/ddlx/sources/zi_rap02_task`），可以從 SE80 一鍵連結到 Eclipse ADT 開啟同一個物件編輯。
- **推測可以擴大到整個 RAP 五層架構**：使用者這次的截圖同時看到 `Behavior Definitions`（`ZI_RAP02_TASK`／`ZI_RAP03_UMTEST`／`ZI_RAPT01`）、`Service Bindings`（`ZRAP04_SB`／`ZRAPT01_SB`……）、`Service Definitions`（`ZRAP04_SD`／`ZRAPT01_SD`）都列在同一棵樹裡，代表 `SE80` 對整個 RAP 現代物件家族（DDLX／BDEF／SRVD／SRVB）都有專屬分類節點，合理推測都能用同樣方式唯讀瀏覽——但這個更大範圍的推測本身**還沒有針對 BDEF／SRVD／SRVB 逐一實測過內容顯示是否也一樣完整**，只是根據 DDLX 這一個案例＋畫面上看到的樹狀分類做的合理外推，之後有需要時應該找機會針對其他型別個別驗證，不要直接當「已確認」使用。
- **結論／教學上的意義**：**`SE80` 是比 `SE11` 更好用的唯讀瀏覽工具，適合「想快速看一眼某個 RAP 物件內容、又不想開 Eclipse」的情境**（`SE11` 只認 DDIC／資料庫層物件，`SE80` 對 Repository 物件的涵蓋範圍廣得多，包含現代 RAP 物件）；但真正要**編輯**內容，還是只能用 Eclipse ADT，`SE80` 這裡看到的都是唯讀顯示。
- **教訓**（呼應第 48 節同一個模式）：**「這個工具大概也查不到／查得到但只有基本資訊」這種沒有實測過的猜測，一律要明確標記成推論，不要當結論寫**——這次猜錯的方向是「低估了 SE80 的能力」，跟第 48 節「高估了 SE11 認得 DDL Name」是同一類錯誤（對沒操作過的畫面做主觀假設），只是方向相反，再次印證「遇到新工具／新畫面，直接問使用者實測比自己瞎猜準」。

## 50. Eclipse ADT 建立 Metadata Extension 的「Templates」畫面，一樣有「新式 entity 語法 vs 舊式 view 語法」的選錯陷阱，跟建 CDS View 是同一個模式（2026-08-03 使用者實測，RAP 課程 rap02 補課）

- **背景**：對著 CDS View 右鍵有 `New Metadata Extension` 直接捷徑（跟這系統一貫的「常用物件類型內建右鍵捷徑」模式一致），填完 Name／Package／Extended Entity 後會跳出「Templates」畫面。
- **⚠️⚠️ 畫面預設可能停在 `Annotate Entity (creation)` 分類**（底下有 `annotateEntity`／`annotateEntityWithParameters` 兩個模板），這個分類產生的骨架是**新式語法**：
  ```abap
  @Metadata.layer: ${layer}
  annotate entity ${entity_name}
    with
  {
    ${element_name};
    ${cursor}
  }
  ```
  關鍵字是 `annotate entity`（帶 `entity`）——**這系統不支援，會啟用失敗，跟第 40.2 節「CDS 編譯器不支援 `define view entity`」是完全同一個限制在 Metadata Extension 這個物件類型上的對應版本**。使用者實測踩到：選了這個分類，最後產生的原始碼確實是 `annotate entity ZI_RAP02_TASKS`。
- **✅ 正確做法**：Templates 畫面裡還有一個收合的 `Annotate View (creation)` 分類，要展開選那裡面的模板，才會產生不帶 `entity` 的 `annotate view` 骨架，跟這系統既有的 CDS View（`define view`，非 `define view entity`）搭配一致。
- **骨架本身還有兩個預設值不能直接用，一定要手動補**：
  1. `@Metadata.layer: layer`——`layer` 是純文字佔位符，不是合法列舉值，一定要手動改成 `#CORE`／`#LOCALIZATION`／`#INDUSTRY`／`#PARTNER`／`#CUSTOMER` 其中之一（查證官方語法文件 `ANNOTATE ENTITY` 取得的完整清單；客戶／企業自建物件一律用 `#CUSTOMER`）。
  2. **骨架預設完全沒有 `@UI: { }` 這個 Entity 層級 Annotation 區塊**——如果要設定 `headerInfo` 這類不屬於單一欄位的 Entity 層級標記，精靈不會幫忙產生，要自己在 `@Metadata.layer` 那一行後面手動加上整段 `@UI: {...}`。
- **教訓**：**這系統只要是「Eclipse 精靈跳出多種語法版本模板可選」的情境（CDS View 的 Data Definition 精靈、這裡的 Metadata Extension 精靈），預設/排在前面的選項很可能是這系統不支援的新式語法，一律要留意有沒有「obsolete」或收合分類裡藏著舊式版本，不能照預設一路按到底**——這是繼第 40 節 CDS View 精靈之後，第二個確認到同樣選錯陷阱的物件類型，之後遇到 BDEF／SRVD 之類的 Eclipse 建立精靈如果也有多重模板選擇畫面，應該優先假設可能有同樣的陷阱，主動提醒使用者仔細看清楚每個模板的預覽內容再選。

## 51. RAP Determination 在這系統要用 obsolete `FOR DETERMINATION` 語法，不是官方新式 `FOR DETERMINE ON SAVE`；`field(readonly)` 會擋住 Determination 內部寫入；Unmanaged 非 Draft 完全沒有宣告式語法（官方明講，非本系統限制）（2026-08-16 實測，RAP 課程 rap05）

- **官方文件 `ABENBDL_DETERMINATIONS` 明講 Determination 的可用範圍**：Managed RAP BO 可以用；Unmanaged **且啟用 Draft** 也可以用；**「Caution: Not available for unmanaged, non-draft RAP BOs.」**——這門課到目前為止的 Unmanaged 範例（`ZI_RAP03_UMTEST`）都沒有啟用 Draft，屬於官方明講「不支援」的情境，所以 Unmanaged 沒有 `determination ... on save { }` 這種宣告式語法可用，**這不是這系統的限制，是 RAP 框架設計本身的規則**，等效邏輯只能手寫在 `CREATE`/`UPDATE` 方法（或它們呼叫的私有方法）裡。
- **⚠️ Managed Determination 的 Handler Method，這系統要用官方標成「obsolete」的舊式語法，新式語法編譯失敗**：官方現行文件 `ABAPHANDLER_METH_DET` 教的新式寫法 `METHODS meth FOR DETERMINE ON SAVE IMPORTING keys FOR bdef~det.`，在這系統啟用直接報 `"DETERMINATION" expected, not "DETERMINE ON".`——要改用官方另一份文件 `ABAPMETHODS_FOR_DET_VAL_OBS`（標題就寫「Obsolete declaration」）描述的舊式關鍵字 `FOR DETERMINATION`，這是本課程第 N 次遇到「這系統的編譯器停在比官方目前教材更早的語言版本，新式語法過不了、舊式（官方標成過時）語法才是對的」這個模式（呼應 `strict`／`view entity`／`etag master` 等既有記錄）。
- **正確語法組合（逐步錯誤訊息實測逼出來的，不是文件裡直接找到的）**：
  ```abap
  METHODS setCreationInfo FOR DETERMINATION Task~setCreationInfo
    IMPORTING keys FOR Task.
  ```
  - 方法名稱後是 `FOR DETERMINATION <alias>~<determination名稱>`（完整寫一次 determination 的參照，等同官方新式語法裡 `FOR DETERMINE ON SAVE` + `FOR bdef~det` 兩處合併成一處）。
  - `IMPORTING keys FOR <alias>`——⚠️ 這裡**不能**再重複 `~<determination名稱>`，只要實體別名；寫成 `FOR Task~setCreationInfo` 會報 `"TASK~SETCREATIONINFO" is not a subentity of the root entity`；完全省略 `IMPORTING` 子句則報 `"field FOR entity" or "IMPORTING field FOR" expected`。
  - 中途如果 BDEF 的 `determination` 宣告還沒有真的 activate 成功就先測 Handler Method，會看到一個很有誤導性的錯誤 `A determination/validation is specified as "entity~name".`——這句話看起來像是在抱怨參照格式，實際是在說「找不到這個名字的 determination」；**這通常是因為 BDEF＋依賴它的 Class 放在同一個 activation 請求裡，其中一個失敗導致兩個都沒真的生效**（本檔第 34 節已經記過類似模式），排查時務必把 BDEF 拆開單獨 activate、`GET ?version=active` 讀回確認內容真的變了，不要只看 activation API 回應有沒有報錯。
- **這系統的 BDEF 衍生型別技術鍵欄位統一是 `%key`，Determination 情境下也一樣**（不是官方教材常見的 `%tky`），跟第 3 節 rap03 已經在 `READ` 方法踩過的坑一致。
- **⚠️⚠️ 跟官方範例行為不同的地方：這系統用 obsolete `FOR DETERMINATION` 語法宣告的 Handler，`IN LOCAL MODE` 對 `field(readonly)` 欄位的內部寫入會被擋下來**：官方範例 `ABENBDL_DETERMINATION_ABEXA` 的 `SoKey`（`field(readonly, numbering:managed)`）、`AmountSum`（`field(readonly)`）都能正常被 Determination 寫入，這是官方教材的標準用法；但這系統對 `field(readonly) created_at, created_by;` 的欄位執行 `MODIFY ENTITIES ... IN LOCAL MODE ... UPDATE FIELDS ( created_at created_by )` 一律報 `The field "CREATED_AT" of entity "..." cannot be modified.`——拿掉這兩個欄位的 `readonly` 之後問題消失，確認是 `readonly` 本身擋住的（不是別的原因），推測是這系統版本的 obsolete Handler Method 沒有拿到「內部框架寫入」的豁免。**Workaround**：Determination 要自動填值的欄位，這系統上不能同時標 `field(readonly)`——反正 Managed CUD 本來就執行不了（第 43 節），純語法示範拿掉即可，不影響教學重點；但這代表**如果之後 Managed Runtime 白名單限制真的解除**，這個 `readonly` 限制要一併重新驗證是不是也解除了，不能只看 CUD 能不能跑。
- **`TIMESTAMPL` 欄位不能直接接 `utclong_current()` 賦值**：`created_at = utclong_current( ).` 報 `Result type of "UTCLONG_CURRENT" cannot be converted into the type of "CREATED_AT".`——`TIMESTAMPL`（DEC21.7 底層表示）跟 `utclong`（8 byte 二進位）是不同的底層型別，這系統不支援兩者間的隱含轉換，要用 `cl_abap_tstmp=>utclong2tstmp( utclong_current( ) )` 明確轉換，這是 ABAP 標準系統類別，不是這系統特有的東西，只是隱含轉換這一步在這系統上行不通。
- **Unmanaged 的等效寫法已用 `programrun` 完整驗證成功**：`ZRAP03_UMTEST` 延伸加上 `created_at`/`created_by` 兩個標準 DE 欄位（`TIMESTAMPL`/`SYUNAME`），`CREATE` 方法一開始呼叫一個私有方法 `determine_creation_info( )`（回傳型別直接借用整張表結構圖方便）取得這兩個值，再一起 `INSERT`；`READ` 方法也要跟著補上讀取新欄位。這個私有方法命名故意跟 Part A 的 Determination Handler 同名概念（`setCreationInfo`/`determine_creation_info`），呼應「宣告式（框架自動呼叫）vs. 命令式（自己在 CREATE 裡明確呼叫）」是同一件事的兩種實現方式這個教學重點。驗證程式輸出：`created_at auto-filled: YES`／`created_by auto-filled correctly: MONICA`，EML `CREATE` 完全沒傳這兩個欄位，資料庫裡卻正確有值。
