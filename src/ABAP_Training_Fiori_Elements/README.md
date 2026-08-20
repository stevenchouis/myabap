# Fiori Elements 開發課程（VS Code + SAP Fiori tools）

RAP Cloud 課程（`src/ABAP_Training_RAP_Cloud/`，rc01–rc08，2026-08-19 正式結案）的延伸篇。2026-08-19 定案開課，課綱規劃中。

## 為什麼要開這門課、跟 RAP Cloud 課程的分工

RAP Cloud 課程的 rc08 已經教過 `@UI.*` Metadata Extension 的語法（`headerInfo`／`facet`／`lineItem`／`identification`／`selectionField`／`valueHelpDefinition`），但驗證方式全程都是用 Eclipse Service Binding 編輯器裡的「Preview for Fiori Elements App」——這只是一個**臨時預覽**，不會產生任何持久物件，也看不到真正的 App 開發／客製化／部署流程。

這門課要教的是「Annotation 寫完之後，怎麼變成一個真正能開發、能客製化、能部署的 Fiori App」：

1. **VS Code + SAP Fiori tools Extension Pack** 怎麼連上 BTP ABAP Cloud Environment 的 OData Service（**這是這門課的環境基礎，fe01 會完整記錄操作步驟**）
2. Fiori Generator 精靈完整操作、產生的專案結構（`manifest.json`／`webapp/`／`ui5.yaml`）
3. 本機開發與預覽（`npm start`，Fiori Tools Proxy 怎麼代理到真實後端）
4. Custom Page／Controller Extension——超出 Annotation 能表達範圍的客製化
5. 部署（`fiori deploy` 回 ABAP UI5 Repository）
6. Fiori Launchpad Tile 設定

舊課程（RAP Cloud）保持完全不動，兩門課合起來才是完整路徑：先在 RAP Cloud 課程學會怎麼把 RAP BO／Annotation 寫對，再到這門課學怎麼把它變成一個真正的 App。

## 環境說明（2026-08-19 查證，詳見 memory `fiori-elements-tooling`）

- **連線環境跟 RAP Cloud 課程完全相同**：同一個 BTP ABAP Environment Trial 帳號，同一批已 Publish 的 Service Binding（`ZRC07_SB`／`ZRC08_SB`）可以直接拿來當 Data Source。
- **不需要 SAP Business Application Studio（BAS）**：VS Code Marketplace 直接安裝「SAP Fiori tools - Extension Pack」即可，不需要在 BTP 訂閱 BAS。
- **⚠️ 這是公開／多人共用的社群 Trial 系統**，跟 RAP Cloud 課程同樣的性質與限制（物件命名避免碰撞、資料有被重置風險）——本課程新產生的 Fiori App 專案本身是本機檔案（不是 SAP 系統物件），不受這個限制影響，但專案指向的後端 Service 仍然是這個共用系統。

### ⚠️⚠️ 連線步驟完整記錄（fe01 會用完整 Step by Step 呈現，這裡先列重點，避免下次忘記怎麼連）

VS Code 裡用 SAP Fiori tools 的 Application Generator 連 BTP ABAP Cloud Environment 的 OData Service，正確流程：

1. Command Palette（`Ctrl+Shift+P`）→ `Fiori: Open Application Generator`
2. Template 選 **List Report Page**（或其他範本）
3. Data Source 選 **`Connect to a System`**（**不要**選 `Connect to an OData Service`——那個要求 Basic Auth 帳密，這個 BTP Trial 的個人開發者帳號完全不支援 Basic Auth，只會卡住）
4. System 選 **New System**，System Type 選 **`ABAP Environment on SAP Business Technology Platform`**
5. ABAP environment definition source 選 **`Use Reentrance Ticket`**（**不要**選 `Discover a Cloud Foundry Service`——那個需要先 `cf login` 且要有 CF Space 權限，這個共用 Trial 帳號沒有走過這條路，設定成本高很多）
6. **System URL 是最容易填錯的地方**：**不能**用瀏覽器 Preview／Swagger 用的網域（`*.abap-web.ap21.hana.ondemand.com`），要用 **BTP Service Key JSON 裡 `"url"` 欄位那個網域**（`*.abap.ap21.hana.ondemand.com`，注意沒有 `-web`）——這兩個是不同的網域，前者填了會在下一步直接報錯「Edmx metadata is required to continue with generation」（一度以為是 SAP Community 上的已知未解 bug，實測後證實只是網址填錯）
7. System name 隨意命名（例如 `TRL`），按 Next 會跳出瀏覽器登入視窗，用平常登入這個 Trial 帳號的方式登入
8. 登入成功後，**Service** 下拉選單會列出這個使用者能看到的所有已 Publish Service Binding——選我們要用的（例如 `ZRC08_SB > ZRC08_SD (0001)`）
9. 「Download value help metadata」選 **Yes**（讓 Value Help 欄位正常運作）
10. Entity Selection：選 Main Entity，Table Type 一般情境選 **Responsive** 就好
11. Project Attributes：Module Name／Application Title 自訂；其餘選項（TypeScript／Deployment Config／Launchpad Config／Advanced Options）先保留預設 **No**，**Use Virtual Endpoints for Local Preview** 保留預設 **Yes**；Project Folder Path 指定存放位置後按 **Finish**

產生完成後，專案資料夾裡 `ui5.yaml` 的 `fiori-tools-proxy` middleware 會自動帶入正確的 `backend.url`（跟第 6 步同一個 API 網域）與 `authenticationType: reentranceTicket`，執行 `npm start`（或 VS Code 的 Start 指令）就會在本機啟動開發伺服器（預設 `http://localhost:8080`），透過這個 Proxy 把 OData 請求轉去真實的 BTP ABAP Cloud 後端。

**2026-08-19 已完整驗證成功**：用這個流程產生 `rc08noteapp`（List Report + Object Page，指向 rc08 的 `ZI_RC05_NOTE`），本機執行 `npm start` 後瀏覽器開 `http://localhost:8080/test/flp.html#app-preview`，正常顯示真實資料、Create／Delete 按鈕、Draft 專屬的 Editing Status 篩選——完整流程可行，非空想。

## 套件與命名慣例

- **後端物件**：完全沿用 RAP Cloud 課程已建立的 `ZI_RC05_NOTE`／`ZI_RC01_TASK` 等 CDS View/BDEF/Service Binding，本課程不重新建立 ABAP 後端物件（除非某一課需要一個全新情境）。
- **前端專案**：每一課一個獨立的 Fiori App 專案資料夾，命名 `feNN_<主題>`（例如 `fe01_connection_test`），**存放在本課程目錄下**（`src/ABAP_Training_Fiori_Elements/feNN_xxx/`），跟其他課程的「答案快照」慣例一致，方便版控留存；`node_modules/`／`dist/` 等產生物透過 `.gitignore` 排除，只保留 `webapp/`／`manifest.json`／`ui5.yaml`／`package.json` 等原始碼層級的檔案。
  - **⚠️ 例外：fe06（Adaptation Project）的資料夾是 `fe06.travel.ext`（點記法）**，不是 `fe06_xxx`——Adaptation Project 的 Project Name 本質上是 SAP 的 Application Variant 技術 ID，工具本身就要求用點記法命名，不是這門課能自訂的慣例，之後如果還有其他 Adaptation Project 課題，一樣會是這種命名。

## 教材慣例（沿用 RAP Cloud/CDS 課程）

- 每題三件套（題目 md + PDF + 答案快照：Fiori 專案的關鍵檔案），`## Lecture` 開頭段落
- 每一課都要有「VS Code 操作 Step by Step」＋動手練習
- 驗證方式：`npm start` 本機執行＋瀏覽器截圖確認畫面效果（無頭驗證工具在這個工具鏈裡不適用，全部要靠使用者截圖回報）

## 課綱（草案，待確認）

| # | 主題 | 環境 | 內容重點 | 狀態 |
|---|---|---|---|---|
| fe01 | 環境介紹＋連線設定 | BTP Trial | VS Code Fiori tools Extension Pack 安裝、Generator 精靈完整操作、**BTP ABAP Cloud OData Service 連線 Step by Step**（System URL／Reentrance Ticket 的坑）、本機執行、跟 rc08 ADT Preview 的差異對照 | ✅ 已出題並驗收（2026-08-19） |
| fe02 | 專案結構解讀 | BTP Trial | `manifest.json`／`ui5.yaml`／`webapp/` 結構逐項解說，Routing、`sap.fe` 設定 | ✅ 已出題（2026-08-19） |
| fe03 | List Report／Object Page 深化 | BTP Trial | 真實 App 裡驗證 rc08 教過的 Annotation 效果，Table Settings、Section／SubSection、FieldGroup | ✅ 已出題（2026-08-19） |
| fe04 | Custom Page | BTP Trial | 超出範本能表達的客製化畫面 | ✅ 已出題（2026-08-19） |
| fe05 | Controller Extension | BTP Trial | Extension Point 加 JS 邏輯客製化行為 | ✅ 已出題並驗收（2026-08-19） |
| fe06 | 擴充 SAP 標準 App——UI 層（Adaptation Project） | BTP Trial | 查標準 App 的 OData Service／UI Annotation、加 Extension View（Fragment）、Enhance UI Annotation（既有欄位可見度）——不動後端資料模型的前端擴充 | ✅ 已出題並驗收（2026-08-19） |
| fe07 | 擴充 SAP 標準 App——後端層（CDS View Extension） | ⚠️ **On-Premise**（`S4H`） | `EXTEND VIEW` 加真實欄位、新增 Metadata Extension 加 `@UI` Annotation——ABAP 官方的「不改原始 CDS View、疊加真實資料欄位」機制，跟 fe06 互補（UI 層 vs 後端層）。**唯一不在 BTP Trial 上的課次**，因為要重現團隊內部舊 PPT 用的傳統 on-premise 開發模式 | ✅ 已出題並驗收（2026-08-19） |
| fe08 | Interface／Projection 兩層架構 | BTP Trial | 幫既有的 `ZI_RC01_TASK`（Interface，rc01 建立至今從未曝露成 App）加一層 `ZC_RC01_TASK`（Projection，含 Projection BDEF＋UI Annotation），完整示範官方建議的兩層架構語法與使用時機（Release Contract／多重曝露） | ✅ 已出題並驗收（2026-08-19） |
| fe09 | 純 Report（無 BDEF） | BTP Trial | `ZI_RC01_TASK_SUMMARY`——單層 CDS View 直接 `GROUP BY` 彙總，不宣告 `root`、不需要 BDEF，跟 fe08 的完整兩層架構對照互補 | ✅ 已出題並驗收（2026-08-19） |
| fe10 | 部署 | BTP Trial | `Fiori: Add Deployment Configuration`＋`npm run deploy` 把 `fe01_connection_test` 部署成 `ZFE10_NOTE_APP`（SAPUI5 ABAP Repository）。**端對端實測：部署機制成功，瀏覽器直接存取一度被 `403 Forbidden: blocked by UCON` 擋下，已在 fe11 用 Communication Scenario＋Publish Locally 解開並驗證成功**——不需要管理員權限，開發者在 ADT 自己就能做 | ✅ 已出題並端對端驗收成功（2026-08-19） |
| fe11 | Fiori Launchpad | ⚠️ **On-Premise**（`S4H`）＋BTP 補課 | **改用地端系統**（2026-08-19 決策：BTP 共用 Trial 帳號實測搜不到 `Business Roles`，證實沒有管理員權限，無法完整教到「其他人能用」；地端使用者有完整登入權限）。沿用 rap04 的 `ZRAPT01_SB3` 當後端，教 `fiori add flp-config`（`crossNavigation`／Semantic Object+Action）＋ Fiori Launchpad Designer（`/UI2/FLPD_CUST`：Catalog／Target Mapping／Tile／Group）＋ PFCG Role 指派，完整走通 fe10 沒能打通的「部署→授權→Launchpad 開得到」全流程。**加碼補充並已驗證成功**：BTP `Communication Scenario`（開發者，ADT 建立＋Publish Locally）解開了 fe10 的 UCON 403（實測 `Notes (1)` 正常顯示），推翻「需要管理員權限」的原始結論。**外部系統（Postman）存取路線已於 2026-08-20 確認做不到**：`Maintain Communication Users`／`Communication Systems`／`Communication Arrangements` 三個 App 在共用帳號上搜尋不到，跟 `Business Roles` 同一類權限邊界（都需要 `SAP_BR_ADMINISTRATOR`），已如實記錄成限制；同時查證確認 `SAP_BR_ADMINISTRATOR` 只在 BTP 這一列有意義，地端 PFCG 部分靠的是傳統 `S_USER_*` 權限物件，兩者不可混用 | ✅ 已出題並端對端驗收成功，2026-08-20 完整結案 |
| fe12（期末整合） | Composition App | BTP Trial | 用 rc06 的 Header-Item（`ZI_RC06_ORDER`／`ZI_RC06_ORDER_I`）補上兩層 Projection＋`@UI.facet`（`#LINEITEM_REFERENCE`）做出 Object Page 內嵌子表格；串起 Composition（rc06）／兩層架構（fe08）／Metadata Extension（fe03/fe07/fe08）／Draft 只影響 Create/Update 不影響 Delete（fe08 發現、這一課精緻化）全部主題，動手練習請學生回頭補 `with draft;` 收尾。**端對端驗證成功**：`Items` 子表格正確顯示明細，無 Create 有 Delete 按鈕，`Navigation Entity` 選 `None` 的判斷也驗證正確 | ✅ 已出題並端對端驗收成功（2026-08-20） |

**待確認**：總題數／順序是否要調整；fe04（Custom Page）／fe05（Controller Extension）出題前要先查證這系統上實際可行的做法（比照 RAP Cloud 課程「查證優先」的習慣）——fe06（Adaptation Project）沿用同一個習慣，已用 BTP Trial 實測確認可行。

## 待辦

- [x] 開課定案，README 草案完成
- [ ] 確認課綱（8 課）
- [x] fe01 出題並驗收（2026-08-19，`fe01_connection_test`，`ZRC08_SB`／`ZI_RC05_NOTE`）
- [x] fe02 出題（2026-08-19，深度解析 fe01 已產生的專案，未產生新物件）
- [x] fe03 出題（2026-08-19，本機 Annotation 疊加＋Table Settings，實測「同 Target/Term 整個覆蓋不是合併」的關鍵行為）
- [x] fe04 出題（2026-08-19，Custom Page 取代 NoteObjectPage，Page Map 的 `+` 需要 Navigation Property 才能用，Custom Page 會失去範本自動生成的 CRUD 工具列）
- [x] fe05 出題（2026-08-19，Controller Extension 掛 `NoteList` 的 `routing.onAfterBinding`＋輕量 Custom Action 按鈕；實測推翻「每次按 Go 都會觸發」的假設，`onAfterBinding` 一頁只觸發一次）
- [x] fe06 出題（2026-08-19，Adaptation Project 擴充標準 App `Demo App for Travel V2`；`fe06.travel.ext` 全新獨立專案，Controller Extension＋Fragment 兩種擴充都端對端驗證成功，意外發現標準 App 底層是舊式 `sap.suite.ui.generic.template`／OData V2，不是新式 `sap.fe.templates`）
- [x] fe07 出題（2026-08-19，CDS View Extension 擴充標準 App `C_SlsDocFlfllmntAnalyzer`（Track Sales Orders 背後真正的 View）；查證團隊內部 2022 舊 PPT 教材非過時，官方查詢入口是 SAP GUI `SCFD_REGISTRY`＋Eclipse `Ctrl+Shift+A`；完整記錄第一次憑名稱猜測選錯目標物件（`C_SalesOrderTP`）繞遠路的教訓；端對端驗證成功，`Personnel Number` 篩選欄位真的出現在 Fiori Launchpad 畫面上）
- [x] fe08 出題（2026-08-19，Interface／Projection 兩層架構；`ZC_RC01_TASK` projection on 既有 `ZI_RC01_TASK`，`ZI_RC01_TASK` 從 rc01 建立至今首次真正曝露成 App；查證兩層架構官方現行有效，`use action` 需顯式宣告但 Determination/Validation 不用；後端已在 Eclipse 建立並 Publish 成功，前端 App 產生與畫面驗證待補）
- [x] fe09 出題（2026-08-19，純 Report 無 BDEF；`ZI_RC01_TASK_SUMMARY` 依 status GROUP BY 彙總；查證「為什麼不宣告 root」——root 語意綁定 Business Object 結構，無 BDEF 就無結構；後端已建立並 Publish 成功，前端待補）
- [x] fe10 出題並端對端實測（2026-08-19，部署；沿用 fe01 的 `fe01_connection_test` 專案，`Fiori: Add Deployment Configuration`＋`npm run deploy` 部署成 `ZFE10_NOTE_APP`（套件 `ZRAPCLOUD`）；查證官方文件確認部署會建立 BSP App／MIME 資料夾／ICF Node／Launchpad Descriptor Items 四種物件；使用者實際執行部署，終端機回報 `Deployment Successful`，但瀏覽器打開實際網址得到 `403 Forbidden: blocked by UCON`——部署機制本身驗證成功，瀏覽器直接存取需要 fe11 的 Communication Arrangement／IAM App 才能打通；過程中也發現真實 `ui5-deploy.yaml`／URL 格式跟原本查證的官方文件範例有落差（已更正），以及 `I_CustABAPObjDirectoryEntry` 在這個環境查不到部署物件，Claude 端沒有可靠的獨立驗證方式）
- [x] 各課次補上明確「環境」標示（2026-08-19，使用者提醒 fe07 是 On-Premise、其餘是 BTP Trial，容易混淆——已在 fe01～fe10 每份講義標題下方加 `> **環境**：...` 提示行，README 課綱表也新增「環境」欄）
- [x] fe11 出題並端對端驗收（2026-08-19～2026-08-20，Fiori Launchpad；**改用地端系統**——BTP 共用 Trial 帳號實測搜尋不到 `Business Roles` 管理 App，證實沒有管理員權限，決定切到使用者有完整登入權限的地端系統，這是本課程第二次環境切換；沿用 rap04 留下的 `ZRAPT01_SB3`／`ZRAPT01_SD`／`ZI_RAPT01` 當後端（查證仍是 Published 狀態）；查證 BTP／On-Premise 兩套 Launchpad 授權模型對照（IAM App/Business Catalog/Business Role vs Catalog/Group/PFCG Role，Semantic Object/Action 概念兩者共用）；教 `fiori add flp-config`（`crossNavigation.inbounds`）＋ `/UI2/FLPD_CUST`（Catalog／Target Mapping／Tile／Group）＋ PFCG Role 指派；完整補上 fe10 卡在 UCON 沒能走完的「部署→授權→Launchpad 開得到」最後一段。**2026-08-20 補課完整結案**：確認 BTP FLP 網址規律（部署網域＋`/sap/bc/ui2/flp`）；確認外部系統存取（Postman／Communication User/System/Arrangement）在共用帳號上做不到（`Maintain Communication Users`等三個 App 搜不到）；查證官方文件確認根本原因是 `SAP_BR_ADMINISTRATOR` 這個 Business Role 只在自己申請的獨立帳號才有、共用 Trial 池刻意鎖住；同時釐清 `SAP_BR_ADMINISTRATOR`（BTP）與地端傳統 `S_USER_*` 權限物件是兩套不同機制，不可混用）
- [x] fe12 出題並端對端驗收成功（2026-08-20，期末整合，Composition App；沿用 rc06 既有的 `ZI_RC06_ORDER`／`ZI_RC06_ORDER_I`（Header-Item Composition，確認仍在 `ZRAPCLOUD` 套件），補上兩層 Interface/Projection 架構（`ZC_RC06_ORDER`／`ZC_RC06_ORDER_I`）＋`@UI.facet`（`type: #LINEITEM_REFERENCE`＋`targetElement: '_Item'`）讓 Object Page 內嵌 Items 子表格；查證三份官方文件確認語法：`ABAP_Cloud` UI Annotation 文件（Carrier/Airline、Agency/Review 兩個範例）確認 Facet 語法、`ABENCDS_PV_ASSOC_REDIRECTED` 確認 Projection 層 Composition 要用 `REDIRECTED TO COMPOSITION CHILD`／`REDIRECTED TO PARENT`、openSAP 官方 RAP 課程 Week3 Unit3（Travel/Booking）確認 Projection BDEF 用 `use association _Item { create; }`／`use association _Header;`；嘗試用 `create_object_programmatically` 這個 MCP 工具直接建立 DDLS/PROG/CLAS 全部失敗（同一類 deserializing error，範圍比原本記錄的更廣），確認沿用課程既有的「Eclipse 建立、Claude 設計＋事後驗證」分工模式；刻意沒加 `with draft;`（跟 fe08 同樣沒有 Draft），留作主要動手練習收尾整門課。**過程中修正兩個真實踩坑**：Metadata Extension 誤寫 `key`（不能重複宣告主鍵）、Service Definition 曝露名稱撞保留字 `Order`（改用 `OrderHeader`）；新建 `ZCL_RC06_SEED_DATA`（`IF_OO_ADT_CLASSRUN`，ABAP Cloud 不允許傳統 Program）補測試資料；使用者截圖確認新版 Generator 精靈多了 `Navigation Entity` 欄位、選 `None` 正確。**端對端驗證結果**：Object Page 正確顯示 `Items` 子表格兩筆明細，無 Create 按鈕、有 Delete 按鈕（精緻化「Draft 是 CUD 前提」為「Draft 只影響 Create/Update，不影響 Delete」）；整門課的期末整合課程正式驗收完成）
