# Fiori Elements 開發課程 3：List Report／Object Page 深化

> **環境**：BTP ABAP Environment Trial（沿用 fe01 的 `fe01_connection_test` 專案）

## Lecture

### 這一課要證明的事

rc08 已經在 ABAP CDS 端（Metadata Extension）幫 `ZI_RC05_NOTE` 寫好一組基本的 `@UI.*` 標記，但只有**一個** Section（`GeneralInfo`），所有欄位都塞在同一個 Facet 裡，List Report 表格也只有預設行為。這一課要做兩件事，**全部透過 fe02 教過的「本機 `annotations/annotation.xml` 疊加」機制完成，完全不回 Eclipse 改 ABAP**：

1. 幫 Object Page 加第二個 Section（`Audit Information`），把異動時間欄位獨立分組——過程中意外踩到一個**很重要、很容易誤判的行為**，這一課最有價值的發現就在這裡。
2. 幫 List Report 的表格加 Table Settings（多選＋批次刪除），順便留下一個關於「本機測試也是真實操作」的實務提醒。

### ⚠️⚠️ 核心發現：本機疊加的 Annotation，同一個 Target＋Term 是「整個覆蓋」，不是「合併」

**第一次嘗試**：在 `annotation.xml` 只加了一個新的 `UI.Facets`（本機檔案，Target 指向 `SAP__self.NoteType`），裡面只放新的 `AuditInfo` Facet，**沒有把後端既有的 `GeneralInfo` Facet 也寫進去**——想法是「反正後端已經有 GeneralInfo 了，我只要補一個新的就好」。

```xml
<Annotations Target="SAP__self.NoteType">
  <Annotation Term="UI.FieldGroup" Qualifier="AuditInfo">
    <Record Type="UI.FieldGroupType">
      <PropertyValue Property="Data">
        <Collection>
          <Record Type="UI.DataField"><PropertyValue Property="Value" Path="changed_at"/></Record>
        </Collection>
      </PropertyValue>
    </Record>
  </Annotation>
  <Annotation Term="UI.Facets">
    <Collection>
      <Record Type="UI.ReferenceFacet">
        <PropertyValue Property="ID" String="AuditInfo"/>
        <PropertyValue Property="Label" String="{@i18n>fieldGroupAuditInfo}"/>
        <PropertyValue Property="Target" AnnotationPath="@UI.FieldGroup#AuditInfo"/>
      </Record>
    </Collection>
  </Annotation>
</Annotations>
```

**實測結果（截圖為證）**：存檔、livereload 自動刷新後，Object Page 上**「General Information」整個消失，只剩下新加的「Audit Information」**——不是「兩個 Section 都出現」，也不是「兩邊的 Facet 陣列合併成一個」。

**結論**：SAPUI5 的 OData V4 Annotation 合併機制，是以 **(Target, Term, Qualifier)** 這個三元組當作識別鍵——`annotation.xml` 裡的 `UI.Facets`（無 Qualifier）跟後端 `metadata.xml` 裡的 `UI.Facets`（同樣無 Qualifier，同一個 Target）**完全撞名**，後載入的（本機檔案，載入順序在 `manifest.json` 的 `dataSources.mainService.settings.annotations` 陣列裡排在後面）**整個取代**前者，不會逐項合併陣列內容。

**修法**：本機的 `UI.Facets` 覆寫，要把「想保留的舊 Facet」跟「想新增的 Facet」**全部一起寫進同一個 Collection**：

```xml
<Annotation Term="UI.Facets">
  <Collection>
    <Record Type="UI.ReferenceFacet">
      <PropertyValue Property="ID" String="GeneralInfo"/>
      <PropertyValue Property="Label" String="{@i18n>fieldGroupGeneralInfo}"/>
      <PropertyValue Property="Target" AnnotationPath="@UI.Identification"/>
    </Record>
    <Record Type="UI.ReferenceFacet">
      <PropertyValue Property="ID" String="AuditInfo"/>
      <PropertyValue Property="Label" String="{@i18n>fieldGroupAuditInfo}"/>
      <PropertyValue Property="Target" AnnotationPath="@UI.FieldGroup#AuditInfo"/>
    </Record>
  </Collection>
</Annotation>
```

`GeneralInfo` 這筆的 `Target` 指回後端既有的 `@UI.Identification`（沒有 Qualifier 的那個，後端沒有被覆蓋，還在），重新整理後兩個 Section 都正常出現，`changed_at` 也正確歸到 `Audit Information` 底下。

**這條規則不是只對 `UI.Facets`成立，任何 `(Target, Term, Qualifier)` 相同的 Annotation 疊加都一樣**——如果之後要局部覆寫 `UI.LineItem`（List Report 表格欄位）或 `UI.Identification`（Object Page 表單欄位），同樣要把「不想動的欄位」也一起複製進本機檔案，只寫「新增的部分」會把整個既有清單洗掉，不是加上去。**這是這一課最重要的心智模型：本機疊加層面對「有 Qualifier 區分」的 Annotation（像這裡的 `UI.FieldGroup#AuditInfo`）是安全的（新 Qualifier 不會跟任何既有的撞名），但面對「沒有 Qualifier、整個實體只有一份」的 Annotation（像 `UI.Facets`／`UI.HeaderInfo`），修改前一定要先複製完整的既有內容。**

**`@i18n>` 文字繫結的正確語法**：Facet 的 `Label` 屬性如果直接寫死字串（如 `String="Audit Information"`），SAP Fiori tools 的 ESLint 外掛會警告 `missing-i18n-key`——正確做法是先在 `i18n/i18n.properties` 加一個 key，再用 **`String="{@i18n>keyName}"`**（注意是單一個 `@` 接 `i18n`，`>` 後面直接接 key 名稱，沒有第二個 `@`）引用，這是官方 `fiori-elements-opensap` 範例教材驗證過的正確格式。

### List Report Table Settings：多選＋批次刪除

`manifest.json` 裡 `routing.targets.NoteList.options.settings.controlConfiguration` 已經有 `@com.sap.vocabularies.UI.v1.LineItem.tableSettings.type: "ResponsiveTable"`（fe01 Generator 精靈選的 Table Type，fe02 已經對照過）。這一課直接在同一個 `tableSettings` 物件裡加兩個屬性：

```json
"tableSettings": {
  "type": "ResponsiveTable",
  "selectionMode": "Multi",
  "condensedTableLayout": true
}
```

- **`selectionMode: "Multi"`**——表格每一列最前面多出核取方塊，可以一次勾選多筆
- **`condensedTableLayout: true`**——列的上下間距變緊湊，同樣畫面高度能顯示更多筆資料

**實測結果**：畫面上表格最前面出現核取方塊，勾兩筆之後右上角 `Delete` 按鈕從灰階變成可點——點下去（Fiori Elements 標準行為會先跳確認對話框，確認後）跳出 `Objects deleted` 的提示，List Report 立刻少了被勾選的那幾筆。

**⚠️⚠️ 重要提醒：這不是模擬，是真的刪除**——`BDEF` 裡的 `delete;`（rc05 已經宣告過）是貨真價實的 RAP CUD 操作，這個 Table Settings 讓你在畫面上更方便觸發它，不代表操作本身變得更安全。這一課實測直接刪掉了兩筆先前課程留下的測試資料（`RCTEST001`／`TEST003`）——這是**共用的 BTP Trial 系統**，任何在這裡按下的 Delete（不管是單筆還是批次）都是對真實後端資料庫的真實寫入，沒有辦法復原。之後幾課如果要示範批次操作，動手前務必先確認要刪的是自己可以承擔後果的測試資料。

### 延伸：List Report 篩選條件的預設值——`@UI.selectionVariant`／`@UI.selectionPresentationVariant`

> ✅ 2026-08-24 新增、**2026-08-25 已實機驗證成功**（`fe01_connection_test`，`Notes (1)` 只顯示 `RC05TEST02`，`note_id` 篩選框自動帶入 `=RC05TEST02` chip，完全不用手動操作，截圖為證）。過程中推翻了原本抄自 SAP 官方文件範例的寫法，詳見下方「⚠️ 兩份官方文件互相矛盾」——這是這門課第一次靠實測發現官方文件本身表述不一致的案例。

List Report 篩選列（Filter Bar）左上角有一個「Standard」下拉選單，可以切換不同的**已儲存篩選組合（Variant）**。這一段要學的就是這個機制背後的 annotation：`@UI.selectionVariant`（定義一組篩選條件）跟 `@UI.selectionPresentationVariant`（把篩選條件跟排序／顯示方式包在一起）。

#### 官方文件的關鍵限制：欄位篩選一定要走本機 XML，不能只靠 ABAP CDS 端

查證 SAP 官方文件《Configuring Default Filter Values》（OData V4，SAPUI5 1.151）明確寫著：

> **SelectionOption is not supported in ABAP CDS annotation. Please use the local XML annotation.**

也就是說：`ZI_RC05_NOTE` 這種**沒有 `with parameters` 的一般 CDS View**，要設定「某個欄位預設要過濾成什麼值」，**沒辦法**直接寫在 Eclipse 的 Metadata Extension（`.ddlx.abap`）裡完成——ABAP CDS 端的 `@UI.selectionVariant` annotation 只能填 `parameters`（給 CDS View Parameter 用），欄位層級的 `SelectOptions`／`Ranges` 一定要走**本機 `annotation.xml`**，正好跟 fe02／fe03 前面已經教過的「本機疊加」機制銜接在一起。

#### ⚠️ 兩份官方文件互相矛盾，實測才發現正確寫法：**完全不寫 `Qualifier` 屬性**，不是 `Qualifier="Default"`

SAP 官方《Configuring Default Filter Values》頁面自己給的 XML 範例寫的是 `<Annotation Term="UI.SelectionVariant" Qualifier="Default">`（把字面字串 `"Default"` 當 Qualifier 值），並稱這是「the sample SelectionVariant showing a default value」——**照抄這個寫法，實測完全沒有生效**（畫面正常顯示全部 9 筆資料、篩選框沒有自動帶值）。

排查時翻到官方另一份文件《Configuring Default Settings (Visualizations, Sort Order, Filter Values)》，裡面描述 Fiori Elements 尋找「自動套用」篩選條件的 fallback 邏輯：

> SAP Fiori elements first checks for a default **(unqualified)** UI.SelectionPresentationVariant... If a default UI.SelectionPresentationVariant is not found, SAP Fiori elements checks for a default **(unqualified)** UI.SelectionVariant...

「unqualified」指的是**整個 `Qualifier` 屬性都不寫**，不是寫成字面值 `"Default"`。把 annotation 改成完全不帶 `Qualifier`（`<Annotation Term="UI.SelectionVariant">`）之後重新整理，**畫面立刻正確套用**——證實這才是這個 UI5 版本（1.148.7）實際認得的寫法，前一份文件自己給的範例在這個情境下是誤導的（或者是給另一種未明確說明的組合情境用的，沒有進一步查證）。**這是這門課目前唯一一個「兩份官方文件互相矛盾、只能靠實測決定該信哪個」的案例**，之後遇到類似「官方範例照抄沒用」的狀況，直接動手實測比繼續翻文件更快。

在 `fe01_connection_test/webapp/annotations/annotation.xml` 的 `Target="SAP__self.NoteType"` 底下加：

```xml
<Annotation Term="UI.SelectionVariant">
  <Record>
    <PropertyValue Property="SelectOptions">
      <Collection>
        <Record Type="UI.SelectOptionType">
          <PropertyValue Property="PropertyName" PropertyPath="note_id"/>
          <PropertyValue Property="Ranges">
            <Collection>
              <Record Type="UI.SelectionRangeType">
                <PropertyValue Property="Sign" EnumMember="UI.SelectionRangeSignType/I"/>
                <PropertyValue Property="Option" EnumMember="UI.SelectionRangeOptionType/EQ"/>
                <PropertyValue Property="Low" String="RC05TEST02"/>
              </Record>
            </Collection>
          </PropertyValue>
        </Record>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

**⚠️ 這一段是沒有 `Qualifier` 屬性的 annotation**——跟前面學到「有 Qualifier 的疊加不會撞到後端既有內容」的安全前提不同，這種沒有 Qualifier 的疊加要留意「同一個 `(Target, Term, Qualifier)` 整個覆蓋」規則（這一課前面 `UI.Facets` 已經教過）；這裡因為 `ZI_RC05_NOTE` 後端完全沒有掛任何 `@UI.selectionVariant`，所以沒有撞名風險，但如果之後在別的 CDS View 上做同樣的事，要先確認後端有沒有已經定義過不帶 Qualifier 的 `UI.SelectionVariant`。

#### 更簡單的替代方案：`@Consumption.filter.defaultValue`

如果只是要幫**單一欄位**設一個簡單的預設值（不需要範圍、不需要多值 OR 條件），有一個更輕量、而且**可以直接寫在 ABAP CDS 端**（Eclipse Metadata Extension，即 `ZI_RC05_NOTE` 這個 CDS View 對應的 Metadata Extension 物件——這是後端**真正的 ABAP 物件**，跟本課程 `src/` 目錄下同名的 `.ddlx.abap` 只是唯讀快照不同，實際要生效必須透過 Eclipse ADT 或有寫入權限的工具改到系統上）的 annotation：

```abap
@Consumption.filter.defaultValue: 'MYID01'
note_id;
```

官方文件的取捨原則：**兩者都設定時 `UI.SelectionVariant` 優先，`Common.FilterDefaultValue`（對應 ABAP CDS 的 `@Consumption.filter.defaultValue`）會被忽略**；`@Consumption.filter.defaultValue` 的限制是**不支援複雜條件**（例如「開頭是 AB」）或**多值**（例如「A 或 B」），只能設單一相等值。

✅ **2026-08-25 已實測驗證**：真正在 `ZI_RC05_NOTE` 的 Metadata Extension 加上這行、啟用後，畫面篩選欄位顯示的仍是本機 `UI.SelectionVariant` 設定的 `RC05TEST02`，`MYID01` 完全沒有生效——證實這條優先順序規則正確。

#### `@UI.selectionPresentationVariant`：篩選＋顯示方式包在一起

如果除了預設篩選條件，還想連同排序方式一起指定，可以用 `@UI.selectionPresentationVariant` 把一個 `@UI.selectionVariant` 跟一個 `@UI.presentationVariant` 綁在一起引用（官方 ABAP CDS Feature Showcase 範例，`/DMO/FSA_C_ChildTP`）：

```abap
@UI: {
  presentationVariant: [
    { qualifier: 'pVariant', sortOrder: [{ by: 'changed_at', direction: #DESC }], visualizations: [{ type: #AS_LINEITEM }] }
  ],
  selectionVariant: [
    { qualifier: 'sVariant', text: '有內容的筆記優先', filter: 'content NE \'\'' }
  ],
  selectionPresentationVariant: [
    { qualifier: 'RecentFirst', presentationVariantQualifier: 'pVariant', selectionVariantQualifier: 'sVariant' }
  ]
}
```

這個組合寫法可以直接寫在 ABAP CDS 端（不像單純欄位篩選被 `SelectionOption` 限制卡住），因為 `filter` 屬性接受的是一整段 OData filter 表達式**字串**，不是結構化的 `SelectOptions`／`Ranges`。這一段先只列出語法參考，實際掛到 List Report 的 Variant 切換器還需要額外的 `manifest.json` 設定（`variantManagement`），留給動手練習或後續課程自行深入。

## 學習目標

- 能講出本機 Annotation 疊加的合併規則：**同一個 `(Target, Term, Qualifier)` 是整個覆蓋，不是陣列合併**——局部覆寫沒有 Qualifier 的 Annotation（如 `UI.Facets`）前，要先把不想動的部分複製進來
- 能用 `UI.FieldGroup`（帶 Qualifier）＋`UI.Facets` 的 `ReferenceFacet` 組合，在 Object Page 加一個新的 Section，欄位分組顯示
- 知道 `UI.FieldGroup` 用 Qualifier 互相區隔、不會互相覆蓋，這跟沒有 Qualifier 的 `UI.Facets`／`UI.HeaderInfo` 行為不同
- 能寫出正確的 `{@i18n>keyName}` 語法，把 Annotation 裡的顯示文字外部化到 `i18n.properties`
- 能用 `manifest.json` 的 `controlConfiguration.tableSettings` 加上 `selectionMode: "Multi"` 啟用表格多選，理解這會讓使用者可以觸發批次 Delete
- **知道任何在這個共用 Trial 環境的寫入操作（含批次刪除）都是真實、不可逆的**，動手前要先確認風險
- 能講出 `@UI.selectionVariant`（**不帶 `Qualifier` 屬性**）在 List Report Filter Bar 的作用，以及為什麼一般欄位的預設篩選值一定要走本機 `annotation.xml`、不能只靠 ABAP CDS 端（官方限制：「SelectionOption is not supported in ABAP CDS annotation」）
- 知道 SAP 官方文件本身也可能互相矛盾——《Configuring Default Filter Values》範例寫 `Qualifier="Default"` 實測無效，《Configuring Default Settings》的 fallback 說明「unqualified」才是實際生效的寫法，遇到「照抄官方範例沒用」時要動手實測，不要預設文件一定準確
- ✅ 已實測驗證 `@Consumption.filter.defaultValue`（ABAP CDS 端可直接寫）跟 `@UI.selectionVariant`（本機 XML）的取捨：前者簡單但只能單值、後者可以用 `SelectOptions`／`Ranges` 表達複雜條件，兩者都設定時以 `@UI.selectionVariant` 優先（真正在後端 `ZI_RC05_NOTE` Metadata Extension 加上前者、本機加上後者，實測畫面確實以本機為準）

## 物件清單

延續 fe01／fe02，這一課主要修改前端專案裡的檔案，**動手練習第 5 題額外真正修改了一個既有 ABAP 物件**（後端 Metadata Extension，非新增）：

| 檔案／物件 | 這一課的修改 |
|---|---|
| `fe01_connection_test/webapp/annotations/annotation.xml` | 新增 `UI.FieldGroup#AuditInfo`＋完整的 `UI.Facets`（含保留的 `GeneralInfo`＋新增的 `AuditInfo`）＋不帶 `Qualifier` 的 `UI.SelectionVariant`（`note_id EQ 'RC05TEST02'`，2026-08-25 補上並實測驗證） |
| `fe01_connection_test/webapp/i18n/i18n.properties` | 新增 `fieldGroupGeneralInfo`／`fieldGroupAuditInfo` 兩個文字 key |
| `fe01_connection_test/webapp/manifest.json` | `controlConfiguration.tableSettings` 加上 `selectionMode: "Multi"`／`condensedTableLayout: true` |
| **`ZI_RC05_NOTE` 的 Metadata Extension（後端真正的 ABAP 物件，`ZRAPCLOUD` 套件）** | `note_id` 欄位加上 `@Consumption.filter.defaultValue: 'MYID01'`，透過 `abap-remote-fs` MCP（`connectionId: abap_cloud`）直接寫入並啟用，2026-08-25。本機同名快照 `src/ABAP_Training_RAP_Cloud/zi_rc05_note.ddlx.abap` 已同步更新 |

## 動手練習

**輪到你了**：

1. 幫 `Audit Information` Section 也加入 `local_changed_at`（Draft 的技術異動欄位）——先想一想：這個欄位在 `zi_rc05_note.ddls.abap` 裡標了 `@Semantics.systemDateTime.localInstanceLastChangedAt`，BDEF 也是 `field(readonly)`，你覺得顯示給使用者看有沒有意義？如果決定要加，改 `UI.FieldGroup#AuditInfo` 的 `Data` Collection，多加一個 `DataField` 就好
2. 試著把 `selectionMode` 從 `"Multi"` 改成 `"None"`，重新整理確認核取方塊真的消失、`Delete` 按鈕也跟著沒了（多選是可以整個關掉的，不是每個 List Report 都需要）
3. 想一想（不用真的做）：如果要在 `UI.LineItem`（List Report 表格欄位）也做局部覆寫，例如只是想調整某個欄位的顯示順序，你要怎麼避免重蹈這一課「不小心把其他欄位洗掉」的覆轍？
4. ✅ **這段已於 2026-08-25 實測驗證成功**（見「延伸」段落，答案已經寫進 `annotation.xml`）——你可以直接重新整理畫面看已經生效的結果；如果想自己重現排錯過程，可以先照抄 SAP 官方《Configuring Default Filter Values》文件的 `Qualifier="Default"` 寫法試一次，實際觀察它為什麼沒生效，再改成不帶 `Qualifier` 驗證差異，體會「官方文件不一定準確、要動手驗證」這件事
5. ✅ **這題也已於 2026-08-25 實測驗證成功**：後端**真正的** `ZI_RC05_NOTE` Metadata Extension 物件（`SAP` 系統上的 BTP ABAP Cloud 物件，不是本機快照檔案 `zi_rc05_note.ddlx.abap`——⚠️ 那個檔案只是唯讀快照，改它不會影響系統）已加上 `@Consumption.filter.defaultValue: 'MYID01'` 並啟用成功；重新整理畫面後，篩選欄位顯示的確實還是 `RC05TEST02`（本機 `UI.SelectionVariant` 優先），`MYID01` 完全被忽略，跟官方文件講的優先順序規則吻合，截圖為證。
   - **重要澄清（本機快照檔案 vs 真正的 ABAP 物件）**：這個系統（BTP ABAP Cloud，`ZRAPCLOUD` 套件）的正規流程是使用者用 Eclipse ADT 手動編輯；但這次意外發現 `abap-remote-fs` MCP（VS Code 擴充套件，`connectionId: abap_cloud`）其實也能直接寫入既有物件——用 `get_abap_object_workspace_uri`（`objectType: DDLX/EX`）取得真正物件的位址，`replace_string_in_abap_object` 修改內容，`abap_activate` 啟用，全程不需要打開 Eclipse GUI。這跟本檔案／`fe01_connection_test` 目錄下的 `.abap`／`.xml` 快照檔案是完全不同的兩個東西——**改本機快照檔案只是改 git 版控備份，不會反映到系統上**，只有透過這類 MCP 工具或 Eclipse ADT 才是真正動到系統物件。

## 驗證方式

這一課主要是前端 Annotation／manifest 疊加，動手練習第 5 題額外涉及一個真正的後端物件變更，驗證方式是「畫面行為符合預期」：

1. Object Page 同時顯示 **General Information**／**Audit Information** 兩個分頁／Section，`changed_at` 歸在後者
2. List Report 表格出現多選核取方塊，勾選多筆後 `Delete` 按鈕可點擊，執行後資料確實減少
3. **這一課實測結果**：以上兩項都已截圖確認成功——覆蓋行為的排錯過程（先錯後對）跟批次刪除的真實效果都已驗證，過程中也確實刪除了兩筆真實測試資料（`RCTEST001`／`TEST003`），符合預期的真實寫入行為，不是異常
4. ✅ **「延伸」段落的 `@UI.selectionVariant` 已於 2026-08-25 實機驗證成功**：`annotation.xml` 加入不帶 `Qualifier` 的 `UI.SelectionVariant`（`note_id EQ 'RC05TEST02'`）後，List Report 重新整理**一開啟就顯示 `Notes (1)`、篩選框自動帶入 `=RC05TEST02` chip**，完全不需要手動操作，截圖為證。過程中發現並修正了一個重要錯誤：SAP 官方《Configuring Default Filter Values》文件自己給的範例寫 `Qualifier="Default"`，實測完全無效；真正生效的寫法是**完全不寫 `Qualifier` 屬性**，這點對照另一份官方文件《Configuring Default Settings》的 fallback 說明（「checks for a default (unqualified) UI.SelectionVariant」）才確認
5. ✅ **優先順序規則已於 2026-08-25 用真正的後端物件驗證成功**：`ZI_RC05_NOTE` 的 Metadata Extension（後端真正 ABAP 物件）加上 `@Consumption.filter.defaultValue: 'MYID01'` 並啟用後，畫面篩選欄位顯示的仍是本機 `UI.SelectionVariant` 設定的 `RC05TEST02`，`MYID01` 完全被忽略，截圖為證

## 思考題

1. 這一課學到「沒有 Qualifier 的 Annotation 本機覆寫是整個取代」——`UI.HeaderInfo`（App 的標題、型別名稱）也是沒有 Qualifier 的 Annotation。如果你想在本機疊加一段只改 `TypeNamePlural` 的 `UI.HeaderInfo`，會不會也把後端定義的 `Title`（`{ type: #STANDARD, value: 'title' }`）洗掉？要怎麼驗證你的猜測？
2. `condensedTableLayout: true` 讓表格看起來更緊湊——這個設定只影響**畫面呈現**，還是也會改變 OData 請求本身（例如一次抓的筆數）？（提示：想一想第 40.7 節／rc08 學過的「Draft 才有 Create/Edit」是框架層級的行為，這個問題是要你分辨「純 UI 呈現設定」跟「影響資料存取邏輯的設定」這兩類 `tableSettings` 屬性）
3. 這一課刪除的 `RCTEST001`／`TEST003` 是哪一課留下的測試資料？如果之後要示範「批次操作」又不想動到別人的測試資料，你會怎麼設計一批「安全可以刪」的專屬測試資料（提示：想一想本檔案 `.claude/rules/sap-adt-mcp.md` 記載過的「安全閘」設計原則，是不是也適用在 Fiori App 這一層）

## 答案

見 `fe01_connection_test/webapp/annotations/annotation.xml`（`UI.FieldGroup#AuditInfo`＋完整 `UI.Facets`＋不帶 `Qualifier` 的 `UI.SelectionVariant`）、`fe01_connection_test/webapp/i18n/i18n.properties`（新增的兩個 key）、`fe01_connection_test/webapp/manifest.json`（`tableSettings` 段落），以及**後端 `ZI_RC05_NOTE` Metadata Extension 的 `@Consumption.filter.defaultValue: 'MYID01'`**（真正的 ABAP 物件變更，本機同名快照 `src/ABAP_Training_RAP_Cloud/zi_rc05_note.ddlx.abap` 已同步）。沒有新增任何 ABAP 物件（動手練習 5 是修改既有物件，不是新增），也沒有新增前端專案——前端部分全部是對 `fe01_connection_test` 既有專案的疊加修改。實測結果：Section 分組正確顯示（含先錯後對的排錯過程）、批次刪除功能正常運作（且是真實刪除，已在講義正文警語說明）、`UI.SelectionVariant` 預設篩選正確生效（含推翻官方範例 `Qualifier="Default"` 的排錯過程）、優先順序規則正確生效（含推翻「後端不能直接改，只能用本機替代方案」的錯誤假設，見動手練習 5 說明）。

「延伸」段落的 `@UI.selectionPresentationVariant`（排序＋篩選組合）部分**仍只是講義文字，沒有實機驗證**——這部分需要額外的 `manifest.json`（`variantManagement`）設定，留給你自行深入或後續課程補充。
