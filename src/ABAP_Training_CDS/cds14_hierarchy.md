# CDS View 課程練習 14：Hierarchy CDS View

## Lecture

### 這一課要教什麼

組織架構、物料 BOM（Bill of Material）、會計科目表——這些資料的共通點是「自我遞迴」：每一列都有一個「父節點」，父節點本身也是同一張表的一列。**Hierarchy CDS View** 是 SAP 官方對這種資料模型的建模方式，用 `@ObjectModel: { dataCategory: #HIERARCHY }` + `@hierarchy.parentChild` annotation 宣告「這個 View 是一棵樹」，讓消費端（Fiori Elements Tree Table、分析工具）知道怎麼呈現父子關係。

**這一課開課前的查證方式，這門課到目前為止最特別的一次**：不是自己寫測試物件驗證語法，是直接讀這系統既有標準物件 `I_GLAccountHierarchyNode`（會計科目表階層，真的在跑的標準物件）的完整原始碼，照抄它的 annotation 結構——比自己猜語法可靠得多。

### 語法元素講解

**① 建表**：Hierarchy CDS View 需要一張自我參照的表，這一課建了 `ZTCDS14_ORGUNIT`（組織架構）：

```abap
define table ztcds14_orgunit {
  key client       : abap.clnt not null;
  key orgunit_id   : abap.char(10) not null;
  parent_id        : abap.char(10);
  orgunit_name     : abap.char(40);
  seq_number       : abap.numc(4);
}
```

`parent_id` 沒有標 `not null`——根節點的 `parent_id` 是空白，代表「沒有父節點」。

**② `@ObjectModel: { dataCategory: #HIERARCHY }`**：宣告這個 View 是一個 Hierarchy。

**③ `@hierarchy.parentChild`**：宣告父子關係怎麼從欄位判斷：

```abap
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
```

- `recurse.parent`／`recurse.child`：告訴框架「這個 View 的哪個欄位是父節點 ID、哪個欄位是自己的 ID」
- `siblingsOrder`：同一層的節點（兄弟節點）該怎麼排序

**④ `@ObjectModel.representativeKey`**：這一課照抄標準物件多加了這個 annotation（標示哪個欄位是這個階層節點的「代表鍵」），雖然實測發現它不是查詢能不能動的關鍵因素，但既然標準物件都這樣寫，保留這個慣例。

### 完整範例

```abap
@EndUserText.label: 'CDS14: Org Unit Hierarchy'
@ObjectModel: { dataCategory: #HIERARCHY }
@ObjectModel.representativeKey: 'OrgUnitId'
@AbapCatalog.sqlViewName: 'ZICDS14ORGH'
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
define view ZI_CDS14_ORGUNIT_HIER
  as select from ztcds14_orgunit
{
  key orgunit_id    as OrgUnitId,
      parent_id     as ParentId,
      orgunit_name  as OrgUnitName,
      seq_number    as SeqNumber
}
```

測試資料是一個兩層組織架構：

```text
ZROOT（CEO Office）
├── ZSALES（Sales Division）
│   ├── ZSALESEU（Sales Europe）
│   └── ZSALESUS（Sales US）
└── ZOPS（Operations）
    └── ZOPSFLT（Flight Operations）
```

**這個 CDS View 本身完整建立、啟用成功**，跟標準物件的 annotation 結構完全對應。

### ⚠️ 誠實記錄：Open SQL 的 `HIERARCHY_DESCENDANTS()` 樹狀查詢語法，這一課沒有在 `programrun` 底下跑通

一般 Open SQL 查這個 View（不做樹狀展開，只是平的查詢）完全沒問題：

```abap
SELECT OrgUnitId, ParentId, OrgUnitName, SeqNumber
  FROM zi_cds14_orgunit_hier
  INTO TABLE @DATA(lt_flat).
```

但如果想用 ABAP SQL 的階層巡覽功能（`HIERARCHY_DESCENDANTS(...)`，可以拿到 `HierarchyRank`／`HierarchyLevel` 這些巡覽用的欄位），這一課**嘗試了六種語法變體，全部被真實編譯器擋下**，逐一記錄如下（這是誠實的除錯過程，不是最終答案）：

1. `HIERARCHY(SOURCE ... START WHERE ... SIBLINGS ORDER BY ...)` → `"START" is invalid here (due to grammar).`
2. 直接 `HIERARCHY_DESCENDANTS(SOURCE zi_cds14_orgunit_hier START WHERE ...)` → `entity must be a hierarchy or exposed via "WITH HIERARCHY"`（即使 CDS View 已經有 `dataCategory: #HIERARCHY` annotation，Open SQL 這一層依然不直接承認）
3. `WITH HIERARCHY zi_cds14_orgunit_hier`（直接指名實體）→ `"ZI_CDS14_ORGUNIT_HIER" is invalid here`（`WITH HIERARCHY` 只接受 CTE 別名，不接受直接的實體名稱）
4. `WITH +hier AS (單純轉發查詢) WITH HIERARCHY +hier` → `The hierarchy "+HIER" was not found and cannot be exposed.`（單純轉發的 CTE 不會自動繼承來源的 Hierarchy 屬性）
5. CTE 裡用 `HIERARCHY(SOURCE ... SIBLINGS ORDER BY ...)`（沒有 `CHILD TO PARENT ASSOCIATION`）→ `"SIBLINGS" is invalid here`
6. CTE 裡用最精簡的 `HIERARCHY(SOURCE zi_cds14_orgunit_hier)`（不帶任何額外子句）→ `")" is invalid here`——`SOURCE` 後面**強制要求** `CHILD TO PARENT ASSOCIATION <association>` 或 `LEVELS (...)` 其中一種

**目前的結論**：這系統的 Open SQL `HIERARCHY(...)` 產生器，似乎只支援官方文件範例展示的「`CHILD TO PARENT ASSOCIATION`」變體（來源本身沒有 Hierarchy annotation，靠一個明確的自我參照 Association 現場組出階層），**不支援直接把一個已經帶 `@hierarchy.parentChild` DDL annotation 的 CDS Entity 當作 `HIERARCHY()` 的 bare SOURCE 使用**。這跟 cds10（Custom Entity）／cds12（Virtual Element）是同一個模式的第三次出現：**某個 CDS 機制的 DDL Annotation，只服務特定的消費框架（這裡看起來是 RAP／Fiori Elements Tree Table），不代表 Open SQL 這一層會自動打通**。

**這一課沒有繼續深挖 `CHILD TO PARENT ASSOCIATION` 變體**（那需要額外設計一個自我參照的 Association，偏離了這一課「CDS Hierarchy 建模」的核心教學目標），**樹狀巡覽的實際效果，留給你在 Eclipse Data Preview 驗證**——Data Preview 對 Hierarchy 型別的 CDS View，官方設計就是會自動呈現成一個可展開/收合的樹狀畫面，不需要透過 Open SQL 查詢語法。

### Eclipse ADT 建立 CDS View：Step by Step

1. 建表 `ZTCDS14_ORGUNIT`：對著 `$TMP` 套件右鍵 → New Database Table，DDL 內容如上
2. 建 CDS View `ZI_CDS14_ORGUNIT_HIER`：Templates 選 **Define View（obsolete as of AS ABAP 7.57）**，內容如上
3. 兩者都啟用後，插入測試資料（可以用這一課的 `ZR_CDS14_SETUP` 驗證程式，或自己在 SE16/SE16N 手動輸入）
4. 對 `ZI_CDS14_ORGUNIT_HIER` 用 **Data Preview**，**這一步請你特別留意畫面呈現方式**——如果 Data Preview 對 Hierarchy 型別的 View 有特殊的樹狀展開效果，這正是這一課想驗證、但 `programrun` 做不到的部分，麻煩截圖回報

## Eclipse ADT Step by Step（重點回顧）

1. `ZTCDS14_ORGUNIT`：自我參照表（`parent_id` 指向同一張表的 `orgunit_id`）
2. `ZI_CDS14_ORGUNIT_HIER`：`@ObjectModel: {dataCategory: #HIERARCHY}` + `@hierarchy.parentChild`，照抄標準物件 `I_GLAccountHierarchyNode` 的結構
3. Data Preview 驗證樹狀呈現效果（這一步無法用 `programrun` 驗證，需要你在 Eclipse 實際操作回報）

## 學習目標

- 能設計一張自我參照的表，正確處理根節點的 `parent_id` 為空
- 能寫出 `@ObjectModel: {dataCategory: #HIERARCHY}` + `@hierarchy.parentChild`（`recurse`/`siblingsOrder`）的完整語法
- 能講出這一課的查證方法（直接讀系統既有標準物件 `I_GLAccountHierarchyNode` 照抄語法），並理解這比自己猜語法可靠
- 能講出「CDS Hierarchy DDL annotation 只服務特定消費框架，Open SQL 的 `HIERARCHY_DESCENDANTS()` 巡覽語法不會自動打通」這個實測發現，並能舉出至少三種嘗試過但失敗的語法變體
- 知道這是這門課第三次遇到「DDL annotation 只服務特定框架、Open SQL 不自動受益」的模式（跟 cds10 Custom Entity、cds12 Virtual Element 同一類）

## 物件清單

| 物件 | 名稱 | 型別 |
|---|---|---|
| 自我參照表 | `ZTCDS14_ORGUNIT` | `TABL/DT` |
| Hierarchy CDS View | `ZI_CDS14_ORGUNIT_HIER` | `DDLS/DF` |
| 測試資料建置程式 | `ZR_CDS14_SETUP` | `PROG/P` |
| 驗證程式 | `ZR_CDS14_DEMO` | `PROG/P` |

全部物件都在 `$TMP` 套件，已建立並啟用（讀取 active 版本內容與寫入內容逐字相符）。

## 動手練習（留待後續補做）

1. 在 Eclipse 對 `ZI_CDS14_ORGUNIT_HIER` 用 Data Preview，實際確認樹狀展開效果，回報畫面截圖
2. 如果你想挑戰 Open SQL 的 `HIERARCHY_DESCENDANTS()` 語法，試著幫 `ZI_CDS14_ORGUNIT_HIER` 額外加一個自我參照的 `association [0..1] to ZI_CDS14_ORGUNIT_HIER as _Parent on _Parent.OrgUnitId = $projection.ParentId`，然後用 `CHILD TO PARENT ASSOCIATION _Parent` 變體重新嘗試這一課記錄的第六種失敗語法，看看能不能成功
3. 建好後跟我核對語法

## 驗證方式

`ZR_CDS14_DEMO` 透過 `programrun` 無頭驗證平面查詢正確（樹狀巡覽語法的除錯過程完整記錄在講義裡，不強行在這裡跑出結果）：

```text
=== ZI_CDS14_ORGUNIT_HIER: plain Open SQL SELECT (flat rows, no tree traversal) ===
ZOPS       ZROOT      Operations
ZOPSFLT    ZOPS       Flight Operations
ZROOT                 CEO Office
ZSALES     ZROOT      Sales Division
ZSALESEU   ZSALES     Sales Europe
ZSALESUS   ZSALES     Sales US
=== Sanity check: all 6 org units present, root has empty ParentId ===
MATCH: hierarchy table data loaded correctly, row count          6
```

六筆組織架構資料正確載入，`ZROOT` 的 `ParentId` 正確是空白——證實底層資料模型跟 Hierarchy CDS View 的欄位對應是正確的。

**動手練習的驗證方式**：Eclipse 啟用成功＋用 Data Preview 看樹狀呈現效果，貼截圖給我核對。

## 思考題

1. 這一課的 `@hierarchy.parentChild` annotation，跟 cds03 教的 Association 語法都是在描述「資料之間的關聯」——兩者的本質差異是什麼？（提示：Association 描述的是「兩個不同實體之間」的關聯，Hierarchy 描述的是什麼？）
2. 如果 `ZTCDS14_ORGUNIT` 的資料出現「循環參照」（例如 A 的父節點是 B，B 的父節點又是 A），你覺得這個 Hierarchy CDS View 的行為會怎樣？
3. 回顧這一課記錄的六種失敗語法嘗試——如果你是第一次遇到這種「官方文件範例語法在這個系統上跑不動」的情境，你會用什麼策略排查，而不是無止盡地憑印象亂猜？

## 答案

見 `ztcds14_orgunit.tabl.abap`、`zi_cds14_orgunit_hier.ddls.abap`、`zr_cds14_setup.prog.abap`、`zr_cds14_demo.prog.abap`。SAP 端物件：`ZTCDS14_ORGUNIT`（表）、`ZI_CDS14_ORGUNIT_HIER`（Hierarchy CDS View）、`ZR_CDS14_SETUP`（測試資料）、`ZR_CDS14_DEMO`（驗證程式）。動手練習由你在 Eclipse 動手建立，稍後補做，沒有固定答案快照。
