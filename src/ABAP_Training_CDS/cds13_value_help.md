# CDS View 課程練習 13：Value Help Annotation

## Lecture

### 這一課要教什麼

`carrid` 這種代碼欄位（`AA`／`LH`）對使用者不友善——這一課教兩件事：① 用 `@Consumption.valueHelpDefinition` 幫欄位掛一個 F4 說明清單（Value Help），讓使用者輸入時可以查詢；② 用 `@ObjectModel.text.association` 幫代碼欄位關聯一個文字說明欄位（例如查到 `AA` 時，畫面顯示「American Airlines」而不是代碼本身）。

**這一課開課前已經查證過一個重要澄清**：`@Consumption.valueHelpDefinition` 是**純 CDS Annotation**，指向另一個 CDS View 當作值清單來源，跟 RAP 課程第 10 節記載的 **Classic Search Help（SHLP，GUI-only，這系統完全沒有 ADT API）是完全不同的機制**——這一課完全不會踩到那個限制，是這門課到目前為止極少數「開課前的擔心最後證明是虛驚一場」的主題。

### 語法元素講解

**① `@Consumption.valueHelpDefinition`**：標在欄位上，指定值清單來源：

```abap
@Consumption.valueHelpDefinition: [{ entity: { name: '<來源 CDS View>', element: '<來源欄位>' } }]
```

這一課讓 `carrid` 的 Value Help 指向 cds01 建的 `ZI_CDS01_CARRIER` 的 `carrid` 欄位——代表這個欄位的合法值清單，就是 `ZI_CDS01_CARRIER` 查得到的所有航空公司代碼。

**② `@ObjectModel.text.association`**：標在代碼欄位上，指定「文字說明」要透過哪個 Association 取得：

```abap
@ObjectModel.text.association: '_Carrier'
key Flight.carrid,
```

搭配這一課宣告的 `_Carrier` Association（跟 cds03 學的語法完全相同），消費端可以知道「`carrid` 這個欄位，如果要顯示對使用者友善的文字，去 `_Carrier` 這個關聯拿」。

### 完整範例

```abap
@AbapCatalog.sqlViewName: 'ZICDS13FLGT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS13: Flight with Value Help + Text Association'
define view ZI_CDS13_FLIGHT_VH
  as select from sflight as Flight
  association [1..1] to ZI_CDS01_CARRIER as _Carrier
    on _Carrier.carrid = Flight.carrid
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_CDS01_CARRIER', element: 'carrid' } }]
      @ObjectModel.text.association: '_Carrier'
  key Flight.carrid,
  key Flight.connid,
  key Flight.fldate,

      _Carrier.carrname   as CarrierName
}
```

**這一課刻意重用了 cds01 建的 `ZI_CDS01_CARRIER`**，示範一件事：這門課從基礎篇累積下來的物件，到了進階篇一樣可以直接拿來用——`ZI_CDS01_CARRIER` 原本只是「CDS View 是什麼」這一課最基本的示範物件，這裡搖身一變成了另一個 View 的 Value Help 資料來源，這正是 cds05 講過的「CDS View 可重用性」的具體體現。

### 這一課的 annotation 純粹是中繼資料，不影響一般查詢

跟這一課的兩個「重量級」鄰居（cds10 Custom Entity、cds12 Virtual Element）不同——那兩個主題的機制**必須透過框架存取才會生效，純 Open SQL 只會看到空值/佔位值**；這一課的 `@Consumption.valueHelpDefinition`／`@ObjectModel.text.association` 純粹是**中繼資料標記**，不影響查詢本身的行為。這一課的驗證程式直接用最普通的 Open SQL 查詢，`CarrierName` 正常查得到值——證實這兩個 annotation 只是「額外說明」，不會讓查詢變得更複雜或有額外限制。

### Eclipse ADT 建立 CDS View：Step by Step

1. 對著 `$TMP` 套件右鍵 → New → Other ABAP Repository Object → `Data Definition` → Name `ZI_CDS13_FLIGHT_VH`
2. Templates 選 **Define View（obsolete as of AS ABAP 7.57）**，Reference Object 選 `SFLIGHT`
3. 改成上面的完整內容
4. Ctrl+S → Activate
5. 用 Data Preview 確認 `CarrierName` 正確顯示；**這一課的 Value Help（F4 下拉選單）效果，需要在真正的輸入畫面（例如 Fiori Elements 或某些 ADT 測試工具）才看得到，Data Preview 本身不一定會呈現 F4 效果**——這點留給你在 Eclipse 實際操作時確認

## Eclipse ADT Step by Step（重點回顧）

1. `ZI_CDS13_FLIGHT_VH`：以 `SFLIGHT` 為來源，Association 接 `ZI_CDS01_CARRIER`
2. `@Consumption.valueHelpDefinition` 指向 `ZI_CDS01_CARRIER` 的 `carrid`
3. `@ObjectModel.text.association` 指向剛宣告的 Association
4. Data Preview 驗證 `CarrierName` 正確顯示

## 學習目標

- 能寫出 `@Consumption.valueHelpDefinition` 指向另一個 CDS View 當作值清單來源
- 能寫出 `@ObjectModel.text.association` 搭配 Association 提供代碼欄位的文字說明
- 能講出「這是純 CDS Annotation，不受 Classic Search Help（SHLP）GUI-only 限制影響」這個開課前查證的關鍵結論
- 能講出這一課的 annotation 是中繼資料層級、不影響一般 Open SQL 查詢行為（跟 cds10／cds12 的框架依賴機制對比）
- 能舉出這一課重用 cds01 物件（`ZI_CDS01_CARRIER`）當 Value Help 來源的例子，體現 CDS View 可重用性

## 物件清單

| 物件 | 名稱 | 型別 |
|---|---|---|
| CDS Interface View | `ZI_CDS13_FLIGHT_VH` | `DDLS/DF` |
| 驗證程式 | `ZR_CDS13_DEMO` | `PROG/P` |

全部物件都在 `$TMP` 套件，已建立並啟用（讀取 active 版本內容與寫入內容逐字相符）。

## 動手練習（留待後續補做）

1. 用 `SPFLI` 建一個新的 CDS View，幫 `cityfrom`／`cityto` 欄位各自掛一個 Value Help（可以指向你自建的城市清單 View，或研究看看能不能直接指向標準物件）
2. 在 Eclipse 對著建好的 View 用 Data Preview，實際確認 F4 下拉選單有沒有出現、內容對不對
3. 建好後跟我核對語法

## 驗證方式

`ZR_CDS13_DEMO` 透過 `programrun` 無頭驗證，確認 Value Help／Text Association annotation 不影響一般 Open SQL 查詢：

```text
=== ZI_CDS13_FLIGHT_VH: Open SQL still works normally (annotations are pure metadata) ===
AA  0017 2018/10/29 American Airlines
AA  0017 2018/11/30 American Airlines
AA  0017 2019/01/01 American Airlines
AA  0017 2019/02/02 American Airlines
AA  0017 2019/03/06 American Airlines
=== Sanity check: CarrierName populated via the same association used for value help/text ===
MATCH: value help / text annotations do not affect normal query behavior, row count          5
```

`CarrierName` 正確顯示「American Airlines」——證實 Value Help／Text Association annotation 純粹是中繼資料，查詢行為完全正常。

**動手練習的驗證方式**：Eclipse 啟用成功＋用 Data Preview 看 F4 下拉選單跟查詢結果，貼截圖給我核對。

## 思考題

1. `@Consumption.valueHelpDefinition` 指向的是 `ZI_CDS01_CARRIER`（cds01 建的最基本 View），如果之後 `ZI_CDS01_CARRIER` 被刪除或改名，這一課的 View 會發生什麼事？
2. `@ObjectModel.text.association` 提供的是「文字說明」，`@Consumption.valueHelpDefinition` 提供的是「合法值清單」——這兩者概念上有什麼關聯？一個欄位可以只有其中一個、沒有另一個嗎？
3. 回顧 RAP 課程學過的 Classic Search Help（SHLP，如果你上過那門課）——為什麼這一課的 CDS-based Value Help 完全不需要依賴 SHLP 這個傳統物件？

## 答案

見 `zi_cds13_flight_vh.ddls.abap`、`zr_cds13_demo.prog.abap`。SAP 端物件：`ZI_CDS13_FLIGHT_VH`（CDS View）、`ZR_CDS13_DEMO`（驗證程式）。動手練習由你在 Eclipse 動手建立，稍後補做，沒有固定答案快照。
