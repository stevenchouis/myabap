# CDS View 課程練習 11：Analytical Annotation 深入

## Lecture

### 這一課要教什麼

cds07 已經教過基本聚合（`GROUP BY`+`SUM`/`AVG`/`COUNT`）跟 `@DefaultAggregation` 的初探。這一課要更完整地標記一個「真正給分析工具消費」的 CDS View：明確區分哪些欄位是**維度（Dimension，用來分組/篩選的類別欄位）**、哪些是**量值（Measure，可以被聚合加總的數字欄位）**，並正確標記金額欄位的幣別參照——這些標記本身不會改變查詢結果，但會被 Fiori Elements Analytical List Page、SAP Analytics Cloud 這類分析工具讀取，決定畫面要怎麼呈現（哪些欄位可以拖進 Row/Column，哪些可以拖進圖表的數值軸）。

### 語法元素講解

**① `@Analytics.query: true`**：標在整個 View 上，宣告「這是一個給分析場景消費的查詢」。

**② `@Analytics.dimension: true` / `@Analytics.measure: true`**：標在個別欄位上，明確宣告這個欄位的分析角色：

| 標記 | 用途 | 這一課的例子 |
|---|---|---|
| `@Analytics.dimension: true` | 類別型欄位，用來分組／篩選 | `carrid`、`connid`、`currency` |
| `@Analytics.measure: true` | 數字型欄位，可以被加總/平均 | `TotalRevenue`、`TotalSeatsOccupied`、`FlightCount` |

**③ `@Semantics.amount.currencyCode`**：金額欄位要標記「這個金額欄位的幣別，記在哪個欄位」，讓消費端知道怎麼正確顯示金額（例如加千分位、幣別符號）：

```abap
@Semantics.amount.currencyCode: 'currency'
sum( EstimatedRevenue )   as TotalRevenue,
```

### ⚠️ 這一課再次踩到「聚合函數參數不能是運算式」的新變體

cds02 已經發現 `CASE WHEN` 條件不能用運算式；這一課建立 `ZC_CDS11_ROUTE_ANALYTICS` 時，第一次嘗試直接寫：

```abap
sum( Flight.price * Flight.seatsocc )   as TotalRevenue
```

啟用報錯：

```text
Expressions cannot be used as parameters of aggregate functions
```

這是同一類限制的**另一個變體**：`SUM(...)`／`COUNT(...)` 這類聚合函數的參數，一樣不能是運算式，只能是純欄位。**修法完全比照 cds05 學到的分層設計**：先建一個 Layer 1（`ZI_CDS11_FLIGHT_REVENUE`）把 `price * seatsocc` 算成一個獨立欄位 `EstimatedRevenue`，Layer 2（`ZC_CDS11_ROUTE_ANALYTICS`）再對這個已經算好的欄位做 `sum(EstimatedRevenue)`——因為對 Layer 2 來說，`EstimatedRevenue` 是一個普通的來源欄位，不是運算式。

**這是這門課第三次遇到「這系統的某個語法位置不接受運算式，只接受純欄位」的模式**（cds02 的 `CASE WHEN`、cds11 的聚合函數參數），而且**第三次都是靠同一招（先在下一層把運算算好、變成普通欄位）解決**——這代表分層設計不是「風格選擇」，在這個系統上很多時候是**技術上必要的**繞過手段。

### 完整範例

**Layer 1**（`ZI_CDS11_FLIGHT_REVENUE`，明細層級，先把運算算好）：

```abap
@AbapCatalog.sqlViewName: 'ZICDS11FREV'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS11: Flight Interface View with Computed Revenue'
define view ZI_CDS11_FLIGHT_REVENUE
  as select from sflight as Flight
{
  key Flight.carrid,
  key Flight.connid,
  key Flight.fldate,
      Flight.currency,
      Flight.seatsocc,
      Flight.price * Flight.seatsocc   as EstimatedRevenue
}
```

**Layer 2**（`ZC_CDS11_ROUTE_ANALYTICS`，分析層級，正式標記 Dimension/Measure）：

```abap
@AbapCatalog.sqlViewName: 'ZCCDS11RANL'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Analytics.query: true
@EndUserText.label: 'CDS11: Route Revenue Analytics (Dimension/Measure)'
define view ZC_CDS11_ROUTE_ANALYTICS
  as select from ZI_CDS11_FLIGHT_REVENUE
{
      @Analytics.dimension: true
  key carrid,

      @Analytics.dimension: true
  key connid,

      @Analytics.dimension: true
      currency,

      @Analytics.measure: true
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'currency'
      sum( EstimatedRevenue )   as TotalRevenue,

      @Analytics.measure: true
      @DefaultAggregation: #SUM
      sum( seatsocc )            as TotalSeatsOccupied,

      @Analytics.measure: true
      @DefaultAggregation: #COUNT
      count(*)                   as FlightCount
}
group by carrid, connid, currency
```

### 跟 cds07 聚合的銜接

cds07 教的是「怎麼把資料彙總」，這一課教的是「彙總完的欄位，該怎麼正式標記給分析工具用」——兩者是同一件事的不同層次：cds07 的 `GROUP BY`/`SUM` 是**資料庫執行層級**的技巧，這一課的 `@Analytics.dimension`/`@Analytics.measure` 是**中繼資料層級**的標記，後者不影響查詢結果（拿掉這些 annotation，查詢出來的數字完全一樣，這一課的驗證程式已經比對過），純粹是「告訴消費端這個欄位該怎麼用」的說明書。

### Eclipse ADT 建立 CDS View：Step by Step

1. 建 Layer 1 `ZI_CDS11_FLIGHT_REVENUE`：以 `SFLIGHT` 為來源
2. 建 Layer 2 `ZC_CDS11_ROUTE_ANALYTICS`：以 `ZI_CDS11_FLIGHT_REVENUE` 為來源，逐一標記 Dimension/Measure
3. Layer 1 先啟用，Layer 2 才能啟用
4. 用 Data Preview 驗證聚合數字正確（跟 cds08 同一批測試資料，數字應該完全一致）

## Eclipse ADT Step by Step（重點回顧）

1. `ZI_CDS11_FLIGHT_REVENUE`：明細層級，算好 `EstimatedRevenue`
2. `ZC_CDS11_ROUTE_ANALYTICS`：`@Analytics.query: true` + 逐欄位 Dimension/Measure 標記 + `@Semantics.amount.currencyCode`
3. `GROUP BY` 聚合，`sum(EstimatedRevenue)` 引用 Layer 1 已算好的欄位（不是運算式）

## 學習目標

- 能寫出 `@Analytics.query: true`、`@Analytics.dimension: true`、`@Analytics.measure: true` 的正確標記位置
- 能寫出 `@Semantics.amount.currencyCode` 並知道它的作用（讓消費端正確顯示金額）
- 能講出「聚合函數參數不能是運算式」這個實測限制的具體錯誤訊息，並能舉出這是這門課第三次遇到「某語法位置只接受純欄位」模式的例子
- 能講出 Dimension/Measure 標記是中繼資料層級、不影響查詢結果本身這個關鍵區分
- 能講出這一課跟 cds07 聚合的銜接關係（資料庫執行層 vs. 中繼資料標記層）

## 物件清單

| 物件 | 名稱 | 型別 |
|---|---|---|
| CDS Interface View（Layer 1） | `ZI_CDS11_FLIGHT_REVENUE` | `DDLS/DF` |
| CDS Analytics View（Layer 2） | `ZC_CDS11_ROUTE_ANALYTICS` | `DDLS/DF` |
| 驗證程式 | `ZR_CDS11_DEMO` | `PROG/P` |

全部物件都在 `$TMP` 套件，已建立並啟用（讀取 active 版本內容與寫入內容逐字相符）。

## 動手練習（留待後續補做）

1. 幫 `ZC_CDS11_ROUTE_ANALYTICS` 多加一個 Measure（例如平均座位使用率），注意聚合函數參數一樣不能是運算式
2. 在 Eclipse 對著 `ZC_CDS11_ROUTE_ANALYTICS` 用 Data Preview，觀察畫面上有沒有因為 `@Analytics.query: true` 而出現跟一般 View 不一樣的呈現方式
3. 建好後跟我核對語法

## 驗證方式

`ZR_CDS11_DEMO` 透過 `programrun` 無頭驗證，查詢 `carrid = 'LH'` 並跟 cds08 已經驗證過的數字逐筆比對：

```text
=== ZC_CDS11_ROUTE_ANALYTICS (carrid = LH) ===
LH  0400 EUR   2,151,305.97   3,222   16
LH  0401 EUR   1,808,856.00   2,716   15
LH  0402 EUR   3,428,568.00   5,148   15
LH  2402 EUR   1,153,856.00   4,768   15
LH  2407 EUR     304,920.00   1,260   15
=== Sanity check: matches cds08 legacy report numbers for LH ===
MATCH: analytical aggregation reproduces the same numbers as cds08, route count          5
```

`TotalRevenue`（2,151,305.97／304,920.00 等）跟 `FlightCount`（16／15）跟 cds08 的驗證結果完全一致——證實這一課加上的 Dimension/Measure/`@Semantics.amount` 標記，純粹是中繼資料層級的補充說明，不影響實際聚合出來的數字。

**動手練習的驗證方式**：Eclipse 啟用成功＋用 Data Preview 看查詢結果，貼程式碼給我核對語法。

## 思考題

1. 如果拿掉 `@Analytics.dimension: true`／`@Analytics.measure: true` 這些標記，`ZC_CDS11_ROUTE_ANALYTICS` 的查詢結果會不會有任何改變？你會怎麼跟同事解釋這些標記「做了什麼」跟「沒做什麼」？
2. `@Semantics.amount.currencyCode: 'currency'` 指向的是同一個 View 裡的 `currency` 欄位——如果這個 View 沒有幣別欄位（例如彙總了不同幣別的資料，幣別本身不再有意義），你覺得這個 annotation 該怎麼處理？
3. 回顧這門課三次遇到「某語法位置不接受運算式」的案例（cds02 CASE WHEN、cds11 聚合函數），你覺得這系統為什麼會有這種限制？（提示：想想看這系統的 CDS 編譯器版本跟這門課一路強調的「舊語法」背景）

## 答案

見 `zi_cds11_flight_revenue.ddls.abap`、`zc_cds11_route_analytics.ddls.abap`、`zr_cds11_demo.prog.abap`。SAP 端物件：`ZI_CDS11_FLIGHT_REVENUE`（Layer 1）、`ZC_CDS11_ROUTE_ANALYTICS`（Layer 2）、`ZR_CDS11_DEMO`（驗證程式）。動手練習由你在 Eclipse 動手建立，稍後補做，沒有固定答案快照。
