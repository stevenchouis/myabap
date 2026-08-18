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

## 教材慣例（沿用 RAP Cloud/CDS 課程）

- 每題三件套（題目 md + PDF + 答案快照：Fiori 專案的關鍵檔案），`## Lecture` 開頭段落
- 每一課都要有「VS Code 操作 Step by Step」＋動手練習
- 驗證方式：`npm start` 本機執行＋瀏覽器截圖確認畫面效果（無頭驗證工具在這個工具鏈裡不適用，全部要靠使用者截圖回報）

## 課綱（草案，待確認）

| # | 主題 | 內容重點 | 狀態 |
|---|---|---|---|
| fe01 | 環境介紹＋連線設定 | VS Code Fiori tools Extension Pack 安裝、Generator 精靈完整操作、**BTP ABAP Cloud OData Service 連線 Step by Step**（System URL／Reentrance Ticket 的坑）、本機執行、跟 rc08 ADT Preview 的差異對照 | 待出題 |
| fe02 | 專案結構解讀 | `manifest.json`／`ui5.yaml`／`webapp/` 結構逐項解說，Routing、`sap.fe` 設定 | 待出題 |
| fe03 | List Report／Object Page 深化 | 真實 App 裡驗證 rc08 教過的 Annotation 效果，Table Settings、Section／SubSection、FieldGroup | 待出題 |
| fe04 | Custom Page | 超出範本能表達的客製化畫面 | 待出題 |
| fe05 | Controller Extension | Extension Point 加 JS 邏輯客製化行為 | 待出題 |
| fe06 | 部署 | `fiori deploy` 回 ABAP UI5 Repository | 待出題 |
| fe07 | Fiori Launchpad | Tile 設定、Semantic Object/Action、App-to-App 導航 | 待出題 |
| fe08（期末整合） | Composition App | 用 rc06 的 Header-Item（`ZI_RC06_ORDER`）做一個含子表格導覽的完整 App，整合前面所有主題 | 待出題 |

**待確認**：總題數／順序是否要調整；fe04（Custom Page）／fe05（Controller Extension）出題前要先查證這系統上實際可行的做法（比照 RAP Cloud 課程「查證優先」的習慣）。

## 待辦

- [x] 開課定案，README 草案完成
- [ ] 確認課綱（8 課）
- [ ] fe01 出題
