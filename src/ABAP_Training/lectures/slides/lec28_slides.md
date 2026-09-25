---
marp: true
theme: default
paginate: true
headingDivider: false
style: |
  section {
    font-family: 'Microsoft JhengHei', 'Noto Sans TC', sans-serif;
    font-size: 26px;
    padding: 60px;
  }
  section.lead {
    text-align: center;
    justify-content: center;
  }
  section.lead h1 { font-size: 56px; }
  code, pre {
    font-family: Consolas, 'Courier New', monospace;
  }
  pre {
    font-size: 21px;
    line-height: 1.45;
  }
  table { font-size: 23px; }
  section.compact pre { font-size: 19px; }
  section.compact table { font-size: 20px; }
  blockquote {
    border-left: 6px solid #0a6ed1;
    padding-left: 16px;
    color: #333;
    background: #eef6fc;
  }
  footer { color: #999; }
---

<!-- _class: lead -->
<!-- _paginate: false -->

# 講義 28
# 客製 Table Maintenance 的
# 權限防護與並行控制

ABAP 基礎教育訓練（進階選修，接在講義 27 之後）

對應練習 ex28｜`ZTR28_CDISC`／`ZTR28_CARR`／`EZTR28_CARR`／`ZR_TR28_PARAM_MAINT`／`ZR_TR28_PRICE_CALC`

---

## 本講重點

- SM30 原生權限不夠用：業務維度要自己包一層
- 自訂**權限物件**（SU21）：`ACTVT` ＋ `CARRID`
- **PFCG** 角色維護：權限物件才真正生效
- Lock Object 鎖定範圍對應「爭搶的資源邊界」
- `VIEW_MAINTENANCE_CALL`：正規呼叫 Table Maintenance
- T-code 指給 **Wrapper**，不是裸的 SM30
- `SELECTION-SCREEN FUNCTION KEY` ＋ Parameter Transaction
- 維護的參數會被下游報表拿去**算錢**

> 六項 GUI-only 步驟（SU21、PFCG、SE11、SM30 產生器、兩個 SE93）都沒有 ADT，逐一附操作路徑

---

## 1. 為什麼要包一層 Authorization Wrapper

SM30 原生用 `S_TABU_DIS`／`S_TABU_NAM` 控管
→ 只回答「能不能維護**這張表**」（表格層級）

實務需求：「王小明只能改長榮(BR)的折扣，李小美只能改華航(CI)」
→ **業務維度**權限，SM30 做不到

**解法**：T-code 不指給 SM30，指給自己寫的 **Wrapper 程式**

1. **權限檢查**：對「這家航空公司」有沒有維護權限
2. **上鎖**：避免同一家公司兩人同時維護（講義 27）

兩關都過，才呼叫標準機制進入維護畫面

---

## 2. SM30 Table Maintenance Generator

1. 先在 SE80 建 Function Group `ZFG_TR28B`
2. SE11 → 表 `ZTR28_CDISC` → Utilities → Table Maintenance Generator
3. Authorization Group `&NC&`、Function Group `ZFG_TR28B`、**One Step**
4. 先用 SM30 直接測試，確認 View 本身能新增／修改

這一步只確認 View 能動，還沒有套用 Wrapper 的權限／鎖定

---

<!-- _class: compact -->

## 3. 自訂權限物件：SU21

1. SU21 → 選 Object Class（本例 **`BC_A`**；`BC` 本身不存在，是分類字首）→ 右鍵 Create
2. Object 輸入 `ZTR28_CARR`（**權限物件名稱上限 10 碼**）
3. **Authorization Fields** 加兩個欄位：
   - `ACTVT`：做什麼（`01` 新增、`02` 變更、`03` 顯示…）
   - `CARRID`：對誰（哪家航空公司）
4. 存檔（Local Object）→ Activate
   （黃色警告「Permissible activities not maintained」可先忽略）

> ⚠️ 權限物件 `ZTR28_CARR`（無 S）跟 Lock Object `EZTR28_CARR`（有 S、`E` 開頭）拼法相近，別看錯

---

## 3.1 AUTHORITY-CHECK

```abap
AUTHORITY-CHECK OBJECT 'ZTR28_CARR'
  ID 'ACTVT'  FIELD lv_actvt
  ID 'CARRID' FIELD p_carrid.

IF sy-subrc <> 0.
  " 沒有權限
ENDIF.
```

| sy-subrc | 意義 |
|---|---|
| 4 | 有這個物件的授權，但**值對不上** |
| 12 | User Master 裡**完全沒有**這個物件的授權（通常 PFCG 角色還沒指派） |

**權限物件只定義「有哪些欄位可管控」**
真正「誰對什麼值有權限」要靠 PFCG，沒做前 `AUTHORITY-CHECK` 一律失敗

---

<!-- _class: compact -->

## 3.2 PFCG：把權限真正指派給使用者

1. **PFCG** → Role `ZTR28_MAINT_ROLE` → **Single Role** → Description 存檔
2. **Menu**：Transaction 按鈕 → 加入 T-code `ZTR28_MAINT`
3. **Authorizations** → Change Authorization Data：
   - `S_TCODE` 自動帶入，但**不會**帶入自訂的 `ZTR28_CARR`
   - **Manually** 手動加入 `ZTR28_CARR`
   - `ACTVT` = `02`（可加 `03`）、`CARRID` = `LH`（教學先只給 LH）
4. **Generate**（產生 Profile）→ Enter 接受預設
5. **User** 頁籤 → 輸入自己的 User ID
6. **User Comparison** → Complete Comparison
7. 存檔

驗證：重新登入後執行 `ZTR28_MAINT`（`LH`）；失敗用 **SU53** 排查

---

## 4. Lock Object 鎖定範圍

`ZTR28_CDISC` 主鍵是 `MANDT`＋`CARRID`
Lock Object `EZTR28_CARR` 的 Lock Parameters 剛好是這兩個欄位

業務需求「同一家航空公司不能有兩人同時維護」
→ 鎖定範圍與主鍵一致

**鎖定範圍要對應「使用者實際爭搶的資源邊界」**
不是機械式照抄主鍵，也不是為了不同而刻意鎖粗

SE11 步驟同講義 27：Primary Table `ZTR28_CDISC`、
勾 `MANDT`／`CARRID`、Lock Mode `E`

---

<!-- _class: compact -->

## 5. VIEW_MAINTENANCE_CALL

```abap
CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
  EXPORTING
    action    = 'U'          " U 維護、S 只顯示、T 帶 Transport
    view_name = 'ZTR28_CDISC'
  EXCEPTIONS
    foreign_lock = 2
    OTHERS       = 6.
```

- 比 `CALL TRANSACTION 'SM30'` 乾淨：可指定 View、繞過初始畫面
- 內部**再做一次**自己的權限檢查（`S_TABU_DIS`／`S_TABU_NAM`）與再上一次 View 鎖
- 兩層互不衝突：Wrapper 管**業務維度**，這支 FM 管**表格層級**
- `action = 'S'` ＋ `ACTVT = '03'` → 「只能看、不能改」模式

---

<!-- _class: compact -->

## 5.1 dba_sellist：只顯示被授權的那家

只做 `AUTHORITY-CHECK` 不夠：進了畫面仍看得到、改得到別家

```abap
ls_sellist-viewfield = 'CARRID'.    " 篩選欄位（大寫）
ls_sellist-operator  = 'EQ'.        " EQ／NE／GT／GE／LT／LE／LK
ls_sellist-value     = p_carrid.
ls_sellist-tabix     = 1.
APPEND ls_sellist TO lt_sellist.

CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
  EXPORTING action = 'U' view_name = 'ZTR28_CDISC'
  TABLES    dba_sellist = lt_sellist ...
```

效果類似先套一個 `WHERE` → 畫面只列 `CARRID = p_carrid`

> ⚠️ 會開出完整畫面等使用者操作 → **不能用 `programrun` 無頭驗證**
> 若已 ENQUEUE，斷線時不會跑到 DEQUEUE，鎖會殘留（排查見講義 27 第 7 節）

---

## 6. T-code 指給 Wrapper

SE93 → `ZTR28_MAINT` → Create

1. 型態：**Program and selection screen (Report transaction)**
2. Program 填 `ZR_TR28_PARAM_MAINT`（**不是** SM30）
3. Selection Screen 填 `1000`
4. 存檔

若 T-code 直接指給 SM30，或把 `S_TABU_DIS` 開放給所有人
→ 使用者繞過 Wrapper，前面的檢查與鎖**形同虛設**

實務：一般使用者角色**不給** SM30 權限，只給 Wrapper 的 T-code

---

## 7. 選取畫面按鈕：FUNCTION KEY

```abap
TABLES: sscrfields.

PARAMETERS: p_carrid TYPE spfli-carrid DEFAULT 'LH' OBLIGATORY,
            p_connid TYPE spfli-connid DEFAULT '0400' OBLIGATORY.

SELECTION-SCREEN FUNCTION KEY 1.

INITIALIZATION.
  sscrfields-functxt_01 = '維護主檔(SM30)'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      CALL TRANSACTION 'ZTR28_SM30'.
  ENDCASE.
```

`FUNCTION KEY 1～4` 對應 `'FC01'～'FC04'`（系統保留代碼）
按鈕文字在 `INITIALIZATION` 設 `functxt_01～04`

---

<!-- _class: compact -->

## 7.1 Parameter Transaction `ZTR28_SM30`

SE93 → `ZTR28_SM30` → Create

1. 型態：**Transaction with parameters**
2. **Default values for → Transaction**：`SM30`
3. 勾 **Skip initial screen**
4. ⚠️ 不是上方 SPA/GPA 表格，而是畫面下方獨立的 **Default Values**：
   - `VIEWNAME` = `ZTR28_CDISC`
   - `UPDATE` = `X`
5. 存檔

`VIEWNAME`／`UPDATE` 是 SM30 初始畫面的**實際技術欄位名**
直接指定畫面欄位值，跟 SPA/GPA 是兩種不同機制

---

<!-- _class: compact -->

## 7.2 故意示範「沒有保護」的按鈕

| | `PRICE_CALC` 的按鈕 | `PARAM_MAINT`（`ZTR28_MAINT`） |
|---|---|---|
| 呼叫方式 | `CALL TRANSACTION 'ZTR28_SM30'` | 完整 Wrapper 流程 |
| 業務權限（`ZTR28_CARR`） | ❌ | ✅ |
| Lock Object | ❌ | ✅ |
| 資料篩選（單一航空公司） | ❌ 整張表都看得到 | ✅ `dba_sellist` |
| 適合場景 | 純示範對照 | 一般使用者正式入口 |

同樣是「從另一支程式跳進主檔維護」
**有沒有包 Wrapper，資安上天壤之別**
按鈕存在本身就是提醒：「這樣寫是不對的」

---

## 8. 整體流程

```
使用者按「維護主檔(SM30)」或直接執行 ZTR28_MAINT
      ▼
S_TCODE 權限檢查（誰能執行這個 T-code）
      ▼
ZR_TR28_PARAM_MAINT 選取畫面：輸入航空公司
      ▼
AUTHORITY-CHECK 'ZTR28_CARR'（業務維度權限）
      ▼
ENQUEUE_EZTR28_CARR（這家有沒有人在維護）
      ▼
VIEW_MAINTENANCE_CALL（自己還有 S_TABU_DIS＋View 鎖）
      ▼
DEQUEUE_EZTR28_CARR
```

四層防護疊在一起，缺任一層都可能被繞過

---

<!-- _class: compact -->

## 9. 維護的參數不是憑空存在

`ZR_TR28_PRICE_CALC`：JOIN `SPFLI`／`SFLIGHT` 套用折扣算最終票價

```abap
SELECT SINGLE discount_pct
  INTO lv_discount_pct
  FROM ztr28_cdisc
  WHERE carrid = p_carrid.
IF sy-subrc <> 0.
  lv_discount_pct = 0.        " 折扣是選配，查不到不擋報表
ENDIF.
gs_result-final_price = ls_sflight-price * ( 1 - lv_discount_pct / 100 ).
```

1. 這支報表**不需要** Wrapper：只「讀」不「寫」
2. 折扣查不到要有**合理預設**（0%），不能讓報表掛掉
3. 驗證利器：在 Wrapper 改折扣 → 立刻跑報表看 `final_price` 變不變

---

## 9.1 REUSE_ALV_GRID_DISPLAY 在無頭環境

| ALV 寫法 | `programrun` 無頭執行 |
|---|---|
| `REUSE_ALV_GRID_DISPLAY`（Functional） | 自動退化成**文字清單**，可直接驗證資料 |
| `cl_salv_table`（OO） | **卡住斷線**（`RFC_CLOSED`） |

⚠️ 不是絕對可靠：某個特定物件 `programrun` 卡過一次，之後不管怎麼改都持續卡住
→ 用全新物件重現，若新物件正常 → 請使用者到 SAP GUI 測

---

## 10. Selection Texts

選取畫面預設顯示技術名稱（`P_CARRID`、`P_CONNID`、`P_DISP`）

SE38 → 程式 → **Goto → Text Elements → Selection Texts**
逐一填入說明 → 存檔 → Activate

- 跟 Text Symbols 同類：**沒有 ADT API**，只能手動維護
- 純粹改善操作體驗，不影響權限／鎖定／篩選邏輯

---

<!-- _class: lead -->

# 課堂練習

完成 **ex28**：

SU21 權限物件、PFCG 角色、Lock Object、
SM30 產生器、兩個 SE93 T-code，
並跑完「權限—鎖定—篩選—計算」的完整測試流程
