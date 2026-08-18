# Fiori Elements 開發課程 3：List Report／Object Page 深化

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

## 學習目標

- 能講出本機 Annotation 疊加的合併規則：**同一個 `(Target, Term, Qualifier)` 是整個覆蓋，不是陣列合併**——局部覆寫沒有 Qualifier 的 Annotation（如 `UI.Facets`）前，要先把不想動的部分複製進來
- 能用 `UI.FieldGroup`（帶 Qualifier）＋`UI.Facets` 的 `ReferenceFacet` 組合，在 Object Page 加一個新的 Section，欄位分組顯示
- 知道 `UI.FieldGroup` 用 Qualifier 互相區隔、不會互相覆蓋，這跟沒有 Qualifier 的 `UI.Facets`／`UI.HeaderInfo` 行為不同
- 能寫出正確的 `{@i18n>keyName}` 語法，把 Annotation 裡的顯示文字外部化到 `i18n.properties`
- 能用 `manifest.json` 的 `controlConfiguration.tableSettings` 加上 `selectionMode: "Multi"` 啟用表格多選，理解這會讓使用者可以觸發批次 Delete
- **知道任何在這個共用 Trial 環境的寫入操作（含批次刪除）都是真實、不可逆的**，動手前要先確認風險

## 物件清單

延續 fe01／fe02，這一課只修改前端專案裡的兩個檔案，沒有新增任何 ABAP 物件：

| 檔案 | 這一課的修改 |
|---|---|
| `fe01_connection_test/webapp/annotations/annotation.xml` | 新增 `UI.FieldGroup#AuditInfo`＋完整的 `UI.Facets`（含保留的 `GeneralInfo`＋新增的 `AuditInfo`） |
| `fe01_connection_test/webapp/i18n/i18n.properties` | 新增 `fieldGroupGeneralInfo`／`fieldGroupAuditInfo` 兩個文字 key |
| `fe01_connection_test/webapp/manifest.json` | `controlConfiguration.tableSettings` 加上 `selectionMode: "Multi"`／`condensedTableLayout: true` |

## 動手練習

**輪到你了**：

1. 幫 `Audit Information` Section 也加入 `local_changed_at`（Draft 的技術異動欄位）——先想一想：這個欄位在 `zi_rc05_note.ddls.abap` 裡標了 `@Semantics.systemDateTime.localInstanceLastChangedAt`，BDEF 也是 `field(readonly)`，你覺得顯示給使用者看有沒有意義？如果決定要加，改 `UI.FieldGroup#AuditInfo` 的 `Data` Collection，多加一個 `DataField` 就好
2. 試著把 `selectionMode` 從 `"Multi"` 改成 `"None"`，重新整理確認核取方塊真的消失、`Delete` 按鈕也跟著沒了（多選是可以整個關掉的，不是每個 List Report 都需要）
3. 想一想（不用真的做）：如果要在 `UI.LineItem`（List Report 表格欄位）也做局部覆寫，例如只是想調整某個欄位的顯示順序，你要怎麼避免重蹈這一課「不小心把其他欄位洗掉」的覆轍？

## 驗證方式

這一課沒有 ABAP 物件變更，驗證方式是「畫面行為符合預期」：

1. Object Page 同時顯示 **General Information**／**Audit Information** 兩個分頁／Section，`changed_at` 歸在後者
2. List Report 表格出現多選核取方塊，勾選多筆後 `Delete` 按鈕可點擊，執行後資料確實減少
3. **這一課實測結果**：兩項都已截圖確認成功——覆蓋行為的排錯過程（先錯後對）跟批次刪除的真實效果都已驗證，過程中也確實刪除了兩筆真實測試資料（`RCTEST001`／`TEST003`），符合預期的真實寫入行為，不是異常

## 思考題

1. 這一課學到「沒有 Qualifier 的 Annotation 本機覆寫是整個取代」——`UI.HeaderInfo`（App 的標題、型別名稱）也是沒有 Qualifier 的 Annotation。如果你想在本機疊加一段只改 `TypeNamePlural` 的 `UI.HeaderInfo`，會不會也把後端定義的 `Title`（`{ type: #STANDARD, value: 'title' }`）洗掉？要怎麼驗證你的猜測？
2. `condensedTableLayout: true` 讓表格看起來更緊湊——這個設定只影響**畫面呈現**，還是也會改變 OData 請求本身（例如一次抓的筆數）？（提示：想一想第 40.7 節／rc08 學過的「Draft 才有 Create/Edit」是框架層級的行為，這個問題是要你分辨「純 UI 呈現設定」跟「影響資料存取邏輯的設定」這兩類 `tableSettings` 屬性）
3. 這一課刪除的 `RCTEST001`／`TEST003` 是哪一課留下的測試資料？如果之後要示範「批次操作」又不想動到別人的測試資料，你會怎麼設計一批「安全可以刪」的專屬測試資料（提示：想一想本檔案 `.claude/rules/sap-adt-mcp.md` 記載過的「安全閘」設計原則，是不是也適用在 Fiori App 這一層）

## 答案

見 `fe01_connection_test/webapp/annotations/annotation.xml`（`UI.FieldGroup#AuditInfo`＋完整 `UI.Facets`）、`fe01_connection_test/webapp/i18n/i18n.properties`（新增的兩個 key）、`fe01_connection_test/webapp/manifest.json`（`tableSettings` 段落）。沒有新增或修改任何 ABAP 物件，也沒有新增前端專案——全部是對 `fe01_connection_test` 既有專案的疊加修改。實測結果：Section 分組正確顯示（含先錯後對的排錯過程）、批次刪除功能正常運作（且是真實刪除，已在講義正文警語說明）。
