# Fiori Elements 開發課程 2：專案結構解讀

## Lecture

### 這一課不重新建專案，直接深度解析 fe01 已經產生的東西

fe01 把重點放在「怎麼連上系統、產生專案」，對產生出來的檔案只給了一句話帶過（`manifest.json`／`ui5.yaml`／`package.json` 各自的角色）。這一課要做的是**逐項拆開 `fe01_connection_test/` 這個資料夾**，搞懂每個檔案實際存了什麼、為什麼長這樣——不需要再跑一次 Generator，直接讀已經有的專案就好。

下面每一段引用的內容，都是直接讀取 `fe01_connection_test/` 裡的真實檔案得到的（不是照抄官方文件的通用範例），所以你可以自己打開對照。

### `manifest.json`：App 的「總設定檔」，逐段解讀

**`sap.app`**——App 的身分與資料來源：

```json
"sap.app": {
  "id": "fe01connectiontest",
  "dataSources": {
    "annotation": { "type": "ODataAnnotation", "uri": "annotations/annotation.xml" },
    "mainService": {
      "uri": "/sap/opu/odata4/sap/zrc08_sb/srvd/sap/zrc08_sd/0001/",
      "type": "OData",
      "settings": { "annotations": ["annotation"], "odataVersion": "4.0" }
    }
  }
}
```

`dataSources` 裡有**兩個資料來源**：`mainService` 是真正的 OData 服務（fe01 已經核對過），`annotation` 是**本機額外的 UI Annotation 檔案**（`annotations/annotation.xml`）——注意 `mainService.settings.annotations` 陣列裡引用了它，代表這個 App 實際生效的 UI 標記＝「後端 `$metadata` 自帶的 Annotation」＋「這個本機檔案疊加的 Annotation」兩者合併。

**`sap.ui5.routing`**——List Report／Object Page 怎麼串起來：

```json
"routing": {
  "routes": [
    { "pattern": ":?query:", "name": "NoteList", "target": "NoteList" },
    { "pattern": "Note({key}):?query:", "name": "NoteObjectPage", "target": "NoteObjectPage" }
  ],
  "targets": {
    "NoteList": {
      "type": "Component", "name": "sap.fe.templates.ListReport",
      "options": { "settings": {
        "contextPath": "/Note",
        "navigation": { "Note": { "detail": { "route": "NoteObjectPage" } } },
        "controlConfiguration": {
          "@com.sap.vocabularies.UI.v1.LineItem": { "tableSettings": { "type": "ResponsiveTable" } }
        }
      } }
    },
    "NoteObjectPage": {
      "type": "Component", "name": "sap.fe.templates.ObjectPage",
      "options": { "settings": { "editableHeaderContent": false, "contextPath": "/Note" } }
    }
  }
}
```

幾個關鍵對應關係：

- **這裡完全沒有你自己寫的 View／Controller**——`target.name` 直接指到 SAP 官方框架元件 `sap.fe.templates.ListReport`／`sap.fe.templates.ObjectPage`，畫面完全是這兩個範本讀取 `contextPath` 指到的 CDS Entity（`/Note`）＋Annotation 動態生成的。這就是「Fiori Elements」這個名字的意思：你只給設定（Annotation＋這份 routing 設定），框架自己生出畫面，不是你手刻 XML View。
- **`pattern` 是 URL 路由規則**：`:?query:` 代表「可有可無的查詢參數」（List Report 首頁不需要任何路徑參數）；`Note({key}):?query:` 的 `{key}` 是**真正的 URL 參數**，對應點進某一筆 Note 時網址列會出現的 `Note(RC05TEST02,IsActiveEntity=true)` 這種技術 Key。
- **`navigation.Note.detail.route`** 就是「List Report 點一列資料，該跳去哪個 route」的設定——這裡指到 `NoteObjectPage`，兩個 Target 因此被串在一起。
- **`controlConfiguration` 裡的 `tableSettings.type: "ResponsiveTable"`**——這正是 fe01 Generator 精靈第 10 步你選的 `Table Type: Responsive` 落地的地方，證實 Generator 那一步問的問題確實對應到這裡的設定。
- **`editableHeaderContent: false`**——Object Page 標題列的欄位預設不能直接編輯，要先按 `Edit` 按鈕才能改（Draft 進入編輯模式），這是官方範本針對 Draft 實體的標準行為。

**`sap.fe`**——這是全域的 Fiori Elements 執行期設定（跟 `sap.ui5.routing.targets.*.options.settings` 這種「單一頁面設定」不同層級）：

```json
"sap.fe": { "app": { "enableLazyLoading": true } }
```

這一課只有這一個設定（延遲載入子元件，優化效能），之後幾課如果用到 `sap.fe` 層級的其他開關，會在對應課程說明。

### `webapp/` 資料夾逐項介紹：哪些是真檔案，哪些是「工具動態生成」的虛擬資源

fe01 已經教過一個重要觀念：`Application Info` 面板不是檔案，是擴充套件動態渲染的畫面。**這個觀念在 `webapp/` 資料夾裡还有另一個例子**，一併在這裡講清楚：

| 檔案／路徑 | 是真檔案嗎 | 說明 |
|---|---|---|
| `Component.js` | ✅ 真檔案 | 整個 App 的進入點，內容只有 5 行：`Component.extend("fe01connectiontest.Component", { metadata: { manifest: "json" } })`——繼承 `sap/fe/core/AppComponent`，把所有設定都委派給 `manifest.json`，本身幾乎沒有邏輯 |
| `index.html` | ✅ 真檔案 | **standalone 模式**的進入點（`npm run start-noflp` 用的就是這個），直接載入 UI5 Bootstrap＋掛載 Component，沒有 Fiori Launchpad 外殼 |
| `test/flp.html`（瀏覽器網址列打的那個） | ⚠️ **不是真檔案** | `find` 這個資料夾找不到 `flp.html`，但瀏覽器打得開——它是 `ui5.yaml` 裡 `fiori-tools-preview` middleware **執行期動態生成**的「Local FLP Sandbox」（npm start 的 log 也印過 `Using sandbox template for UI5 version: ...` 這一行），模擬正式環境 Fiori Launchpad 的外殼，讓你在本機也能用跟正式環境一樣的方式（Tile 點進去）預覽 App，不用另外架一個真正的 Launchpad |
| `i18n/i18n.properties` | ✅ 真檔案 | 文字資源檔，目前只有 `appTitle`／`appDescription` 兩個 key（對應 `manifest.json` 裡的 `{{appTitle}}`／`{{appDescription}}` 佔位符） |
| `annotations/annotation.xml` | ✅ 真檔案，但**目前是空殼** | 只有 17 行，`<Schema Namespace="local">` 底下完全沒有任何 `<Annotations>` 內容——因為這一課的 `@UI.*` 標記（`HeaderInfo`／`Facets`／`LineItem`／`Identification`）全部**已經在後端 CDS Metadata Extension 裡寫好**，隨 `$metadata` 一起送過來，這個本機檔案不用重複定義。它的真正用途是**前端想要疊加或覆寫某個 Annotation 時，不用改 ABAP、直接改這個檔案就好**（下面動手練習會示範） |
| `localService/mainService/metadata.xml` | ✅ 真檔案（531 行） | Generator 精靈連線時抓回來的 **`$metadata` 本機副本**——用 `grep` 可以在這個檔案裡直接找到 `SAP__UI.HeaderInfo`／`SAP__UI.Facets`／`SAP__UI.LineItem`／`SAP__common.DraftRoot` 這些標記的完整內容，證實 rc08 在 ABAP CDS 端寫的 Metadata Extension，最終就是編譯成這裡看到的樣子。⚠️ 這份副本主要給 Mock Server／型別提示用，**執行期實際顯示畫面時，App 打的是真正的後端 `$metadata`，不是這份本機副本**——如果之後 ABAP 端的 Annotation 改了，這份本機檔案要重新用 Generator（或對應指令）刷新，不會自動同步 |
| `localService/mainService/srvd_f4/...` | ✅ 真檔案 | Value Help 的 Metadata（例如 `I_DraftAdministrativeUserVH`，Draft 建立人／異動人的 Value Help），這是 fe01 第 9 步「Download value help metadata」選 `Yes` 才會抓下來的東西——選 `No` 的話這個子資料夾就不會存在 |
| `test/integration/*.gen.js` | ✅ 真檔案（Generator 自動產生） | `NoteListJourney.gen.js`／`NoteObjectPageJourney.gen.js` 是 OPA5（One Page Acceptance，SAPUI5 官方整合測試框架）的測試骨架，根據 `manifest.json` 的 routing 設定自動生成——檔名對應到 List Report／Object Page 兩個頁面，`.gen.js` 副檔名代表「工具生成、之後重跑 Generator 可能會被覆蓋」，這門課不深入（整合測試不是這門課的主題），但值得知道它的存在 |

### 三份 `ui5*.yaml` 設定檔的差異

專案裡其實有三份 UI5 Tooling 設定檔，`npm start`／`npm run start-local`／`npm run start-mock` 分別對應：

| 檔案 | 對應指令 | 連線對象 | 用途 |
|---|---|---|---|
| `ui5.yaml` | `npm start` | 真實後端（`fiori-tools-proxy`）＋ 遠端 UI5 Runtime（`ui5.sap.com`） | fe01 用的就是這個——最貼近正式環境的行為，但需要網路連線＋登入 |
| `ui5-mock.yaml` | `npm run start-mock` | **完全不連後端**，改用 `sap-fe-mockserver` middleware 根據 `metadata.xml` **自動生成假資料** | 適合離線開發、或後端還沒 Publish 時先開發畫面邏輯 |
| `ui5-local.yaml` | `npm run start-local` | 同時設定了 `sap-fe-mockserver`＋真實後端 `fiori-tools-proxy`，且多了一段 `framework:` 區塊指定把 SAPUI5 函式庫**真正下載到本機**（不透過 Proxy 連 `ui5.sap.com`） | 適合完全離線環境（沒有網路也能開發，UI5 函式庫本身也不用連線） |

**這三份設定檔都是 Generator 精靈自動產生的**，不用自己手刻——這一課只需要知道它們的差異，之後真的要用到離線／Mock 開發模式時，直接換一個指令即可。

### `package.json` 的 `scripts`：每個指令在做什麼

| Script | 實際指令 | 用途 |
|---|---|---|
| `start` | `fiori run --open "test/flp.html#app-preview"` | fe01 用的標準本機開發模式 |
| `start-local` | 帶 `ui5-local.yaml` | 見上表，離線開發 |
| `start-mock` | 帶 `ui5-mock.yaml` | 見上表，Mock 資料 |
| `start-noflp` | 開 `/index.html`（不透過 FLP Sandbox） | 直接用 `index.html` 這個真檔案開啟，不經過虛擬的 `flp.html` |
| `build` | `ui5 build --config=ui5.yaml --clean-dest --dest dist` | 打包成正式的靜態資源，`dist/` 資料夾（`.gitignore` 已排除）——fe06 部署會用到 |
| `deploy` | `fiori verify` | 部署（fe06 詳細教） |
| `deploy-config` | `fiori add deploy-config` | 產生部署設定（fe06 詳細教） |
| `lint` | `eslint ./` | 程式碼風格檢查 |
| `int-test` | 跑 OPA5 整合測試（`ui5-mock.yaml`＋`opaTests.qunit.html`） | 對應上面 `test/integration/*.gen.js` 那些測試骨架 |

## 學習目標

- 能講出 `manifest.json` 的 `sap.app`／`sap.ui5.routing`／`sap.fe` 三個區塊各自負責什麼，尤其是 `routing.routes`／`routing.targets` 怎麼把 List Report 跟 Object Page 串成一個可以互相導覽的 App
- 知道 Fiori Elements App 沒有手寫的 View／Controller——畫面是 `sap.fe.templates.ListReport`／`sap.fe.templates.ObjectPage` 這兩個官方範本元件，讀取 `contextPath`＋Annotation 動態生成的
- 能區分 `webapp/` 底下「真檔案」跟「工具執行期動態生成、實際不存在」的資源（`test/flp.html` 是後者，跟 fe01 教過的 `Application Info` 面板是同一類概念）
- 知道 `@UI.*` Annotation 目前全部來自後端 `metadata.xml`（能用 `grep` 在裡面找到 `HeaderInfo`／`Facets`／`LineItem`／`DraftRoot`），`annotations/annotation.xml` 這個本機檔案目前是空的，但是前端**不改 ABAP、疊加/覆寫 Annotation** 的正式管道
- 能講出 `ui5.yaml`／`ui5-local.yaml`／`ui5-mock.yaml` 三者的差異與對應的 `npm run` 指令
- 知道 `Download value help metadata` 這個 Generator 選項具體會多產生 `localService/mainService/srvd_f4/` 這個子資料夾

## 物件清單

這一課不產生任何新的前端專案或 ABAP 物件——完全是對 fe01 已經產生的 `fe01_connection_test/` 做深度解析：

| 檔案 | 這一課的重點 |
|---|---|
| `fe01_connection_test/webapp/manifest.json` | `routing.routes`／`routing.targets`／`sap.fe` |
| `fe01_connection_test/webapp/Component.js` | App 進入點 |
| `fe01_connection_test/webapp/annotations/annotation.xml` | 本機 Annotation 疊加機制（動手練習會實際改這個檔案） |
| `fe01_connection_test/webapp/localService/mainService/metadata.xml` | 後端 `$metadata` 本機副本，含完整 `@UI.*` 標記 |
| `fe01_connection_test/ui5.yaml`／`ui5-local.yaml`／`ui5-mock.yaml` | 三種本機開發模式 |

## 動手練習

**練習 1（livereload 體驗）**：`fe01_connection_test` 的 `npm start` 應該還在背景跑著（`fiori-tools-appreload` middleware，port 35729）。打開 `webapp/i18n/i18n.properties`，把 `appTitle=FE01 連線測試` 改成別的文字，存檔——**不用重新執行 `npm start`**，瀏覽器分頁標題應該會自動更新。這證實 livereload 真的在運作，也讓你直接體驗到「改設定檔、瀏覽器自動反映」這個開發迴圈。

**練習 2（本機 Annotation 疊加，選做，稍有難度）**：`webapp/annotations/annotation.xml` 目前是空殼。試著在 `<Schema Namespace="local">` 裡加一段 `<Annotations Target="...">`，針對 `Note` Entity 的某個欄位覆寫顯示行為（例如把某個欄位在 List Report 表格裡隱藏，或改變欄位順序）——**不用改任何 ABAP 物件**，存檔後 livereload 應該會反映在畫面上。如果卡住，可以先跟我核對要寫的 XML 內容。

## 驗證方式

這一課沒有 ABAP 物件變更，驗證方式是「讀懂＋能對應到真實檔案內容」：

1. 你能指出 `manifest.json` 裡哪一段決定了「點 List Report 一列會跳到 Object Page」
2. 練習 1：livereload 實測成功，瀏覽器標題文字即時反映 `i18n.properties` 的修改
3. （選做）練習 2：`annotation.xml` 加了本機覆寫後，畫面行為確實改變，且沒有動到任何 ABAP 物件

## 思考題

1. `manifest.json` 的 `dataSources.mainService.settings.annotations` 是一個陣列（`["annotation"]`），如果之後這個 App 需要疊加第二份本機 Annotation 檔案（例如區分「這是這個 App 專屬的客製化」跟「這是共用的擴充」），你覺得要怎麼設定？（提示：陣列可以放多個 ID，每個 ID 對應 `dataSources` 底下另一個 `ODataAnnotation` 型別的項目）
2. `localService/mainService/metadata.xml` 是本機的 `$metadata` 副本，執行期實際顯示畫面時卻是打真正的後端——如果 ABAP 端後來又加了一個欄位的 `@UI.lineItem`，這個本機副本沒有跟著更新，畫面上會不會反映最新的後端 Annotation？這個副本存在的意義究竟是什麼（提示：想一想 `ui5-mock.yaml` 的 Mock Server 是根據誰產生假資料的）
3. `routing.targets.NoteObjectPage` 沒有設定 `navigation`（跟 `NoteList` 不同，`NoteList` 有一段 `navigation.Note.detail.route`）——這代表 Object Page 沒辦法再往下導覽了嗎？如果之後（fe08）要做 Header-Item 的 Composition App，你覺得子項目的導覽設定應該加在哪裡？

## 答案

見 `fe01_connection_test/webapp/manifest.json`（`routing` 段落）、`fe01_connection_test/webapp/annotations/annotation.xml`（動手練習 2 完成後會有內容）、`fe01_connection_test/webapp/localService/mainService/metadata.xml`（後端 Annotation 的完整內容，用 `grep "SAP__UI\."` 可以快速定位）。這一課沒有產生新的物件，答案就是對照著讀 fe01 已經建立的專案。
