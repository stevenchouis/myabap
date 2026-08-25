# Fiori Elements 開發課程 16（延伸篇）：Overview Page——跨服務儀表板

> **環境**：BTP ABAP Environment Trial（沿用 fe01／fe08 已建立的兩個既有 Service Binding，**不新增任何 ABAP 物件**）

## Lecture

### 為什麼補這一課

fe01～fe15 全部集中在 **List Report／Object Page／Custom Page** 這條主線，這是實務上最常用的路線沒錯，但 Fiori Elements 官方定義的標準 Floorplan 其實還有 **Overview Page（OVP）**、**Analytical List Page（ALP）**、**Worklist** 三種這門課完全沒碰過。逐一評估投入產出比之後：

- **ALP** 官方文件確認在 OData V4 世代已經被整併進 `sap.fe` 的 List Report 範本（掛一組 Chart Annotation 就能達成），技術上跟 fe03 教過的 List Report 深化高度重疊，不值得獨立開課。
- **Worklist** 嚴格說是比 Fiori Elements 更早的 SAPUI5 Freestyle 範本類型，現在的效果直接用 List Report 掛 Action 按鈕就能取代，市場上新專案幾乎不會特地選它。
- **Overview Page** 是三者裡**唯一在架構上真正獨立、且有一個其他 Floorplan 完全做不到的能力**——這正是這一課要教的重點。

### Overview Page 的本質：卡片容器，不是單一實體頁面

List Report／Object Page／ALP 的共同限制，官方文件講得很明白：

> "SAP Fiori elements only supports a single service as the service behind the data for all its controls." （[Prerequisites for Using SAP Fiori Elements for OData V4](https://ui5.sap.com/#/topic/f2344b5e78164b2b9c27ef8b068f295c)）

這幾種 Floorplan 的整個頁面（篩選列、表格、Object Page 導覽）都是**圍繞著單一 EntitySet 的 Metadata 生成的**，所以天生只能綁一個 Service。

**Overview Page 完全不是這種架構**——它是一個「卡片容器」，容器本身不綁定任何實體，每一張卡片（Card）各自獨立宣告自己要用哪個 `model`、哪個 `entitySet`。官方文件直接證實了這個差異：

> "Use the OVP to develop applications for monitoring and decision-making scenarios. You can aggregate data from multiple entities into cards and enable navigation to the relevant applications for further action. The OVP supports both OData V2 and OData V4, and you can use both services within the same [app]." （[How Overview Page Differs from Other Floorplans](https://ui5.sap.com/#/topic/c64ef8c6c65d4effbfd512e9c9aa5044)）

換句話說：**這門課到目前為止建立的每一個 Fiori App（fe01 的 Note、fe08 的 Task、fe12 的 Order），全部都是「各自獨立、互不相干」的應用**——List Report／Object Page 的架構限制決定了它們永遠不可能被塞進同一個 App。但 Overview Page 可以把這三個原本毫無關聯的服務，用「一頁多卡片」的方式拼進同一個儀表板，這是這門課第一次真正示範「聚合多個既有系統」的能力，也是企業導入 Fiori 時常見的「主管儀表板」場景。

### 卡片如何綁定不同服務：關鍵在 `settings.model`

manifest.json 的 `sap.ovp.cards` 底下，每張卡片都有自己的 `model` 屬性，指向 `sap.ui5.models` 裡的某一個 model 名稱：

```json
"sap.ovp": {
    "globalFilterModel": "ZCD204_EPM_DEMO_SRV",
    "globalFilterEntitySet": "SalesOrder",
    "cards": {
        "card00": {
            "model": "ZCD204_EPM_DEMO_SRV",
            "template": "sap.ovp.cards.v4.stack",
            "settings": { "title": "{{card00_title}}" }
        },
        "card01": {
            "model": "ZCD204_EPM_DEMO_SRV",
            "template": "sap.ovp.cards.v4.table",
            "settings": { "title": "{{card01_title}}" }
        }
    }
}
```
（節錄自官方 [Overview Page Card](https://help.sap.com/docs/SAPUI5/b2f662dd9d7a4ec680056733050b4d34/74332d5d829b413f9d7c0950dc6a71d2.html) 文件範例）

範例裡兩張卡片剛好用同一個 `model`，但**沒有任何規則要求卡片之間的 `model` 要一樣**——只要 `sap.ui5.models` 裡定義了兩個（或更多）指向不同 OData Service 的 model，各卡片各自填自己要用的 `model` 名稱即可。這一課要做的動手練習，就是把 fe01 的 Note 服務跟 fe08 的 Task 服務，各自掛一張卡片，塞進同一個 Overview Page。

⚠️ **有得必有失**：`globalFilterModel`／`globalFilterEntitySet`（頁面最上方的共用篩選列）只能指向**一個**服務的**一個**實體，套用篩選時「只對跟這個實體共用同名欄位的卡片生效」——如果 Note 跟 Task 完全沒有同名欄位，全域篩選列對其中一張卡片就會是無效的（這是這一課動手練習後半段要觀察、思考的重點）。

### V4 卡片型版命名規則

```
sap.ovp.cards.v4.<cardType>   ← OData V4 用
sap.ovp.cards.<cardType>      ← OData V2 用（少一段 v4）
```

常見 `<cardType>`：`list`（列表卡）、`table`（表格卡）、`stack`（QuickView／計數卡）、`charts.analytical`、`charts.bubble`（分析圖表卡，需要額外的 `DataPoint`／`Chart`／`PresentationVariant` Annotation，這一課先不碰，留給「思考題」討論）。

## 動手操作：VS Code Step by Step

### Part A：用 Generator 產生 Overview Page 骨架

1. Command Palette（`Ctrl+Shift+P`）→ `Fiori: Open Application Generator`
2. **Template Selection**：Template Type 選 **SAP Fiori**，畫面應該會看到 List Report Page／Worklist Page／Analytical List Page／Object Page／**Overview Page** 幾個選項——選 **Overview Page**
3. **Data Source**：跟 fe01 一模一樣的流程——`Connect to a System` → 選之前存好的系統（例如 fe01 建立的那個），不需要重新走 Reentrance Ticket 登入（除非連線已過期）
4. **Service**：搜尋並選 **`ZRC08_SB > ZRC08_SD (0001)`**（fe01 用過的 Note 服務——選它當這個 App 的主要服務／全域篩選來源）
5. 後續畫面（Entity Selection／Project Attributes）請照精靈實際顯示的欄位填寫；**Overview Page 的精靈流程可能跟 fe01 的 List Report 精靈有些欄位差異（例如不一定會問 Main Entity）**，如果畫面跟這裡預期的不一樣，直接照精靈給的欄位填，事後截圖告訴我，我們一起校正這份講義
6. Project Folder Path 指定到 `src/ABAP_Training_Fiori_Elements/`，Module Name 建議 `fe16overviewpage`，按 **Finish**

產生完成後，`cd` 進新專案資料夾執行 `npm start`，瀏覽器應該會看到一個**空的** Overview Page——這是正常的，接下來的 Part B 才是這一課的重點。

✅ **已由使用者實機驗證確認**（2026-08-25）：畫面實際顯示的是 `sap.ovp` 框架的標準「零卡片」提示畫面——大圖示＋「**You've hidden all the cards**」文字＋「**Go to Manage Cards**」按鈕。這是 `sap.ovp.cards` 目前是空物件時的預期畫面（措辭雖然寫「hidden」，但語意上就是「目前沒有任何卡片可以顯示」，不是真的有人手動隱藏過），代表 Template 確實正確選到 **Overview Page**（不是 List Report），Generator 骨架產生成功——接下來 Part B 手動加卡片才會讓畫面真正有內容。

### Part B：手動加第二個服務＋第二張卡片

1. 打開新專案的 `webapp/manifest.json`，在 `sap.app.dataSources` 底下**新增**一個指向 Task 服務的 dataSource（跟 `mainService` 平行）：

   ```json
   "taskService": {
     "uri": "/sap/opu/odata4/sap/zrc01_sb/srvd/sap/zrc01_sd/0001/",
     "type": "OData",
     "settings": {
       "odataVersion": "4.0",
       "localUri": "localService/taskService/metadata.xml"
     }
   }
   ```

2. 在 `sap.ui5.models` 底下**新增**一個 model 指向這個新 dataSource：

   ```json
   "taskModel": {
     "dataSource": "taskService",
     "settings": {
       "operationMode": "Server",
       "autoExpandSelect": true
     }
   }
   ```

3. 找到 Generator 產生的 `sap.ovp` 區塊——⚠️ **這個範本的 Generator 實際產生的骨架，比想像中完整很多**，已經自動幫你設好：

   ```json
   "sap.ovp": {
     "globalFilterModel": "mainModel",
     "globalFilterEntitySet": "Note",
     "containerLayout": "resizable",
     "enableLiveFilter": true,
     "considerAnalyticalParameters": false,
     "cards": {},
     "globalFilterControlType": "MacroFilterBar"
   }
   ```

   幾個實測才確認的細節：
   - **這個 OVP 專案的主要服務 model 名稱是 `mainModel`，不是 fe01/fe08 那種匿名 `""`**——`@sap/generator-fiori:ovp` 這個範本（跟 List Report 用的 `:lrop` 範本不同）習慣給主 model 一個有意義的名字，`globalFilterModel` 也正確指到 `"mainModel"`。**這代表卡片的 `model` 要填 `"mainModel"`，不是 `""`**（下面已更正）。
   - `globalFilterModel`／`globalFilterEntitySet`／`containerLayout` **Generator 已經自動填好**，不需要自己加
   - `"globalFilterControlType": "MacroFilterBar"`——這是上一輪查證時只在網路摘要看到、沒抓到官方文件出處的設定，這次直接在真實產生的專案裡驗證確認存在

   **你只需要在既有的 `"cards": {}` 裡面補上兩個卡片項目**（不要整段複製貼上一個新的 `"sap.ovp": {...}"`包在外面，那會變成巢狀重複——這是這次動手操作實際踩到的坑，已經修正）：

   ```json
   "cards": {
     "card_note": {
       "model": "mainModel",
       "template": "sap.ovp.cards.v4.list",
       "settings": {
         "title": "{{card_note_title}}",
         "entitySet": "Note"
       }
     },
     "card_task": {
       "model": "taskModel",
       "template": "sap.ovp.cards.v4.table",
       "settings": {
         "title": "{{card_task_title}}",
         "entitySet": "Task"
       }
     }
   }
   ```

4. 在 `webapp/i18n/i18n.properties` 補上用到的兩個 key（`card_note_title`／`card_task_title`），內容自訂（例如「最新 Note」／「待處理 Task」）。

5. 存檔，重新整理瀏覽器（或重啟 `npm start`）——預期看到**兩張卡片並排**：一張列出 Note 資料（List Card），一張列出 Task 資料（Table Card），分別來自兩個完全獨立的 Service Binding。

   ✅ **已由使用者實機驗證確認**（2026-08-25）：畫面正確顯示兩張並排卡片——「**最新 Note**」（List Card，逐列顯示 `RC05TEST04`／`testb6`／`testdfs` 等真實 Note 資料，含 `titlea`/`titleb` 欄位值）、「**待處理 Task**」（Table Card，顯示 `RC02TEST03`「Action test task」／`RC07TEST01`「OData create test」，含 Status 欄位顯示 `D`）。全域篩選列也正確渲染成 `FilterBar` Building Block，顯示 `FILTERBAR_EDITING_STATUS`（Draft 相關技術欄位）與 `note_id` 兩個篩選欄位——證實 fe16 全課的核心主張（一個 App、兩個獨立 Service Binding、各自的卡片）完整跑通。

6. 找到最上方的**全域篩選列**，試著用 `Note` 相關欄位篩選，觀察兩張卡片的反應——預期只有 Note 卡片會被篩選到，Task 卡片不受影響（因為 `globalFilterEntitySet` 目前指向 `Note`，Task 沒有同名欄位）。

## 學習目標

- 能說出 Overview Page 跟 List Report／Object Page／ALP 最根本的架構差異：後者整頁綁死單一 Service 的 Metadata，OVP 是卡片容器，每張卡片各自宣告 `model`
- 能講出官方文件明確記載「OVP 可以在同一個 App 內混用多個 OData Service（甚至可以 V2／V4 混用）」這個其他 Floorplan 做不到的能力，並知道具體是靠 `sap.ui5.models` 定義多個 model、每張卡片各自 `settings.model` 指定來實現
- 知道 `sap.ovp.cards.v4.<cardType>`（V4）跟 `sap.ovp.cards.<cardType>`（V2）的命名差異
- 理解全域篩選列（`globalFilterModel`／`globalFilterEntitySet`）只對「跟這個實體共用同名欄位」的卡片生效，這是把互不相干的服務拼在一起時必然要面對的取捨

## 物件清單

**這一課沒有新增或修改任何 ABAP 物件**——完全沿用既有的兩個 Service Binding：

| 物件 | 來源 | 角色 |
|---|---|---|
| `ZRC08_SB`／`ZRC08_SD`（曝露 `ZI_RC05_NOTE`） | fe01 | Overview Page 的主要服務，`Note` 卡片來源，也是全域篩選來源 |
| `ZRC01_SB`／`ZRC01_SD`（曝露 `ZC_RC01_TASK`） | fe08 | 第二個服務，手動掛進同一個 App 的 `Task` 卡片來源 |
| `fe16overviewpage` | 這一課新建 | 唯一新增的東西是**本機前端專案**，不是 ABAP 物件 |

## 動手練習

1. 再加一張 **Stack 卡**（`sap.ovp.cards.v4.stack`，QuickView／計數卡），指向 Task 或 Note 任一服務，觀察它跟 List／Table 卡在視覺呈現上的差異（提示：Stack 卡通常用來顯示「總筆數」這類彙總資訊，不是逐列資料）
2. 把 `containerLayout` 從 `resizable` 改成 `fixed`，重新整理觀察卡片版面差異（提示：官方文件說 `fixed` 已經在 SAPUI5 1.142 起被棄用，`resizable` 才是現在的預設，這個練習純粹是體驗兩者差異，不代表新專案該選 `fixed`）
3. 點卡片右上角的 **More（⋯）**選單，找 **Manage Cards**——這個對話框可以讓使用者自己決定要不要顯示某張卡片，試著隱藏 Task 卡片，重新整理頁面確認這個設定有沒有被記住
4. 想一想：如果要讓全域篩選列同時對 Note 跟 Task 兩張卡片都有效，你會怎麼設計？（提示：篩選列的機制是「比對同名欄位」，两个 Entity 需要有欄位「語意相同、名稱也相同」——這代表要嘛在其中一個 CDS View 上加一個同名欄位，要嘛接受這兩張卡片本來就不該共用同一個全域篩選條件）
5. 對照 fe11 學過的 Fiori Launchpad：如果只是想讓使用者能各自點開 Note App 和 Task App，兩個獨立 Tile 也能做到；想一想在什麼情境下，主管會寧可要一個「兩者資料都看得到的儀表板頁面」，而不是兩個分開的 Tile？

## 驗證方式

✅ **Part A 已由使用者實機驗證確認**（2026-08-25）：

1. ✅ 用 Generator 產生成功，Template 確實是 Overview Page
2. ✅ `npm start` 後瀏覽器能看到 Overview Page 版面（不是 List Report 的表格版面）——實際畫面是 `sap.ovp` 的標準「零卡片」提示畫面（`You've hidden all the cards`），證實骨架正確、只是還沒有卡片

✅ **Part B 已由使用者實機驗證確認**（2026-08-25）：

1. ✅ 手動編輯 manifest.json 後，畫面上同時出現 **Note 卡片**（List Card，真實資料 `RC05TEST04`／`testb6`／`testdfs`）與 **Task 卡片**（Table Card，真實資料 `RC02TEST03`／`RC07TEST01`，含 Status 欄位），兩者資料都正確顯示
2. ✅ 全域篩選列正確渲染成 FilterBar（`FILTERBAR_EDITING_STATUS`／`note_id` 兩個篩選欄位）

⏳ **動手練習 1～3（Stack 卡、Layout 切換、Manage Cards）待驗證**（選做，完成後回報結果）

## 思考題

1. 官方文件說 KPI／分析圖表卡（`sap.ovp.cards.v4.charts.*`）需要額外的 `com.sap.vocabularies.UI.v1.DataPoint`／`Chart`／`PresentationVariant`／`SelectionVariant` Annotation，且要求「資料要能被彙總（aggregation）」。如果想幫 Task 服務加一張「依 Status 分組計數」的分析圖表卡，你覺得後端（`ZI_RC01_TASK`）需要補上什麼？（提示：對照 AMDP／CDS 課程學過的彙總概念，一般 CDS View 要能被當作分析用途，通常需要 `@Analytics.query: true` 或搭配聚合函式的 View）
2. 這一課示範的是「List Report 世界裡兩個各自獨立的 App，被 Overview Page 用卡片方式聚合」。如果反過來，公司已經有一個地端系統用傳統 SAPUI5 freestyle（非 Fiori Elements）開發的舊報表，理論上能不能也塞一張卡進 Overview Page？（提示：查一下 [Creating Custom Cards on the Overview Page](https://ui5.sap.com/#/topic/6d260f7708ca4c4a9ff45e846402aebb) 這份文件）
3. 為什麼 List Report／Object Page／ALP「整頁只能綁一個 Service」這個限制，官方文件形容成 KPI 標籤跟 Value Help 是「例外」？這跟這一課學到的 OVP「本質上不是單一實體頁面」的原因，是不是同一種道理？

## 答案

`fe16overviewpage/webapp/manifest.json`（`sap.app.dataSources.taskService`／`sap.ui5.models.taskModel`／`sap.ovp.cards.card_note`＋`card_task`）與 `i18n.properties`（`card_note_title`／`card_task_title`）已由使用者實機操作＋Claude 校正後定案，**Part A／Part B 全部端對端實機驗證成功**（2026-08-25）。

過程中修正了兩個真實踩坑，值得記錄：

1. **巢狀重複**：手動編輯時把整段從 `"sap.ovp": {...}` 開始的完整片段，貼進了 Generator 已經產生的 `sap.ovp.cards` 那個既有的空物件裡，變成 `sap.ovp → cards → sap.ovp → cards` 多包一層——JSON 結構錯誤，框架讀不到卡片。修法：卡片項目要直接補進既有的 `"cards": {}` 裡，不要整段複製貼上一個新的 `sap.ovp` 外層。
2. **Model 名稱誤判**：原始講義假設這個 OVP 範本的主要服務 model 會沿用 fe01/fe08 那種匿名 `""`，但 `@sap/generator-fiori:ovp` 範本（跟 List Report 用的 `:lrop` 不同）實際上把它命名成 **`mainModel`**——這是實測才發現的範本差異，不同 Fiori Elements Generator 範本對「預設 model 叫什麼名字」沒有統一慣例，改設定前務必先讀一次 Generator 實際產生的 `sap.ui5.models`，不能照抄別的範本的命名習慣。

最終畫面：Object 兩張卡片並排——「最新 Note」（List Card，來自 `mainModel`／`ZRC08_SB`）、「待處理 Task」（Table Card，來自 `taskModel`／`ZRC01_SB`），全域篩選列正確渲染 FilterBar，證實整門課的核心主張（OVP 可以在同一個 App 混用多個獨立 Service Binding）完整成立。

## Sources

- [SAP Fiori Elements for OData V4](https://ui5.sap.com/#/topic/13ee8ba1b0264ba08dc15a4aee02c91f)
- [How Overview Page Differs from Other Floorplans](https://ui5.sap.com/#/topic/c64ef8c6c65d4effbfd512e9c9aa5044)
- [Prerequisites for Using SAP Fiori Elements for OData V4](https://ui5.sap.com/#/topic/f2344b5e78164b2b9c27ef8b068f295c)
- [Configuring the Manifest for the Overview Page](https://help.sap.com/docs/SAPUI5/b2f662dd9d7a4ec680056733050b4d34/f194b411027e4402a0be0537fa7b803b.html)
- [Overview Page Card](https://help.sap.com/docs/SAPUI5/b2f662dd9d7a4ec680056733050b4d34/74332d5d829b413f9d7c0950dc6a71d2.html)
- [Configuring the Global Filter on the Overview Page](https://ui5.sap.com/#/topic/73d96937ae94468da04cf0d32eb4c6ee)
- [Data Source (SAP Fiori Tools Generator)](https://help.sap.com/docs/SAP_FIORI_tools/17d50220bcd848aa854c9c182d65b699/99061814ead548808d539861fb27bafb.html)
