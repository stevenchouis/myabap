# Fiori Elements 開發課程 11：Fiori Launchpad（Tile／Semantic Object/Action／PFCG Role）

> **⚠️⚠️ 環境：這一課換到 On-Premise 系統（`S4H`／Client `130`），不是 fe01～fe06／fe08～fe10 用的 BTP ABAP Environment Trial！**——原因見下方「這一課要解決的問題」；這是本課程第二次切換環境（第一次是 fe07），下一課 fe12 是否切回 BTP Trial 待規劃時再定。這一課使用者在地端系統上有完整登入權限（可以自己處理 PFCG／SAP GUI 角色與 Launchpad 設定），操作方式（SAP GUI `/UI2/FLPD_CUST`／`PFCG`，而非 BTP 的 IAM App／Business Catalog／Business Role）跟前後課次都不一樣。

## Lecture

### 這一課要解決的問題

fe10 把 `fe01_connection_test` 部署成 `ZFE10_NOTE_APP`，部署機制本身完全成功，但瀏覽器打開實際網址被 `403 Forbidden: blocked by UCON` 擋下——查證後發現這是「讓其他人能用」這條授權鏈路的問題（Business User 要能存取，需要 IAM App→Business Catalog→Business Role 這整條鏈，Business Role 的建立與指派是 Administrator 層級的工作），而使用者在那個共用 BTP Trial 帳號上實測**搜尋不到 `Business Roles` 這個管理 App**，證實沒有管理員權限——這是這個共用帳號的權限邊界，不是我們操作有誤。

這一課改到地端系統：使用者在這裡**有完整登入權限，能自己處理 PFCG／SAP GUI 角色**，可以把「部署好的 App 讓別人也能用」這條路完整走一次，不用卡在權限不明的環境上。**額外的價值**：地端用的是**傳統／Classic 授權模型**（PFCG Role + Fiori Launchpad Designer），跟 BTP 專屬的 Business Role 模型完全不同——這套 Classic 模型在實務上沿用了十幾年、大多數既有 SAP 客戶現場還是用這一套，教學價值不亞於 BTP 那套較新的模型。

### 兩套模型的對照（先建立整體概念，再進入操作）

| | BTP ABAP Environment（fe10 卡住的地方） | On-Premise（這一課） |
|---|---|---|
| 「誰能存取」的授權鏈 | IAM App → Business Catalog → Business Role → 指派給 Business User | **Catalog（含 Target Mapping）＋ Group（含 Tile）→ 掛進 PFCG Role 的選單 → 指派給使用者** |
| 誰負責建立「App 有哪些功能」 | 開發者建 IAM App（**開發者層級**，可自助） | 開發者在 **Fiori Launchpad Designer**（`/UI2/FLPD_CUST`）建 Catalog／Target Mapping／Tile |
| 誰負責「授權給誰」 | 管理員建 Business Role、指派（**管理員層級**） | 管理員（或有 `S_USER_*` 權限的人）在 **PFCG** 把 Catalog/Group 掛進角色選單、`SU01` 指派角色給使用者 |
| 需要的「管理員權限」長什麼樣子 | **Business Role**：`SAP_BR_ADMINISTRATOR`——透過 BTP ABAP Environment 的 Fiori App `Maintain Business Users` 指派給某個 Business User，這是 BTP 專屬的雲端身分模型（IAM/Identity Provisioning），不是傳統權限物件 | **PFCG 角色維護權限**：`S_USER_AGR`／`S_USER_GRP`／`S_USER_PRO`／`S_USER_TCD`／`S_USER_VAL` 這幾個經典權限物件（或直接是 `SAP_ALL`），透過 `SU01` 指派給使用者——這是沿用幾十年的傳統 ABAP 權限模型 |
| App 怎麼被辨識、串接 | 同樣是 **Semantic Object + Action**（Intent-Based Navigation，這個概念**兩套模型通用**，不是 BTP 專屬） | 同左 |

**⚠️⚠️ 重要澄清（避免名詞誤用）**：`SAP_BR_ADMINISTRATOR` 這個名字**只在 BTP ABAP Environment（Cloud）這一列有意義**，是雲端 Business Role 機制的產物；地端 On-Premise 系統要做這一課的 `/UI2/FLPD_CUST`＋`PFCG` 操作，**不需要（也沒有）指派字面上叫 `SAP_BR_ADMINISTRATOR` 這個東西**，需要的是上表右欄那組**傳統 PFCG 角色維護權限物件**——兩者都屬於「管理員層級的存取」，但機制、名稱、指派方式（BTP 用 Fiori App 指派給 Business User；On-Premise 用 `SU01` 指派 PFCG 角色給使用者）完全是兩套不同世代的系統，不要把 BTP 的角色名稱套用到地端系統上。這一課使用者在地端系統本來就有完整登入權限，所以地端這半邊從一開始就沒有被權限卡住——真正卡住的只有 BTP 那半邊（fe10 的 Business Role／fe11 補課的 Communication Management，都需要 `SAP_BR_ADMINISTRATOR`，而這個共用 Trial 帳號沒有）。

**重點**：Semantic Object／Action（Intent-Based Navigation）這個核心概念，BTP 跟 On-Premise 是**共用**的——manifest.json 裡怎麼宣告 Inbound Intent、App 之間怎麼靠 Semantic Object 互相導航，兩套環境的寫法完全一樣，只有「後台怎麼把這個 Intent 跟一個實際的 Tile／App 綁在一起、怎麼授權」這一層機制不同。這一課教的操作方式雖然是 On-Premise 專屬，但概念可以直接套用回 BTP。

### ✅✅ 補充：回頭解答 fe10 的 UCON 卡點——`Communication Scenario`（開發者）＋`Communication Arrangement`（管理員），這是 BTP 專屬機制、On-Premise 完全沒有；**已實測驗證成功**

fe10 部署成功後瀏覽器被 `403 blocked by UCON` 擋下，當時只查到「這是授權鏈路問題、需要管理員權限」就沒有再往下追。**回頭查證官方文件才發現：我們當時完全沒建過一個叫 `Communication Scenario` 的物件——這才是真正缺的那一步，而且這一步是開發者層級就能做的，根本不需要管理員權限。這個判斷已經實際操作驗證成功（見下方 Step by Step 最後的驗收記錄），推翻了 fe10 原本「需要管理員權限才能解決」的結論。**

**官方標準流程**（查證 `ABAP Cloud` 官方文件「Providing an OData Service」，非猜測）：

1. 建立 Web API（fe10 已完成：`ZI_RC05_NOTE`／`ZRC08_SB`）
2. **建立 Communication Scenario**——⚠️ 官方文件明講這是「a development artifact... created in the development system using ABAP Development Tools」，**是開發者在 Eclipse ADT 建立的物件，不是管理員專屬工作**
3. 把 Service Binding（`ZRC08_SB`）產生的 Inbound Service **加進**這個 Communication Scenario
4. **Publish** 這個 Communication Scenario，管理員才看得到、才能拿去用

**這四步做完之後，管理員才進場**：用這個已 Publish 的 Communication Scenario 建立 **Communication Arrangement**——這一步才真正「開放存取」，並且依照呼叫者身分分成兩種情境：

| 情境 | 需要的物件 | 對應到誰 |
|---|---|---|
| **自己測試／Fiori Launchpad 瀏覽器存取**（fe10 卡住的情境） | 只需要 Communication Scenario 存在＋**Publish Locally**——**✅ 已實測驗證，不需要完整 Arrangement，`SAP_BR_DEVELOPER` 衍生角色＋已本機 Publish 的 Scenario 就足夠讓 UCON 放行** | 開發者自己 |
| **外部系統呼叫**（Postman／React Native／其他系統對接，ABAPer 常見的真實工作）| 除了 Communication Scenario，還要 **Communication System**（登記呼叫方身分）＋**Communication User**（技術帳號，認證方式可選 Basic Auth／OAuth2ClientCredentials／Client Certificate）＋**Communication Arrangement**（把 Scenario＋System＋User 綁在一起，管理員在 Fiori Launchpad「Communication Arrangements」App 操作）——**這部分沒有實測，仍是官方文件推論** | 外部系統／串接方 |

### Step By Step：在 ADT 建立 Communication Scenario，解開 fe10 的 UCON 403（✅ 已實測成功）

查證到 SAP 官方文件「Creating a Communication Scenario for Unrestriced Access (Developer)」給的精確操作步驟，並已完整實測驗證：

1. 開 Eclipse，切回 BTP Trial 連線，在 Project Explorer 找到套件 **`ZRAPCLOUD`**（`ZI_RC05_NOTE`／`ZRC08_SB` 所在的套件）
2. 右鍵 → **New → Other → ABAP Repository Object**，開出建立精靈
3. 精靈裡選 **Communication Management → Communication Scenario**，Next
4. Name 填 **`ZFE10_NOTE_SCENARIO`**，Description 填一段有意義的文字（例如 `FE10 UCON Fix - Note App Access`），Next
5. Finish 建立傳輸請求
6. 開啟這個 Communication Scenario 編輯器，切到 **Inbound** 頁籤 → 點 **Add** → 搜尋並選取 **`ZRC08_SB`** 產生的 Inbound Service（實測畫面顯示為 `0001 / ZRC08_SB_0001_G4BA / OData V4 / ZRC08_SB`），加進來
7. `Ctrl+S` 存檔、`Ctrl+F3` 啟用——**⚠️ 這一步不能省略**：編輯器加完 Inbound Service 後標題列會顯示「active, locked」，代表還在編輯 Session 裡，這時候直接按 Publish 可能對著舊版本動作、看起來像沒反應；先明確存檔＋啟用，Publish 才會生效
8. 點編輯器右上角 **`Publish Locally`** 按鈕（✅ 確認畫面上真的就是這個名稱，位置在 Communication Scenario 標題列右側）

**✅ 驗收結果（已實測成功）**：完成上面 8 步後，重新拿瀏覽器打開 fe10 部署出來的網址（`https://xxxxxxxx.abap-web.ap21.hana.ondemand.com/sap/bc/ui5_ui5/sap/zfe10_note_app`）——**`Notes (1)` 正常顯示，`403 blocked by UCON` 完全消失**。這證實：

- **自測／瀏覽器存取只需要 Communication Scenario＋Publish Locally，開發者自己在 ADT 就能做完，完全不需要管理員權限**——fe10 原本「需要管理員權限才能解決」的結論已正式更正

**⚠️ `Activate` 跟 `Publish Locally` 各自在做什麼，不要混為一談**：

- **`Ctrl+F3`（Activate）**：跟啟用任何 ABAP Repository 物件（CDS View、Class……）同一套機制，只是讓 Communication Scenario 這個**設計時期定義**（登記了哪些 Inbound Service）本身存檔生效，**不會**去動 UCON 那邊的執行期允許清單
- **`Publish Locally`**：官方文件原文「to make sure that the **required services have been generated**」——這句話代表 Publish 才是真正**產生執行期物件**、把定義裡登記的 Inbound Service **具體註冊成 UCON 認得的端點**的動作，概念上對應「Register Inbound Endpoint」
- **這次操作是存檔→啟用→Publish 三步連續做完才測試，沒有拆開驗證「只做到 Activate、還沒 Publish」是不是就已經生效**——上面的判斷是根據官方文件措辭＋SAP「設計時期物件 vs. 產生的執行期物件」分兩層的一貫設計慣例推論出來的，可信度高但不是 100% 隔離驗證過，如實記錄這個限制

### ⚠️⚠️ 務必分清楚：「Service Binding 的 Preview」跟「部署出來的獨立網址」是完全不同的兩條路，前者測試不能代表後者的 403 已解決

**這一課實測過程中真實踩過的混淆點**：一開始以為 UCON 403 會發生在 Service Binding 的 **Preview**（Eclipse 裡對著 `ZRC08_SB` 按 Preview，或瀏覽器打開 `/sap/bc/adt/businessservices/odata...` 這種網址），結果 Preview 從頭到尾都正常顯示資料，完全沒有 403——**403 其實只發生在 fe10 `npm run deploy` 產生的那個獨立網址**（`/sap/bc/ui5_ui5/sap/zfe10_note_app`）。兩者容易搞混，因為畫面看起來很像（都是同一個 List Report），但走的是完全不同的存取路徑：

| | Service Binding 的 **Preview**（Eclipse／瀏覽器皆可） | fe10 部署出來的**獨立網址**（這一課實際卡住的地方） |
|---|---|---|
| 網址型態 | `/sap/bc/adt/businessservices/odata...`（在 `/sap/bc/adt/` 這個 **ADT 專屬命名空間**底下） | `/sap/bc/ui5_ui5/sap/zfe10_note_app`（獨立的 BSP App 存取路徑，跟 ADT 完全無關） |
| 走的存取管道 | 沿用你 Eclipse 已經登入的 **ADT Session**（開發者本來就有的存取權，這條路本來就不受 UCON 允許清單限制） | 一個全新的、獨立的瀏覽器 HTTP 請求，直接打 ICF，**這裡才是 UCON 允許清單真正檢查的地方** |
| 受不受 UCON 影響 | **不受影響**——Preview 一路都能看到 `Notes (1)` 正常顯示，不代表 403 已經解決 | **受影響**——沒有 Communication Scenario 前一律 403，建完＋Publish Locally 後才正常 |

**教訓**：驗證「UCON 403 是否真的解開」，一定要拿**部署出來的那條獨立網址**親自測，Preview 測試再順利都不能當作證據——這是這一課除錯過程真實走過的彎路，值得記下來，之後任何「懷疑 UCON 擋住了什麼」的情境，第一件事就是先確認自己測的是哪一條路徑。

**跟「搜不到 Business Roles」是兩件獨立的事**：Business Role 掌管的是「哪個 Business User 能存取哪個 App」（fe10 分析過的 Business User 路徑）；Communication Scenario／Arrangement 掌管的是「這個 API 端點本身有沒有被允許對外接受呼叫」（UCON 這道更底層的網路防護）。之前只查了前者、沒查到後者，是這次查證才補上的缺口——也呼應了 ABAPer 實務上很常見的真實工作內容：**幫其他系統（不是 Fiori Launchpad 使用者，是純粹的 API 呼叫方）開一個可以串接的介面**，這條路走的完全是 Communication System／User／Arrangement，跟這一課主體教的 PFCG／Launchpad Designer（給人用瀏覽器點 Tile）是平行、不同的兩件事。

### ⚠️⚠️ 實測證偽：Postman 用個人帳密（Basic Auth）打部署網址，`200 OK` 但不是真的認證成功

**這是一個假設被實測推翻、值得完整記錄的案例**：曾經推測「瀏覽器能用 SSO 登入成功、Communication Scenario 又勾了 `Basic ✓`，那 Postman 拿開發者自己的帳密走 Basic Auth 去打同一個部署網址，應該也能通過」——**實際測試（Postman，Auth Type 選 Basic Auth，帳號 `monica`＋密碼，打 `https://xxxxxxxx.abap-web.ap21.hana.ondemand.com/sap/bc/ui5_ui5/...`）結果是 `200 OK`，但回應內容是一段 HTML／JavaScript 轉址腳本**（設 `fragmentAfterLogin`／`locationAfterLogin`／`signature` 幾個 cookie，然後把瀏覽器導去 `https://abap-public-trial-ap21.authentication.ap21.hana.ondemand.com/oauth/authorize?...`）——**這不是認證成功拿到資料，是系統把這次呼叫當成「未登入」，回傳標準的互動式登入轉址頁面**，Postman 送出的 Basic Auth 表頭完全沒有被拿去驗證。

**原本的推測錯在哪裡**：
1. **Communication Scenario 的 `Supported Authentication Methods` 核取方塊，只有在真正建立 Communication User＋Communication Arrangement 之後才會生效**——目前只做到 Scenario 建立＋Publish Locally（設計時期登記），完全沒有建立任何 Communication User，Basic Auth 這條路根本沒有對應的技術帳號憑證可以核對，系統自然不理會送出的帳密
2. **`/sap/bc/ui5_ui5/...`（`abap-web.*` 網域）這個路徑，設計上就是給瀏覽器互動 SSO 登入用的**——不管你送不送 Basic Auth 表頭，沒有有效 Session／SSO Token 一律導去登入頁，這個路徑根本不會去檢查 Basic Auth 表頭
3. **瀏覽器能成功，靠的是它已經走完（或原本就有）互動式 SSO 拿到的 Session**——這是一條跟 Basic Auth 完全獨立的認證管道，不是因為「Basic Auth 被允許」才成功

**結論**：要讓 Postman 這類外部工具真正呼叫得通，必須完整走一次外部系統的正式流程（Communication System＋Communication User＋Communication Arrangement）——完整 Step by Step 見下一節，留給下次 Session 動手做。

### ❌ 已確認：外部系統存取（Communication User／System／Arrangement）在這個共用帳號上做不到——權限邊界，非操作錯誤（2026-08-20 實測）

**✅ 這次 Session 先確認了 FLP 網址本身**：`https://<租戶>.abap-web.ap21.hana.ondemand.com/sap/bc/ui2/flp#Shell-home`——跟部署出來的 App（`.../sap/bc/ui5_ui5/sap/<app>`）是**同一個網域**，只是路徑換成 `/sap/bc/ui2/flp`，證實 fe10 講義裡「FLP 是被同一套 ICM/ICF serve 出來的另一個 UI5 App」這個架構描述是對的，可以直接用部署網址的主機名稱＋這個路徑推算出來，不需要另外從 BTP Cockpit 找連結（BTP Cockpit 的 Instance 詳細資訊點三個點只有 `View Dashboard`／`Create Service Key` 等選項，沒有直接列出 FLP 連結）。

**❌ 但 `Maintain Communication Users`／`Communication Systems`／`Communication Arrangements` 這三個 App 確認找不到**：在 FLP 右上角搜尋框輸入 `communication`，只找到 1 筆結果 **`System Outbound Communication`**（這是「我方系統呼叫別人」用的 Outbound 方向 App，跟這裡需要的「外部呼叫方打進來」Inbound 方向完全不同，用不上），三個目標 App 完全不在搜尋結果裡。

**結論**：這是跟 `Business Roles`（0 筆結果，已在 fe10/fe11 前段確認過）同一類的**權限邊界**——這個共用 Trial 帳號沒有被授權存取 Communication Management 這個功能區塊，不是操作方式錯誤、也不是這幾個 App 在這個版本不存在（官方文件明確列為 BTP ABAP Environment 標準功能）。**Postman 外部系統存取（Communication User＋System＋Arrangement）這條路，在這個共用帳號上到此為止，不再往下嘗試**——如果之後換成有管理員權限的獨立 BTP 租戶（例如個人申請的 Free-Tier，見 [[cloud-rap-exploration]]），這條路的 Step by Step 仍然有效，可以直接沿用下面保留的步驟說明。

**✅ 查證官方文件確認：為什麼這個帳號沒有、換一個自己申請的帳號大機率會有**——`Business Roles`／`Communication Management` 兩者都需要 Business Role **`SAP_BR_ADMINISTRATOR`**（官方文件「Business Catalogs and Business Roles」明確列出 Communication Systems 對應的角色就是它）。官方「Trial Scope」文件明講一般個人 Trial Account「Access is open to everyone...**You can manage platform users by assigning them role collections**」——代表**你自己申請的個人 Trial／Free-Tier Account，本來就是你一個人的獨立帳號，你自己就是初始管理員**，理論上可以自己把 `SAP_BR_ADMINISTRATOR` 指派給自己。現在連的這個環境瀏覽器上明確標示 **「TRL Shared Trial AP21」**——是一個刻意設計成多人共用的資源池（呼應之前套件清單裡混著全球陌生學習者物件的觀察），共用池為了不讓任何一人的管理員操作影響到池子裡其他人，會刻意鎖住管理員層級功能。**這是「共用池」這個特定資源的人為限制，不是「Trial／Free-Tier 帳號類型」本身的技術限制**——這個推論沒有實際申請新帳號驗證過，如果之後有機會用個人帳號重測，值得回頭補驗證。

<details>
<summary>保留：完整 Step by Step（給未來有管理員權限的租戶用，這個共用帳號無法執行）</summary>

查證到 SAP 官方文件「Configuring Basic Authentication」（**產品明確是 SAP BTP ABAP environment**，跟這次情境完全對應，非猜測），逐欄位列出 Basic Auth 情境下 Communication User／System／Arrangement 的建立步驟。

**Step 1：`Maintain Communication Users` App（Fiori Launchpad 管理類 App）→ New**

| 欄位 | 填入值 |
|---|---|
| User Name | `ZFE10_POSTMAN_USER` |
| Description | `FE10 UCON Postman Test` |
| Password | 自訂或讓系統產生（**記下來，Postman 會用到**） |

**Step 2：`Communication Systems` App → New**

*General Data*
| 欄位 | 填入值 |
|---|---|
| System ID | `ZFE10_POSTMAN_SYS` |
| System Name | `FE10 Postman Test System` |

*Technical Data*
| 欄位 | 填入值 |
|---|---|
| General: Inbound Only | ✅ 勾選（我們只需要「別人打進來」，不需要「這個系統打出去」） |

*Users for Inbound Communication*
| Authentication Method | User Name/Client ID |
|---|---|
| User ID and Password | `ZFE10_POSTMAN_USER`（Step 1 建立的那個） |

**Step 3：`Communication Arrangements` App → New**

| 欄位 | 填入值 |
|---|---|
| Scenario ID | `ZFE10_NOTE_SCENARIO`（fe11 前面已經建立、Publish Locally 過的那個） |
| Arrangement Name | `ZFE10_POSTMAN_ARR` |
| Communication System | `ZFE10_POSTMAN_SYS` |
| Inbound Communication: User Name | `ZFE10_POSTMAN_USER` |
| Inbound Communication: Authentication Method | User ID and Password |

**⚠️ 關鍵**：存檔後，畫面上的 **Inbound Services** 區塊會直接顯示這個 Service 的**正確存取 URL**——官方文件特別強調「Always use the URLs provided in this section when configuring the calling service」（不同認證方式／不同使用者類型，URL 可能不一樣，**不要沿用 fe10 部署印出的那個網址，也不要憑印象拼網址，一律用這裡顯示的為準**）。

**Postman 測試**：
1. Auth Type 改選 **Basic Auth**
2. Username／Password 填 **`ZFE10_POSTMAN_USER`** 跟 Step 1 設定的密碼（**不是**你自己的開發者帳號 `monica`——這是這次跟上次實驗最大的差異，上次用 `monica` 失敗，這次改用專門建立的技術帳號）
3. 網址改用 Communication Arrangement 畫面上 **Inbound Services** 顯示的那一條
4. **預期結果**：如果這整條理論成立，這次應該能拿到真正的 OData JSON 資料（不再是 HTML 登入轉址頁）——如果還是失敗，那也是有價值的結果，代表理論裡漏了什麼，一樣要如實記錄

**這一組物件命名也要記進物件清單**：`ZFE10_POSTMAN_USER`（Communication User）／`ZFE10_POSTMAN_SYS`（Communication System）／`ZFE10_POSTMAN_ARR`（Communication Arrangement），全部在 BTP Trial、套件概念上依附於 `ZFE10_NOTE_SCENARIO`（Communication User/System 本身不屬於特定套件，是租戶層級的物件）。

**⚠️ 這組物件在這個共用帳號上實際上沒有建立成功**——上面的 Step by Step 是查證官方文件產出的理論流程，因為 Communication Management App 搜尋不到（見本節開頭），這幾步從未真的執行過，`ZFE10_POSTMAN_USER`／`ZFE10_POSTMAN_SYS`／`ZFE10_POSTMAN_ARR` 只是規劃階段的命名，不是已存在的物件。

</details>

### ⚠️⚠️ 更正：部署只有一個網址，「該打 abap.\* API 網域」這句話講錯了

**上一段講義原文寫「應該打的是底層 OData Service 網址（`abap.*` API 網域），不是部署出來的 UI5 App 靜態網址（`abap-web.*`）」——這句話是錯的，已經更正**。

- `npm run deploy` **只印出一個網址**：`https://xxxxxxxx.abap-web.ap21.hana.ondemand.com/sap/bc/ui5_ui5/sap/zfe10_note_app`，沒有第二個
- `abap.*` 網域是 `ui5.yaml`（**本機開發用**）裡 `fiori-tools-proxy` 的 `backend.url`，給 `npm start` 本機開發代理走 OAuth Reentrance Ticket 用的——**這是開發工具連線用的網域，不是部署出來的 App 自己會用到的**
- 部署出來的 App，`manifest.json` 的 `mainService.uri` 是**相對路徑**（`/sap/opu/odata4/sap/zrc08_sb/srvd/sap/zrc08_sd/0001/`，前面沒有網域）——照標準 HTTP 行為，瀏覽器會用「目前頁面所在的網域」去補齊，也就是說**這個 App 自己發出的 OData 請求，實際上也是打 `abap-web.*`，不是另一個 `abap.*` 網域**
- **這個更正是根據相對路徑的標準行為推論的，沒有實際打開瀏覽器開發者工具（F12）→ Network 分頁親眼確認過**——想徹底驗證的話，這是最直接的方法，也是這一課的教訓之一：網域／網址這類細節，能實測確認就不要單靠推論

### 這一課的後端：沿用 rap04 留下的 `ZRAPT01_SB3`

不重新部署，直接用 RAP 課程 rap04（`.claude/rules/sap-adt-mcp.md` 第 40.9 節）留下的 `ZRAPT01_SB3`——**已查證確認仍是 `srvb:published="true"`**，OData V2，Service Definition `ZRAPT01_SD`（`expose ZI_RAPT01 as Root;`），CDS View `ZI_RAPT01`（`root_id`／`descr` 兩個欄位），套件 `$TMP`。省下重新建 RAP 物件的時間，把這一課的力氣全部放在 Launchpad／Role 這個新主題上。

### Step 1：VS Code 連地端系統，產生一個小 App（跟 fe01 的差異：Basic Auth，不是 Reentrance Ticket）

1. `Ctrl+Shift+P` → `Fiori: Open Application Generator`
2. Template 選 **List Report Page**
3. Data Source 選 **`Connect to a System`** → **New System**
4. **System Type 選 `ABAP On Premise`**（⚠️ 不是 fe01 用的 `ABAP Environment on SAP Business Technology Platform`——地端系統沒有 Reentrance Ticket 這回事，走的是傳統帳號密碼）
5. System URL 填地端系統的對外網址（`https://erpdemo01.itts.com.tw:44300`，這門課程既有系統，見 CLAUDE.md 第 15 節），Client 填 `130`
6. 認證方式選 **Basic Authentication**，輸入帳密（**不要**把密碼寫進任何設定檔存進版控，這點延續整個專案的安全慣例）
7. Service 選 `ZRAPT01_SB3 > ZRAPT01_SD (0001)`，Main Entity 選 `Root`
8. Module Name 填 `fe11_launchpad_role`，Project Folder Path 指到 `src/ABAP_Training_Fiori_Elements/`，其餘保留預設
9. 建議先補一個極簡的 Metadata Extension（`@UI.headerInfo`／`@UI.lineItem`／`@UI.identification`，`root_id`／`descr` 兩個欄位）讓畫面不要只有技術欄位名——這步驟做法完全比照 fe08／fe09，不重複贅述

### Step 2：`manifest.json` 加 Launchpad Intent（`fiori add flp-config`）

`Ctrl+Shift+P` → **`Fiori: Add Launchpad Configuration`**（對應底層指令 `sap.ux.appGenerator.launchFlpConfig`），精靈會問：

| 欄位 | 這一課填的值 |
|---|---|
| Semantic Object | `RapTestRoot` |
| Action | `manage` |
| Title | `RAP Test Root` |
| Icon | 任選一個 `sap-icon://` 值，例如 `sap-icon://task` |

存檔後 `manifest.json` 會多出這段（**這段 JSON 是這一課真正的教學重點之一，值得逐行看懂**）：

```json
"sap.app": {
  "crossNavigation": {
    "inbounds": {
      "RapTestRoot-manage": {
        "signature": { "parameters": {}, "additionalParameters": "allowed" },
        "semanticObject": "RapTestRoot",
        "action": "manage",
        "title": "{{flpTitle}}",
        "subTitle": "{{flpSubtitle}}",
        "icon": "sap-icon://task"
      }
    }
  }
}
```

**這就是「Semantic Object + Action」在程式碼層的宣告**——`RapTestRoot`＋`manage` 合起來構成一個 **Intent**（`#RapTestRoot-manage`），之後 Launchpad Designer 裡的 Target Mapping、以及任何想「導航到這個 App」的其他 App，都是靠這組 Intent 字串互相辨識，不是靠硬記網址。

### Step 3：部署（沿用 fe10 教過的機制，這次是 Basic Auth 目標）

`Ctrl+Shift+P` → `Fiori: Add Deployment Configuration` → Target 選 `ABAP` → 選 Step 1 建立的地端系統連線 → SAPUI5 ABAP Repository 填 **`ZFE11_ROOT_APP`** → Package 填 **`$TMP`**（沿用 `ZRAPT01_SB3` 同一個套件，訓練物件集中管理）→ 完成後 `npm run deploy`。

**跟 fe10 的關鍵差異**：這次 `ui5-deploy.yaml` 的 `target` 底下會是 **`auth: basic`**（不是 `authenticationType: reentranceTicket`），部署當下可能會跳出帳密輸入提示（`credentials` 沒有明確寫在檔案裡時，工具會用系統的安全儲存機制或互動提示，見 fe10 講義查證過的 `ux-ui5-tooling` 文件說明）。部署成功後一樣會印出存取網址，這次網址會是 `https://erpdemo01.itts.com.tw:44300/sap/bc/ui5_ui5/sap/zfe11_root_app/...` 這種形式——**⚠️ `$TMP` 套件的物件理論上不可傳輸，但單純部署到本機系統的 BSP 物件不受這條限制**（`$TMP` 限制的是「跨系統傳輸」，不影響「在這個系統上被建立、被存取」）。

### Step 4：Fiori Launchpad Designer（`/UI2/FLPD_CUST`）——建 Catalog／Target Mapping／Tile

SAP GUI 執行 `/UI2/FLPD_CUST`：

1. **Catalogs** 頁籤 → 右鍵 → **New Catalog**，Title／ID 填 `Z_FE11_CATALOG`
2. 對著這個新 Catalog → **New Target Mapping**：
   - **Semantic Object**：`RapTestRoot`
   - **Action**：`manage`
   - **Application Type**：**SAPUI5 Fiori App**
   - **Title**：`RAP Test Root`
   - **URL**：指到部署出來的 BSP App（`/sap/bc/ui5_ui5/sap/zfe11_root_app`）
   - **Additional Information**：`SAPUI5.Component=<sap.app.id，去 manifest.json 查>`（這是 Launchpad 執行期要載入哪個 UI5 Component 的關鍵設定，不是隨便填的路徑，一定要跟 `manifest.json` 裡 `sap.app.id` 的值一致）
3. 對著這個 Catalog → **New Tile** → 選 **App Launcher - Static**，Semantic Object／Action 選剛剛那組（`RapTestRoot`／`manage`），系統會自動帶出 Title／Icon（因為跟 manifest.json 的 Inbound 宣告對上了）
4. **Groups** 頁籤 → 右鍵 → **New Group**，Title／ID 填 `Z_FE11_GROUP`，把剛剛的 Tile 拖進這個 Group

**⚠️ 這幾個物件（Catalog／Group）通常需要傳輸請求**（不像 `$TMP` 那樣純本機）——沿用你既有的傳輸請求即可，這門課不特別示範怎麼建立新的傳輸請求（見 CLAUDE.md「開發流程」既有規範）。

### Step 5：PFCG——把 Catalog/Group 掛進角色選單，指派給使用者

1. `PFCG` → 建一個新角色 **`Z_FE11_TEST`**（一看名字就知道是這門課的訓練用角色，方便之後回收）
2. **Menu** 頁籤 → 右鍵 → **SAP Fiori Tile Catalog**（或類似選項，依系統版本選單措辭可能略有差異）→ 選 `Z_FE11_CATALOG`，**確認 `Include Applications` 這個核取方塊有勾選**（官方文件明確強調這一步不能漏，漏了 Catalog 底下的 App 不會真的被授權）
3. 同樣方式加入 `Z_FE11_GROUP`
4. **Authorizations** 頁籤：正常產生／維護權限值（這個測試 App 的 Service `ZRAPT01_SB3` 用的是 `@AccessControl.authorizationCheck: #NOT_REQUIRED`，理論上不需要額外的業務權限物件，但 Fiori Launchpad 本身的基礎權限物件——如 `S_START`、`S_SERVICE`——通常已經包在標準的最終使用者角色範本裡，這門課不深入展開權限物件細節，維持這一課的重點在 Launchpad／Role 機制本身）
5. **User** 頁籤：把你自己的使用者帳號加進去（這一課用同一個帳號驗證即可，不強求真的換一個帳號登入）
6. 存檔、產生 Profile（`PFCG` 標準流程：Save → Generate）

### Step 6：驗證——登入 Fiori Launchpad，確認 Tile 真的出現

SAP GUI 執行 `/UI2/FLP`（或直接瀏覽器打 `https://erpdemo01.itts.com.tw:44300/sap/bc/ui2/flp`），登入後應該要在 `Z_FE11_GROUP` 底下看到剛剛設定的 Tile（標題 `RAP Test Root`），點下去要能開啟 `ZFE11_ROOT_APP`（List Report，`Root` entity，`root_id`／`descr` 欄位）。

**這是這一課、也是 fe10 沒能完成的最終驗收畫面**——跟 fe10 的差別在於：fe10 是「有部署好的 App，但沒有 Tile／沒有授權，只能貼裸網址且被 UCON 擋下」；這一課是完整走過「部署→建 Tile→授權→登入 Launchpad 點 Tile 進去」全部四步，缺一步都不算完整。

## 學習目標

- 能講出 Intent-Based Navigation（Semantic Object + Action）是 BTP／On-Premise 兩套 Launchpad 模型**共用**的核心概念，只是後台授權機制不同
- 能操作 `Fiori: Add Launchpad Configuration`，看懂它在 `manifest.json` 加的 `crossNavigation.inbounds` 區塊每個欄位的意義
- 能在 SAP GUI `/UI2/FLPD_CUST` 完整建立 Catalog／Target Mapping／Tile／Group
- 能在 `PFCG` 把 Fiori Catalog/Group 掛進角色選單（知道 `Include Applications` 這個核取方塊不能漏）、指派給使用者
- 能講出 fe10（BTP，卡在 UCON／權限）跟 fe11（On-Premise，完整走通）的對照：同一個「讓別人能用」的目標，两套環境的落地方式完全不同，但概念模型相通
- 能講出 BTP 環境 `Communication Scenario`（開發者，ADT 建立＋Publish）跟 `Communication Arrangement`（管理員，綁定 Communication System＋User）的分工，知道這是解 UCON 403 的正規流程，也知道這跟 Business Role（管誰能用 App）是兩條獨立的授權鏈
- 能講出「自己測試／瀏覽器存取」跟「外部系統（Postman／React Native）呼叫」在 BTP 環境需要的物件不完全一樣——後者多了 Communication System／User 這一層技術帳號設定
- 能講出 BTP ABAP Environment 的 Fiori Launchpad 網址規律：跟部署出來的 App 同一個網域（`abap-web.<region>.hana.ondemand.com`），只是路徑換成 `/sap/bc/ui2/flp`，不需要另外從 BTP Cockpit 找連結
- 能講出這個共用 Trial 帳號的權限邊界：`Business Roles`（fe10 已確認）跟 `Communication Management`（`Maintain Communication Users`／`Communication Systems`／`Communication Arrangements`，這一課確認）都搜尋不到，代表外部系統存取（Postman）這條路在共用帳號上做不到，需要換成有管理員權限的獨立租戶才能走完
- **能精準分辨 `SAP_BR_ADMINISTRATOR` 這個名稱只在 BTP 那一列有意義**：它是 BTP ABAP Environment 的 Business Role（透過 `Maintain Business Users` App 指派），`Business Roles`／`Communication Management` 都需要這個角色；地端 On-Premise 的 `/UI2/FLPD_CUST`＋`PFCG` 操作靠的是完全不同機制（傳統 `S_USER_*` 權限物件＋`SU01`），不要把兩套系統的管理員權限概念混為一談——這是這一課「兩套模型的對照」表格新增的一列，也是最容易搞混的地方

## 物件清單

| 物件 | 系統 | 說明 |
|---|---|---|
| `ZRAPT01_SB3`／`ZRAPT01_SD`／`ZI_RAPT01` | On-Premise，`$TMP` | rap04 既有物件，沿用當後端 |
| `ZFE11_ROOT_APP` | On-Premise，`$TMP` | 這一課部署出來的 BSP App |
| `fe11_launchpad_role`（前端專案） | 本機 | VS Code 專案資料夾，含 `crossNavigation` 設定 |
| `Z_FE11_CATALOG`（Fiori Catalog） | On-Premise | 含 1 個 Target Mapping、1 個 Tile |
| `Z_FE11_GROUP`（Fiori Group） | On-Premise | 含上面那個 Tile |
| `Z_FE11_TEST`（PFCG Role） | On-Premise | 掛 Catalog＋Group，指派給使用者 |
| `ZFE10_NOTE_SCENARIO`（Communication Scenario） | BTP Trial，`ZRAPCLOUD` | 補課用，測試能否解開 fe10 的 UCON 403，含 `ZRC08_SB` 的 Inbound Service |

## 動手練習

**輪到你了**：

1. 幫這個 Semantic Object（`RapTestRoot`）再加一個 Action（例如 `display`，唯讀用途），對應到同一個 App 但用不同的 URL Parameter（例如 `?sap-ui-app-id-hint=readonly`），想一想這在實務上可以用來做什麼情境（提示：同一份資料，給不同角色不同的操作權限）
2. 試著把 fe08 或 fe09 部署出去的 BTP App（如果你手上還有可用的 BTP 環境）也走一次 Semantic Object 宣告，比較兩邊 `manifest.json` 的 `crossNavigation.inbounds` 寫法是不是逐字一樣
3. 查一下 `PFCG` 角色選單裡「Include Applications」這個核取方塊沒勾選會發生什麼事——你可以故意建一個沒勾的測試角色，指派給自己，看 Launchpad 上 Tile 是不是真的不會出現
4. **✅ 已驗證，練習重現一次加深印象**：照上面「補充」段落的 Step by Step，在 BTP Trial 對 `ZFE10_NOTE_APP` 建立 `ZFE10_NOTE_SCENARIO` 並本機 Publish——這一步已經實測解開了 fe10 的 `403 blocked by UCON`，親自動手做一次體會「開發者層級就能解決 UCON」這件事，同時練習分辨 Preview 網址跟部署網址的差異

## 驗證方式

使用者在地端系統完整走完部署（Basic Auth）→ Launchpad Designer（Catalog／Tile／Group）→ PFCG（角色＋指派）→ 登入 Fiori Launchpad 確認 Tile 出現並能開啟 App。Claude 端這一課沒有獨立的後端查詢驗證手段（跟 fe10 學到的教訓一致：這類 UI/Launchpad 層的設定沒有對應的 MCP 查詢工具），完全依賴使用者截圖回報。

## 思考題

1. 這一課用的是「一個帳號身兼開發者跟管理員」，實務上大型企業通常會有專職的 Basis／安全管理員負責 PFCG／Launchpad Designer 這塊，跟開發團隊是分開的。想一想：如果開發者跟管理員是不同人，這一課的六個步驟裡，哪些應該是開發者做、哪些應該是管理員做？這個切分跟 fe10 查證過的 BTP「IAM App／Business Catalog 是開發者層級，Business Role 是管理員層級」的切分邏輯像不像？
2. fe10 的 App（`ZFE10_NOTE_APP`）部署在 BTP、卡在 UCON；這一課的 App（`ZFE11_ROOT_APP`）部署在地端、完整打通。如果之後真的要幫 BTP 那邊也打通，比對這一課學到的「Semantic Object/Action 概念相通、只是後台機制不同」，你覺得 BTP 那邊除了 Business Role，會不會也有一個等同「Launchpad Designer」角色的工具？（提示：回頭看 fe10 查證時讀到的「Launchpad Space／Page」這個詞）
3. 這一課查到 BTP 的 `Communication Scenario` 是「開發者在 ADT 建立＋Publish」，`Communication Arrangement` 才是「管理員綁定 System／User」——這個「開發者定義能力、管理員授權對象」的分工模式，跟地端 `Fiori Launchpad Designer`（開發者定義 Catalog/Tile）＋`PFCG`（管理員／有權限的人指派角色）是不是同一種設計哲學？如果是，你覺得為什麼 SAP 在完全不同世代、不同技術棧的兩套系統裡，會不約而同採用類似的「內容與授權分離」設計？

## 答案

地端物件：`Z_FE11_CATALOG`／`Z_FE11_GROUP`／`Z_FE11_TEST`（PFCG Role）／`ZFE11_ROOT_APP`（BSP App），皆建立於 On-Premise 系統 `S4H`／Client `130`，套件 `$TMP`。

BTP 補課物件：`ZFE10_NOTE_SCENARIO`（Communication Scenario，套件 `ZRAPCLOUD`）——**已實測驗證成功解開 fe10 的 `403 blocked by UCON`**，開發者在 ADT 建立＋加入 Inbound Service＋Publish Locally 即可，不需要管理員權限。

外部系統存取（Postman，Communication User／System／Arrangement）：**❌ 已確認在這個共用帳號上做不到**——FLP 搜尋框搜 `communication` 只找到 `System Outbound Communication`（Outbound 方向，用不上），`Maintain Communication Users`／`Communication Systems`／`Communication Arrangements` 三個都不在結果裡，跟 `Business Roles` 同一類權限邊界，`ZFE10_POSTMAN_USER`／`ZFE10_POSTMAN_SYS`／`ZFE10_POSTMAN_ARR` 從未真正建立。如實記錄成限制，這個測試項目到此為止。

**權限概念總結**：這一課兩套系統都需要「管理員層級」的存取，但完全是兩套不同機制，不能混用名詞——BTP 那一半（`Business Roles`／`Communication Management`）需要的是 Business Role `SAP_BR_ADMINISTRATOR`（雲端 IAM 模型，這個共用帳號沒有）；On-Premise 那一半（`/UI2/FLPD_CUST`＋`PFCG`）需要的是傳統 `S_USER_*` 權限物件（`SU01` 指派 PFCG 角色，使用者在地端系統本來就有）。
