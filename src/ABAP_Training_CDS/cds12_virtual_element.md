# CDS View 課程練習 12：Virtual Element

## Lecture

### 這一課要教什麼

前面所有欄位都是資料庫查詢算出來的（不管是原始欄位還是 CAST/運算/聚合的結果，最終都是 SQL 執行的產物）。**Virtual Element** 是完全不同的機制：宣告一個欄位存在，但它的值**不是資料庫查出來的，是執行期由一個 ABAP 類別即時算出來的**（例如需要複雜業務邏輯、呼叫其他系統才能算出的值）。

**⚠️ 這系統用的是比較舊、SADL-based 的 Virtual Element 機制**（`@ObjectModel.virtualElement` + 實作 `IF_SADL_EXIT_CALC_ELEMENT_READ` 的 Exit Class），不是 SAP 較新文件常提到的「CDS Projection View 專屬 Virtual Element」（那個綁在 `define view entity ... as projection on ...` 的新式語法上，這系統不支援）。這門課從 cds01 就一路強調這系統只有舊式 `define view` 可用，這一課是同一條主線在 Virtual Element 這個主題上的延續——好消息是，舊式機制一樣完整可用，語法查證直接讀這系統的標準介面定義確認，不是憑印象猜的。

### 語法元素講解

**① Exit Class 要實作的介面**：直接讀這系統的標準介面定義（不是查文件猜的）：

```abap
INTERFACE if_sadl_exit_calc_element_read PUBLIC.
  INTERFACES if_sadl_exit.

  METHODS get_calculation_info
    IMPORTING it_requested_calc_elements TYPE tt_elements
              iv_entity                  TYPE string
    EXPORTING et_requested_orig_elements TYPE tt_elements
    RAISING   cx_sadl_exit.

  METHODS calculate
    IMPORTING it_original_data           TYPE STANDARD TABLE
              it_requested_calc_elements TYPE tt_elements
    CHANGING  ct_calculated_data         TYPE STANDARD TABLE
    RAISING   cx_sadl_exit.
ENDINTERFACE.
```

兩個方法分工：
- **`get_calculation_info`**：框架呼叫，先問「你要算這個 Virtual Element，需要原始表的哪些欄位？」——回答 `et_requested_orig_elements`
- **`calculate`**：框架把你要的原始欄位資料（`it_original_data`）準備好之後呼叫，你要把算好的值填進 `ct_calculated_data`（跟 `it_original_data` **依索引位置一一對應**，不是用 Key 對應）

**⚠️ 這系統實測出來的一個小陷阱**：`et_requested_orig_elements`（`sadl_entity_element` 型別，底層其實是 `STRING`）用 `VALUE #( ( 'FLDATE' ) )` 這種一般單引號字面值會報型別不相容：

```text
"'FLDATE'" and the row type of "ET_REQUESTED_ORIG_ELEMENTS" are incompatible.
```

要改用**反引號**（Backquote）表示 STRING 型別字面值：`VALUE #( ( \`FLDATE\` ) )` 才會通過——這是 ABAP 語言本身「單引號＝定長字元字面值，反引號＝STRING 字面值」的規則，在這個情境被放大成一個容易踩的坑。

**② CDS View 端的宣告**：

```abap
@ObjectModel.virtualElement: true
@ObjectModel.virtualElementCalculatedBy: 'ABAP:<Exit 類別>'
cast( 0 as abap.int4 )   as DaysUntilDeparture
```

**⚠️ 這裡也有一個不直覺的地方**：欄位清單裡還是要寫一個「看似正常」的運算式（這一課用 `cast( 0 as abap.int4 )` 當佔位符），**不能完全空白**——這個佔位運算式的值在真正透過框架存取時會被 Exit Class 算出來的值蓋掉，但在沒有透過框架的情境（下一節會講）會維持這個佔位值。

### ⚠️ 核心觀念：跟 Custom Entity 一樣，純 Open SQL 不會觸發 Exit Class

這一課的驗證程式做了兩個對照實驗：

**實驗 1**：直接用 Open SQL 查 `ZI_CDS12_FLIGHT_VIRTUAL`（完全不透過任何 RAP／Gateway 框架）：

```text
AA  0017 2018/10/29          0
AA  0017 2018/11/30          0
AA  0017 2019/01/01          0
Result: all rows show DaysUntilDeparture = 0 (the placeholder value), the exit class was NOT triggered via plain Open SQL.
```

`DaysUntilDeparture` 全部都是 `0`——就是 CDS View 裡寫的那個佔位值，**Exit Class 完全沒有被呼叫**。這跟 cds10 學到的「Custom Entity 只有透過 RAP 框架存取才會觸發 Query Provider」是同一個模式，只是這裡換成「Virtual Element 只有透過 SADL／Gateway 框架存取才會觸發 Exit Class」。**這一課用實測直接證明了官方文件的描述是真的**（`ABENCDS_PROJ_VIEW_VIRTEL_ABEXA` 提到「When using ABAP SQL, the class is not accessed」——雖然那份文件講的是新式 RAP Projection View 的 Virtual Element，這一課證實舊式 SADL 機制有一模一樣的行為）。

**實驗 2**：沿用 cds10 學到的技巧——**直接呼叫 Exit Class 的 `calculate` 方法，餵一筆自己組的測試資料，繞過框架驗證邏輯本身對不對**：

```text
Computed DaysUntilDeparture for fldate = today+10:         10
=== Sanity check: exit class correctly computes 10 days ===
MATCH: exit class logic correctly computed the day difference
```

餵一筆 `fldate = 今天+10天` 的資料，`calculate` 方法正確算出 `10`——證實類別內部的計算邏輯是對的，跟 cds10 一樣，**這只驗證了「類別邏輯正確」，不驗證「CDS View 到 Exit Class 這條綁定真的在真實框架呼叫下會生效」**，後者一樣需要 Service Binding（Eclipse-only）才能完整驗證。

### Eclipse ADT 建立 CDS View：Step by Step

1. 建 Exit Class `ZCL_CDS12_DAYS_CALC`：實作 `IF_SADL_EXIT_CALC_ELEMENT_READ`，**注意 `get_calculation_info` 裡要用反引號字串字面值**
2. 建 CDS View `ZI_CDS12_FLIGHT_VIRTUAL`：以 `SFLIGHT` 為來源，Virtual Element 欄位用 `cast(0 as abap.int4)` 當佔位運算式，兩個 annotation（`virtualElement`／`virtualElementCalculatedBy`）都要標
3. 類別先啟用，CDS View 才能正確解析 annotation 指向的類別
4. Data Preview／Open SQL 都只會看到佔位值 `0`，這是預期行為，不是失敗——要看到真正算出來的值，需要透過 Service Binding

## Eclipse ADT Step by Step（重點回顧）

1. `ZCL_CDS12_DAYS_CALC`：實作 `IF_SADL_EXIT_CALC_ELEMENT_READ` 的 `get_calculation_info`／`calculate` 兩個方法
2. `ZI_CDS12_FLIGHT_VIRTUAL`：`@ObjectModel.virtualElement: true` + `@ObjectModel.virtualElementCalculatedBy`
3. Open SQL／Data Preview 只會看到佔位值，這是預期行為

## 學習目標

- 能講出這系統用的是舊式 SADL-based Virtual Element 機制（`@ObjectModel.virtualElementCalculatedBy` + `IF_SADL_EXIT_CALC_ELEMENT_READ`），跟新式 RAP Projection View Virtual Element 是兩回事
- 能寫出 Exit Class 的兩個方法（`get_calculation_info`／`calculate`）各自的職責
- 能講出 `sadl_entity_element` 型別要用反引號字串字面值賦值的實測限制
- 能講出「Virtual Element 只有透過框架存取才會觸發 Exit Class，純 Open SQL 只會看到佔位值」這個核心觀念，並用這一課的實測結果佐證
- 能講出「直接呼叫 Exit Class 方法驗證邏輯」這個技巧驗證了什麼、沒驗證到什麼

## 物件清單

| 物件 | 名稱 | 型別 |
|---|---|---|
| Virtual Element Exit 類別 | `ZCL_CDS12_DAYS_CALC` | `CLAS/OC` |
| CDS View | `ZI_CDS12_FLIGHT_VIRTUAL` | `DDLS/DF` |
| 驗證程式 | `ZR_CDS12_DEMO` | `PROG/P` |

全部物件都在 `$TMP` 套件，已建立並啟用（讀取 active 版本內容與寫入內容逐字相符）。

## 動手練習（留待後續補做）

1. 修改 `ZCL_CDS12_DAYS_CALC`，改成計算「距離某個固定紀念日還有幾天」，而不是距今天
2. 試著建一個 Service Definition＋Service Binding，用 Eclipse Preview 實際驗證 `DaysUntilDeparture` 透過 OData 存取時是不是真的算出正確的值（不是佔位值 `0`）
3. 建好後跟我核對語法

## 驗證方式

`ZR_CDS12_DEMO` 透過 `programrun` 無頭驗證兩件事：① Open SQL 查詢只看得到佔位值（Exit Class 未被觸發）；② 直接呼叫 Exit Class 驗證計算邏輯本身正確：

```text
=== Attempt 1: plain Open SQL SELECT against the virtual-element view ===
AA  0017 2018/10/29          0
AA  0017 2018/11/30          0
AA  0017 2019/01/01          0
Result: all rows show DaysUntilDeparture = 0 (the placeholder value), the exit class was NOT triggered via plain Open SQL.
=== Attempt 2: call ZCL_CDS12_DAYS_CALC directly to verify its own logic ===
Computed DaysUntilDeparture for fldate = today+10:         10
=== Sanity check: exit class correctly computes 10 days ===
MATCH: exit class logic correctly computed the day difference
```

**動手練習的驗證方式**：Eclipse 啟用成功即可；如果做了 Service Binding，用 Eclipse Preview 貼截圖給我核對。

## 思考題

1. 為什麼 Virtual Element 的值不能直接寫進資料庫表？如果硬要把 `DaysUntilDeparture` 這種值存進表裡，會有什麼實務上的問題？（提示：這個值每天都在變）
2. `get_calculation_info` 跟 `calculate` 分成兩個方法呼叫，而不是一個方法直接做完——你覺得這樣設計的用意是什麼？（提示：想想看如果原始資料表有 20 個欄位，但這次呼叫只需要算一個只依賴其中 1 個欄位的 Virtual Element）
3. 回顧 cds10（Custom Entity）跟這一課（Virtual Element），兩者都有「純 Open SQL 不會觸發框架邏輯」的限制——你覺得 SAP 為什麼要這樣設計，而不是讓 Open SQL 也觸發？

## 答案

見 `zcl_cds12_days_calc.clas.abap`、`zi_cds12_flight_virtual.ddls.abap`、`zr_cds12_demo.prog.abap`。SAP 端物件：`ZCL_CDS12_DAYS_CALC`（Exit 類別）、`ZI_CDS12_FLIGHT_VIRTUAL`（CDS View）、`ZR_CDS12_DEMO`（驗證程式）。動手練習由你在 Eclipse 動手建立，稍後補做，沒有固定答案快照。
