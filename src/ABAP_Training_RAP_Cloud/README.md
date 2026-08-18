# RAP Cloud 實戰課程（SAP BTP ABAP Environment）

RAP 課程（`src/ABAP_Training_RAP/`，rap01–rap09，2026-08-17 正式結案）的延伸篇。2026-08-18 定案開課，rc01～rc08（期末）已全部出題並驗收完成，**2026-08-19 正式結案**。

## 為什麼要開這門課、跟既有 RAP 課程的分工

既有 RAP 課程是在這個專案的 On-Premise S/4HANA 1909 系統上做的，那個系統的套件沒有啟用「ABAP Cloud 語言版本」，導致：

- CDS View 只能用舊式 `define view`（無 `entity` 關鍵字）
- BDEF 沒有 `strict` 模式
- **Managed BDEF 的 CUD（Create/Update/Delete）雖然語法正確、能啟用，但執行到底層一律被 SAP 官方的 `CL_CSP_MD_METADATA_FACTORY` 白名單擋下 Dump**（詳見 `.claude/rules/sap-adt-mcp.md` 第 43 節）——這代表舊課程雖然完整教了 Managed BO 語法，卻**從來沒有機會讓學員看到 Managed CUD 真正端對端跑起來**
- Draft、Late Numbering、Side Effects 這些功能，官方版本對照表顯示要 On-Premise 7.57～7.58（≈S/4HANA 2022～2023）才有完整支援，這個系統的 7.54（1909）也用不了

**這門課不重講舊課程已經教過的東西**（Managed/Unmanaged 概念、五層架構、BDEF 基本語法），而是專注在「這個新環境才辦得到的事」：

1. 新式 CDS View Entity 語法（`define root view entity`）
2. `strict(2)` 模式
3. **Managed BDEF 的 CUD 真正能執行完**（不會被白名單擋下來）
4. Draft、Early/Late Numbering
5. Composition／Association 的完整體驗
6. Service Binding **真正 Publish 成功**，走 Fiori Launchpad
7. Fiori Elements 基礎（`@UI.*` annotation 實際看到畫面效果）

舊課程（`src/ABAP_Training_RAP/`）保持完全不動，兩門課合起來才是完整的學習路徑：先在舊課程扎穩語法基礎、理解「為什麼真實企業系統版本常常落後」，再到這門課看語法真正跑起來的樣子。

## 環境說明（2026-08-18 查證，詳見 memory `cloud-rap-exploration`）

- **連線方式**：VS Code 擴充套件 `vscode-abap-remote-fs`（作者 marcellourbani）內建的 MCP Server，`.mcp.json` 裡的 server 名稱是 `abap-remote-fs`，`connectionId` 固定是 **`abap_cloud`**。跟舊 RAP/CDS 課程用的 `sap-adt`（Eclipse Plugin＋`adt-rfc-bridge`）是完全不同的連線機制與工具集。
- **系統版本**：已用讀取既有物件原始碼的方式證實（`strict(2)`／`with draft`／`early numbering`／`field(features:instance)`／`define root view entity`），版本完全足夠支援本課程所有規劃內容，不需要再另外查版本號（`SVERS`/`CVERS` 這類表被 ABAP Cloud 的 Released API 限制擋住，查不到，但這本身就是正確受限行為的證據）。
- **⚠️ 這是公開／多人共用的社群 Trial 系統，不是私人租戶**：套件清單裡有大量明顯屬於其他學員的物件（各種語言、各種線上課程的練習內容）。使用者已確認知情並接受這個性質。實務影響：
  - 物件命名要避免碰撞，本課程一律建在使用者自己專用的套件（見下方「套件與命名慣例」）
  - 系統資料有被重置的風險，不適合假設物件會永久保留
  - 資料模型沿用系統既有的 `/DMO/*`（SAP 官方 RAP 教學參考模型：Travel／Booking／Agency／Flight），不是舊課程用的 SCARR/SFLIGHT/SBOOM（那套在這個系統上也有部分學員建過類似模型，但不是官方標準內容，不適合當作課程依賴的穩定資料源）
- **⚠️⚠️ 重大限制：MCP 工具的「建立新物件」功能目前對這個系統版本整體故障**（`create_object_programmatically`），不分套件類型（本地／正式）、不分物件型別（PROG／DDLS／CLAS 都測過，一律卡在對應的 XSLT `deserializing` 錯誤），也跟有沒有配傳輸請求無關。VS Code 擴充套件本身（不透過 MCP）建立物件也會跳出同樣的錯誤通知，證實是這個擴充套件版本與這個 Cloud 租戶後端的相容性問題，不是 MCP 包裝的問題。
  - **但 Eclipse ADT 原生建立完全正常**——已用使用者實際建立的 `ZCLASS_TEST1` 驗證過。
  - **MCP 工具的讀取／修改內容／啟用／語法檢查／ABAP Unit 全部正常**——已完整測過一輪（`get_abap_object_lines`／`replace_string_in_abap_object`／`abap_activate`／`get_abap_diagnostics`）。
  - **本課程的分工模式**：每個新物件的「建立空殼」這一步，一律由使用者在 **Eclipse ADT** 手動完成；Claude 接手後續所有動作（寫入完整內容、語法檢查、啟用、驗證）。這比舊 On-Premise 課程的分工範圍更廣（舊課程只有少數物件如 Service Binding 需要手動建立，這裡是**所有物件類型**都需要）。
- **執行驗證工具**：這個環境沒有對應 On-Premise `programrun`（無頭執行報表看 `WRITE` 輸出）的工具。改用：
  - **`run_unit_tests`（ABAP Unit）**：寫測試類別呼叫 EML，跑完拿到逐方法 pass/fail——這是本課程驗證 RAP CUD／Determination／Validation／Action 的主要手段，也更貼近官方建議的 RAP 測試方式（比 `programrun`+`WRITE` 更正規）
  - **`execute_data_query`**：對應 On-Premise 的 Data Preview／`datapreview/freestyle`，可以直接下 SQL 查資料庫驗證結果

## 套件與命名慣例

- **套件**：待使用者在 Eclipse 建立一個專用套件（建議 `ZRAPCLOUD`，非本地／需要 Transport Request 的正式套件，比照使用者既有的 `ZSTEVENCGHOUIS`／`ZSTEVENCGHOUIS1` 模式），本課程所有物件都建在這個套件下，跟使用者其他測試物件（`ZCLASS_TEST1` 等）分開。
- **物件命名**：沿用舊 RAP 課程的分類慣例，前綴改用 `RC`（RAP Cloud）避免跟舊課程物件名稱混淆：
  - `ZRCnn_*`：DDIC Table
  - `ZI_RCnn_*`：CDS Interface View（Root）
  - BDEF：跟 CDS View 同名
  - `ZRCnn_SD`／`ZRCnn_SB`：Service Definition／Service Binding
  - ABAP Unit 測試類別：跟被測物件同名的 Local Test Class Include，或獨立 `ZCL_RCnn_TEST_*`

## 教材慣例（比照舊 RAP/CDS 課程）

- 每題三件套：題目 `rcNN_主題.md` + PDF 講義 + 答案快照
- `## Lecture` 開頭要有背景知識講解，**重點放在跟舊課程／On-Premise 系統的差異對照**，不重複已經教過的基礎概念
- 範例前先分段講解語法
- 每一課都要有「Eclipse ADT 建立空殼物件」Step by Step（**這門課這一步是必要的，不是選擇性的**）＋動手練習
- 驗證方式：ABAP Unit（`run_unit_tests`）為主，`execute_data_query` 輔助；最終的 Fiori Elements 畫面效果仍需使用者在瀏覽器/Fiori Launchpad 手動確認

## 課綱（草案，待確認，共 8 課）

| # | 主題 | 內容重點 | 狀態 |
|---|---|---|---|
| rc01 | 環境介紹＋CDS View Entity | 環境差異總覽（含建立物件要走 Eclipse 的限制）；`define root view entity` 語法，跟 On-Premise 舊語法逐項對照；建立第一個 Table＋CDS Interface View | ✅ 已完成（2026-08-18，`ZRC01_TASK`＋`ZI_RC01_TASK`，套件 `ZRAPCLOUD`，啟用成功並用 `execute_data_query` 驗證查詢正常） |
| rc02 | Managed BDEF＋`strict(2)` | 完整語法＋**CUD 真正端對端執行成功**（ABAP Unit 驗證，對照舊課程 rap03 記錄的白名單 Dump） | ✅ 已完成（2026-08-18，`ZI_RC01_TASK` BDEF＋`ZCL_RC02_TASK_TEST`，`run_unit_tests` ALL TESTS PASSED；`strict(2)`／Implementation Class 因果鏈已查證並記錄，實際物件先用零 Implementation Class 版本，完整 `strict(2)` 留給 rc03） |
| rc03 | Determination／Validation | 官方現行語法（`FOR DETERMINE ON SAVE`／`FOR VALIDATE ON SAVE`）能不能用，對照舊課程 rap05/rap06 被迫用 obsolete 語法 | ✅ 已完成（2026-08-18，完整 `strict(2)`＋`ZBP_I_RC01_TASK`／`lhc_task`，`run_unit_tests` ALL TESTS PASSED；重大發現：`COMMIT ENTITIES` 驗證失敗後 Transactional Buffer 不會自動清空，需 `ROLLBACK ENTITIES`，官方文件 `ABENBDL_VALIDATIONS`／`ABAPROLLBACK_ENTITIES` 佐證） |
| rc04 | Action | 對照舊課程 rap07 | ✅ 已完成（2026-08-18，`ZI_RC01_TASK` 新增 `action markDone`＋`ZBP_I_RC01_TASK` 新增 Handler Method，`run_unit_tests` ALL TESTS PASSED 3/3；核心結論：Action 語法跟舊課程 rap07 完全相同、無新舊版本落差，因為掛在沒有 obsolete 問題的 `FOR MODIFY` 類別底下，講義含 BDEF／Handler Method 兩組語法逐項詳解） |
| rc05 | Draft | 舊課程完全驗證不了的部分 | ✅ 已完成（2026-08-19，全新獨立實體 `ZI_RC05_NOTE`／`ZRC05_NOTE`／`ZRC05_NOTE_D`，`with draft;`＋五個標準 Draft Action，`run_unit_tests` ALL TESTS PASSED 2/2，兩測試一次過、無需除錯；核心發現：Draft 完全由框架處理，不需要任何 ABP 實作，是這門課第一次不用碰 Local Types 的一課） |
| rc06 | Composition／Association（Header-Item） | 對照舊課程 rap08，含 `%cid_ref` vs `%key` 的父鍵引用規則 | ✅ 已完成（2026-08-19，`ZI_RC06_ORDER`／`ZI_RC06_ORDER_I` Header-Item，`run_unit_tests` ALL TESTS PASSED 2/2；核心發現：`lock dependent by _Header` 官方現行語法直接可用（對照舊課程 workaround）、Managed Composition 的 Cascading Delete 完全由框架處理（`ZBP_I_RC06_ORDER` 純空殼）、EML 父子關聯要用 `%cid_ref`（推翻舊課程 rap08 的 `%key` 結論）） |
| rc07 | Service Definition／Binding／Publish | 這次應該能真正 Publish 成功，走 Fiori Launchpad | ✅ 已完成（2026-08-18，`ZRC07_SD`／`ZRC07_SB`（OData V4 - UI）Publish 成功；用 Eclipse 內建 Swagger UI 直接測 OData 協定：`GET /Task` 200 查到真實資料、`POST /Task` 201 驗證 Determination 透過真正 OData Create 也會觸發、Action 因 `etag master` 被 OData V4 標準的 `428 If-Match` 併發控制擋下（非失敗，已完整解釋）；額外發現 BTP 個人帳號只能走 OAuth 不能 Basic Auth） |
| rc08（期末整合） | Fiori Elements 基礎＋整合 | `@UI.*` 實際看到畫面效果，整合前面所有主題 | ✅ 已完成（2026-08-19，`ZI_RC01_TASK`／`ZI_RC05_NOTE` 加 `@UI.*` Metadata Extension，`ZI_RC08_STATUS_VH`＋`ZCL_RC08_STATUS_VH` 實作 Value Help（CDS Custom Entity＋`IF_RAP_QUERY_PROVIDER`）；🏆 核心收尾發現：OData V4 UI 服務若背後實體無 Draft，Fiori Elements 標準範本天生不會產生 Create／Edit 按鈕（即使協定層完全支援），用 `ZRC07_SB`（非 Draft，無 Create/Edit）vs 新建 `ZRC08_SB`（`ZI_RC05_NOTE`，Draft，有 Create/Edit＋Editing Status 篩選）實測對照證實） |

## 出題工作流程

1. 使用者在 Eclipse ADT 建立本課需要的空殼物件（Table／CDS View／BDEF／Service Definition／Service Binding 等）
2. Claude 用 `abap-remote-fs` MCP 讀取空殼、寫入完整內容（`replace_string_in_abap_object`）
3. `get_abap_diagnostics` 語法檢查 → `abap_activate` 啟用
4. `run_unit_tests`／`execute_data_query` 驗證資料與行為正確
5. 使用者驗收（含視覺效果需要的畫面確認）→ 快照 → 題目 md → PDF → 更新本 README 狀態 → commit

每批 1-2 課、使用者驗收後再繼續（比起 On-Premise 課程步調更保守，因為每課都需要使用者先手動建立空殼，協調成本較高）。

## 待辦

- [x] 使用者在 Eclipse 建立專用套件 `ZRAPCLOUD`
- [x] 確認課綱草案（8 課，暫不加 Fiori Elements 進階章節，留給未來獨立課程）
- [x] rc01 出題（2026-08-18）
- [x] rc02 出題（2026-08-18）
- [x] rc03 出題（2026-08-18，Determination／Validation＋完整 `strict(2)`＋Implementation Class，`run_unit_tests` ALL TESTS PASSED，發現 `COMMIT ENTITIES` 失敗後需 `ROLLBACK ENTITIES` 才會清空 Transactional Buffer，已寫入講義並有官方文件佐證）
- [x] rc04 出題（2026-08-18，Action，`run_unit_tests` ALL TESTS PASSED 3/3；核心結論：Action 語法跟舊課程 rap07 完全相同，講義含 BDEF／Handler Method 兩組語法逐項詳解）
- [x] rc05 出題（2026-08-19，Draft，`run_unit_tests` ALL TESTS PASSED 2/2，一次過無需除錯；核心結論：Draft 完全由框架處理，不需要任何 ABP 實作）
- [x] rc06 出題（2026-08-19，Composition／Association，`run_unit_tests` ALL TESTS PASSED 2/2；核心發現：`lock dependent by _Header` 直接可用、Cascading Delete 框架自動處理、`%cid_ref` 推翻舊課程 `%key` 結論）
- [x] rc07 出題（2026-08-18，Service Definition／Binding／Publish，`ZRC07_SD`／`ZRC07_SB` Publish 成功；用 Eclipse 內建 Swagger UI 直接驗證 OData V4：GET 查到真資料、POST 驗證 Determination 透過真正協定觸發、Action 因 ETag 併發控制被 428 擋下並完整解釋；額外發現 BTP 個人帳號只能走 OAuth 不能 Basic Auth）
- [x] rc08 出題（2026-08-19，Fiori Elements 基礎＋整合，`@UI.*` Metadata Extension＋Value Help Custom Entity；核心收尾發現：Draft 是 Fiori Elements 標準範本 Create/Edit 按鈕的前提，`ZRC07_SB`（非 Draft）vs `ZRC08_SB`（`ZI_RC05_NOTE`，Draft）實測對照證實——**RAP Cloud 課程 rc01～rc08 全課程正式結案**）
