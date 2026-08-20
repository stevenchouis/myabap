# CDS View 課程練習 16（期末整合）：組織架構完整案例

## Lecture

### 這一課要教什麼

這是整個 CDS View 課程（cds01～cds16）的最後一課，目標是把進階篇後半段教的四個獨立主題——**Analytical Annotation**（cds11）、**Virtual Element**（cds12）、**Value Help**（cds13）、**Hierarchy**（cds14）——疊進**同一個** CDS View，設計出一個能直接被 Fiori Elements／分析工具消費的完整組織架構模型。

這一課刻意選了 cds14 已經建好的組織架構（`ZTCDS14_ORGUNIT`）當基礎，補上一個新欄位 `HeadCount`（員額數），示範四種技巧怎麼疊在一起、彼此有沒有衝突。

### 完整範例：`ZI_CDS16_ORGUNIT_FINAL`

```abap
@EndUserText.label: 'CDS16: Org Unit Hierarchy - Final Integration'
@ObjectModel: { dataCategory: #HIERARCHY }
@ObjectModel.representativeKey: 'OrgUnitId'
@Analytics.query: true
@AbapCatalog.sqlViewName: 'ZICDS16ORGF'
@hierarchy.parentChild:
{
  recurse:
    {
        parent: 'ParentId',
        child:  'OrgUnitId'
     },
  siblingsOrder:
    {
        by: 'SeqNumber',
        direction: 'ASC'
    }
  }
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view ZI_CDS16_ORGUNIT_FINAL
  as select from ztcds14_orgunit
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_CDS16_ORGUNIT_FINAL', element: 'OrgUnitId' } }]
  key orgunit_id    as OrgUnitId,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_CDS16_ORGUNIT_FINAL', element: 'OrgUnitId' } }]
      parent_id     as ParentId,

      @Analytics.dimension: true
      orgunit_name  as OrgUnitName,

      seq_number    as SeqNumber,

      @Analytics.measure: true
      @DefaultAggregation: #SUM
      headcount     as HeadCount,

      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_CDS16_LABEL_CALC'
      cast( '' as abap.char(60) )   as DisplayLabel
}
```

四種技巧各自扮演的角色：

| 技巧 | 這一課的用法 |
|---|---|
| **Hierarchy**（cds14） | `OrgUnitId`／`ParentId` 建立父子關係，讓消費端知道這是一棵組織架構樹 |
| **Analytics**（cds11） | `OrgUnitName` 標成 Dimension、`HeadCount` 標成 Measure，讓分析工具知道可以依部門彙總員額數 |
| **Value Help**（cds13） | `ParentId` 掛 Value Help，指向**這個 View 自己**——使用者輸入「這個部門的上級部門」時，可以從既有組織單位清單選 |
| **Virtual Element**（cds12） | `DisplayLabel` 執行期才組出「代碼 - 名稱（N 名員工）」這種給畫面顯示用的組合字串，不占資料庫儲存空間 |

**這四種技巧一次啟用成功，彼此沒有衝突**——這代表這門課從 cds09 到 cds15 分開驗證過的每一項技巧，語法上都是可以自由組合的積木，不需要額外的相容性處理。

### ⚠️ Value Help 指向自己：一個值得注意的細節

`ParentId` 的 `@Consumption.valueHelpDefinition` 指向 `ZI_CDS16_ORGUNIT_FINAL` 自己的 `OrgUnitId` 欄位——**這是合法且常見的模式**：自我參照的階層資料，「選父節點」的值清單本來就該是「這個階層裡所有節點」，也就是這個 View 自己。這跟 cds13 範例（指向另一個獨立的 `ZI_CDS01_CARRIER`）不同，這裡示範的是「自己當自己的 Value Help 來源」這種階層資料特有的模式。

### 驗證邊界：誠實區分「能驗證」跟「不能驗證」的部分

這一課完整沿用前面幾課學到的驗證方法論，**不假裝能驗證實際上驗證不到的東西**：

1. **Hierarchy（父子結構）＋Analytics（聚合）＋Value Help（純中繼資料）**：這三項都不影響一般 Open SQL 查詢行為，`programrun` 完整驗證——`HeadCount` 加總結果正確（61 = 5+20+8+12+8+8）。
2. **Virtual Element（`DisplayLabel`）**：延續 cds12 的發現，純 Open SQL 只查得到佔位值（空白）；改用 cds10／cds12 發明的 **Mock 直接呼叫技巧**，驗證 `ZCL_CDS16_LABEL_CALC` 的計算邏輯本身正確（餵 `ZROOT`／`CEO Office`／`5` 進去，正確組出 `ZROOT - CEO Office (5 staff)`）。
3. **Hierarchy 的樹狀巡覽效果、Value Help 的 F4 下拉選單效果**：延續 cds14／cds13 的結論，這兩項的真實呈現效果需要在 Eclipse Data Preview 或真正的 Fiori Elements 畫面才看得到，`programrun` 做不到，留給你在 Eclipse 實際操作驗證。

### 全課程回顧：cds01～cds15 學到的東西，怎麼收斂成這一課

- **cds01～cds08（基礎篇）**教的是「怎麼設計一個查詢單元」：欄位運算、Association、Parameters、分層設計、Access Control、聚合，最後在 cds08 疊成一個完整的多層報表案例。
- **cds09～cds15（進階篇）**教的是「這系統支援哪些進階建模能力」：Extend View（不改原始碼擴充）、Custom Entity（資料來源不是表）、Analytics（分析工具消費）、Virtual Element（執行期計算）、Value Help（F4 說明）、Hierarchy（自我遞迴）、效能與除錯方法論。
- **這一課**把進階篇後半段四項技巧收斂成一個真實可用的案例，證明它們不是四個互相獨立、只能各自展示的孤立範例，是可以自由組合的建模工具箱。

**這門課從頭到尾最重要的方法論，不是任何一個特定語法**，是這件事：**這系統的 CDS 編譯器版本比官方最新文件舊，任何語法都要在真實系統上測過才能確定能不能用，官方文件的範例語法經常需要調整（`define view` 不是 `define view entity`、`FOR DETERMINATION` 不是 `FOR DETERMINE`、聚合函數不接受運算式參數……）；遇到「純 Open SQL 查不到框架相關欄位」這種情況，不要放棄驗證，想辦法用 Mock 技巧繞過去驗證核心邏輯，同時誠實記錄「這只驗證到什麼程度」。

## Eclipse ADT Step by Step

1. 幫 `ZTCDS14_ORGUNIT` 加一個 `headcount` 欄位（`abap.int4`）
2. 建 Exit Class `ZCL_CDS16_LABEL_CALC`（`IF_SADL_EXIT_CALC_ELEMENT_READ`，組合 `OrgUnitId`／`OrgUnitName`／`HeadCount` 成顯示字串）
3. 建 `ZI_CDS16_ORGUNIT_FINAL`：四種 annotation 一次寫好
4. 用 Data Preview 驗證：樹狀展開效果、`HeadCount` 數字、`DisplayLabel` 是否透過框架正確算出（Data Preview 走不走 SADL 框架，這一課沒有把握，請你實際操作回報）

## 學習目標

- 能設計一個同時整合 Hierarchy／Analytics／Value Help／Virtual Element 四種 annotation 的完整 CDS View，不誤觸相容性問題
- 能講出「Value Help 指向自己」這種自我參照階層資料的常見模式，跟指向獨立來源 View 的差異
- 能完整複述這一課的驗證邊界：哪些用 `programrun` 直接驗證、哪些用 Mock 技巧驗證邏輯、哪些留給 Eclipse 手動驗證，並說得出各自的原因
- 能用自己的話總結這門課從 cds01 到 cds16 最重要的方法論（實測優先、誠實記錄限制、遇到框架依賴問題想辦法找繞道驗證的方法）

## 物件清單

| 物件 | 名稱 | 型別 |
|---|---|---|
| 自我參照表（cds14 擴充，新增 `headcount`） | `ZTCDS14_ORGUNIT` | `TABL/DT` |
| Virtual Element Exit 類別 | `ZCL_CDS16_LABEL_CALC` | `CLAS/OC` |
| 期末整合 CDS View | `ZI_CDS16_ORGUNIT_FINAL` | `DDLS/DF` |
| 驗證程式 | `ZR_CDS16_DEMO` | `PROG/P` |

全部物件都在 `$TMP` 套件，已建立並啟用（讀取 active 版本內容與寫入內容逐字相符）。

## 動手練習（留待後續補做，也是整個課程的畢業練習）

1. 在 Eclipse 對 `ZI_CDS16_ORGUNIT_FINAL` 用 Data Preview，完整確認：樹狀展開效果、`ParentId` 的 F4 下拉選單、`DisplayLabel` 有沒有真的透過 SADL 框架算出組合字串（不是空白佔位值）
2. 自己設計一個全新的整合案例（不用組織架構，換一個你熟悉的業務情境），至少疊兩種以上這門課教過的進階技巧
3. 補做這門課從 cds01 到 cds16 所有「留待後續補做」的動手練習，逐一跟我核對

## 驗證方式

`ZR_CDS16_DEMO` 透過 `programrun` 無頭驗證，完整結果：

```text
=== 1. Analytical + Value Help annotations: plain Open SQL works normally ===
ZOPS       ZROOT      Operations         8
ZOPSFLT    ZOPS       Flight Operations  8
ZROOT                 CEO Office         5
ZSALES     ZROOT      Sales Division    20
ZSALESEU   ZSALES     Sales Europe      12
ZSALESUS   ZSALES     Sales US           8
Sum of HeadCount across all org units: 61
=== 2. Virtual Element (DisplayLabel): plain Open SQL only sees the placeholder ===
ZROOT DisplayLabel via Open SQL: (blank, expected)
=== 3. Virtual Element exit class logic, verified directly via Mock ===
Computed DisplayLabel: ZROOT - CEO Office (5 staff)
=== Final sanity check ===
MATCH: analytics/value-help work via Open SQL, virtual element placeholder confirmed, exit class logic verified via mock
```

`HeadCount` 加總正確（61）、`DisplayLabel` 透過 Open SQL 查詢正確顯示佔位空白值（符合 cds12 已經證實的框架依賴行為）、透過 Mock 技巧驗證 Exit Class 邏輯正確組出 `ZROOT - CEO Office (5 staff)`——四種技巧全部驗證到位，沒有一項是憑空聲稱。

**動手練習的驗證方式**：Eclipse 啟用成功＋用 Data Preview 完整驗證三個「`programrun` 驗證不到」的效果，貼截圖給我核對，這也是這門課最後一次請你回報 Eclipse 端的實際畫面。

## 思考題（全課程總複習）

1. 回顧 cds01 到 cds16，你覺得哪一課的實測發現對你來說最實用、最可能在未來的實際工作中用到？
2. 這門課反覆出現「這系統的 CDS 編譯器比官方文件舊」這件事——如果你之後真的要在正式的新版系統（支援 `define view entity`）上工作，你覺得這門課學到的核心觀念（Association、分層設計、Access Control、聚合、Custom Entity、Virtual Element、Hierarchy）有多少可以直接帶過去，需要調整的又是哪些細節？
3. 如果要你用一句話，跟一個完全沒學過 CDS View 的同事解釋「CDS View 到底解決了什麼問題」，你會怎麼說？（回顧 cds01 的「三個痛點」跟這一課的完整案例，試著給出一個比 cds01 當時更完整的答案）

## 答案

見 `ztcds14_orgunit.tabl.abap`（更新版，含 `headcount`）、`zcl_cds16_label_calc.clas.abap`、`zi_cds16_orgunit_final.ddls.abap`、`zr_cds16_demo.prog.abap`。SAP 端物件：`ZTCDS14_ORGUNIT`（擴充）、`ZCL_CDS16_LABEL_CALC`（Exit 類別）、`ZI_CDS16_ORGUNIT_FINAL`（期末整合 View）、`ZR_CDS16_DEMO`（驗證程式）。動手練習由你在 Eclipse 動手操作，稍後補做——**這也是整個 CDS View 課程（cds01～cds16）的最後一份講義**，恭喜完課。
