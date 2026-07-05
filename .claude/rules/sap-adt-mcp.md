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

- **allow**（唯讀、無副作用）：`sap_get_source`、`sap_object_structure`、`sap_syntax_check`、`sap_search_object`、`sap_usage_references`、`sap_run_unit_test`、`sap_inactive_objects`、`sap_abap_docu`、`sap_sql_query`（雖然第 3 節提到它目前回空，但語意上仍是讀取）、`sap-docs__*`。
- **ask**（有副作用，依 CLAUDE.md「建立物件、啟用、鎖定、釋放傳輸請求一律先列出內容確認」的規則）：`sap_set_source`、`sap_create_object`、`sap_activate`、`sap_lock`、`sap_unlock`、`sap_atc_run`。
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

## 匯出 SAP 原始碼到 src/ 的慣例

- 檔名採 abapGit 格式：`<物件名小寫>.<類型>.abap`（如 `zdqm0001.prog.abap`；INCLUDE 也是 `.prog.abap`）。
- 主程式要連同其 INCLUDE 一起匯出；多支程式共用的 INCLUDE 只存一份。
- `src/` 是**單向快照**：SAP 端修改後需重新匯出；本地修改要用 `sap_set_source` 寫回系統才算數。
