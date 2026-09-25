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

# 講義 15
# Function Module——SE37 與 CALL FUNCTION

ABAP 基礎教育訓練（授課順序：接在講義 8 之後）

對應練習 ex15｜答案：`ZFG_TR15` / `Z_TR15_CALC_REVENUE` / `ZR_TR15_CALL_FM`

---

## 本講重點

- Function Module（FM）的定位：**跨程式共用**的邏輯單位
- Function Group：FM 的容器——一個 group 可放多個 FM
- TOP include 全域變數：同 group 的 FM 共用同一份資料
- 介面四區：IMPORTING / EXPORTING / CHANGING / TABLES ＋ EXCEPTIONS
- 傳整張表：`CHANGING` + DDIC Table Type 取代 `TABLES`
- SE37 建立與單獨測試
- `CALL FUNCTION` 呼叫：方向對應與例外處理
- FM vs FORM 的選擇

---

## 1. FM 是什麼、跟 FORM 差在哪

FORM 只能在同一支程式裡呼叫；FM 是**全系統共用**
講義 8 是「程式內」模組化，FM 擴大到「全系統」
之後講義 9 的 ALV（`REUSE_ALV_GRID_DISPLAY`）也是標準 FM

| | FORM | Function Module |
|---|---|---|
| 共用範圍 | 本程式內 | 全系統 |
| 單獨測試 | 不行 | SE37 直接測 |
| 介面 | USING / CHANGING | IMPORTING / EXPORTING / CHANGING / TABLES + EXCEPTIONS |
| 容器 | 報表程式 | Function Group |
| 定位 | 程式內部拆段 | 跨程式共用、RFC、BAPI 的基礎 |

**Function Group**：FM 不能單獨存在，掛在 `ZFG_xxx` 底下
同 group 的 FM 共用全域資料——同主題收同一個 group

---

<!-- _class: compact -->

## Function Group：一個 group 放多個 FM

Function Group = 一支特殊程式（`SAPLZFG_TR15`）＋一組 include
（include：被原地展開的程式碼片段，講義 14 細講）：

| Include | 內容 |
|---|---|
| `LZFG_TR15TOP` | **TOP：全域宣告**（`DATA`／`TYPES`） |
| `LZFG_TR15UXX` | 系統維護，列出所有 FM include |
| `LZFG_TR15U01`、`U02`… | **每個 FM 各一個 include** |
| `LZFG_TR15F01`（選用） | group 內共用的 FORM |

- **一個 FM 只屬一個 group；一個 group 可放很多 FM**
- 同主題、要共用資料的 FM 放同一個 group；沒共用就不必硬塞
- 呼叫端只認 FM 名稱，不需要知道它在哪個 group

---

<!-- _class: compact -->

## TOP include 全域變數：同 group 的 FM 共用同一份

```abap
* TOP include
DATA: gv_total_revenue TYPE s_price,
      gv_call_count    TYPE i.

FUNCTION z_tr15_add_revenue.          " 累加
  gv_total_revenue = gv_total_revenue + iv_revenue.
  gv_call_count    = gv_call_count + 1.
ENDFUNCTION.

FUNCTION z_tr15_get_total.            " 讀取（自己沒累加）
  ev_total = gv_total_revenue.  ev_count = gv_call_count.
ENDFUNCTION.
```

呼叫 `ADD_REVENUE` 三次（50000／40000／36000），只傳單筆、沒有變數帶回
→ 另一支 `GET_TOTAL` 讀到 **126,000.00／3**（同一份全域變數）

---

<!-- _class: compact -->

## 生命週期與注意事項

- **載入**：group 內任何一支 FM 第一次被呼叫時整個載入，全域變數從初始值開始
- **範圍**：這次 session 的這個 group；不同 session 各自一份，**不同 group 看不到彼此**
- **隱藏前提**：呼叫順序影響結果，介面看不出來 → 用前先 `RESET`
- **難測難追蹤**：行為取決於「之前發生過什麼」
- TOP 宣告能用在 FM **本體**，但**不能**用在 FM **介面**型別（要 DDIC 型別）
- 定位：傳統 FM 能力，舊程式常見；新世代用 Class 的 instance 屬性（狀態明確、可建多份）

---

<!-- _class: compact -->

## 2. 定義介面（`Z_TR15_CALC_REVENUE`）

```abap
FUNCTION z_tr15_calc_revenue
  IMPORTING
    VALUE(iv_price)    TYPE s_price       " 收進來：票價
    VALUE(iv_seatsocc) TYPE s_seatsocc    " 收進來：已售座位
  EXPORTING
    VALUE(ev_revenue)  TYPE s_price       " 送出去：營收
  EXCEPTIONS
    invalid_input.                        " 錯誤丟給呼叫端

  IF iv_price < 0 OR iv_seatsocc < 0.
    RAISE invalid_input.        " 中止 FM，呼叫端 sy-subrc <> 0
  ENDIF.

  ev_revenue = iv_price * iv_seatsocc.

ENDFUNCTION.
```

---

## 2.1 介面區的方向與前綴

| 區 | 方向 | 前綴 |
|---|---|---|
| IMPORTING | 呼叫端 → FM | `iv_` |
| EXPORTING | FM → 呼叫端 | `ev_` |
| CHANGING | 雙向 | `cv_` |
| TABLES | 內表（舊式） | `t_` |

介面參數型別**一定要用 DDIC 型別**（講義 25），不能用程式裡的 `TYPES`

---

<!-- _class: compact -->

## 2.2 `CHANGING` + Table Type 取代 `TABLES`

```abap
FUNCTION z_tr15_calc_revenue_tab
  CHANGING
    VALUE(ct_flights) TYPE ztr15_tt_flight_rev.       " SE11 建的 Table Type
  FIELD-SYMBOLS <fs_flight> TYPE ztr15_flight_rev.
  LOOP AT ct_flights ASSIGNING <fs_flight>.
    <fs_flight>-revenue = <fs_flight>-price * <fs_flight>-seatsocc.
  ENDLOOP.
ENDFUNCTION.

* 呼叫端：gt_flights TYPE ztr15_tt_flight_rev
CALL FUNCTION 'Z_TR15_CALC_REVENUE_TAB'
  CHANGING
    ct_flights = gt_flights.          " 呼叫後 REVENUE 已填上
```

| | 舊式 `TABLES` | `CHANGING` + Table Type |
|---|---|---|
| Header Line | 自動帶（雙義） | 沒有 |
| 傳值 | 不行，只能傳址 | 可以 `VALUE(...)` |
| Method 能用 | 不能 | 能 |

---

## 3. SE37 單獨測試

SE37 → 輸入 FM 名 → Test（F8）
→ 填 IMPORTING 值 → 執行 → 直接看 EXPORTING 結果與例外

> **先在 SE37 測通，再寫呼叫端**
> 問題切成兩半，好查十倍

測試案例可存起來重複使用（Test Data Directory）

---

## 4. CALL FUNCTION：呼叫端

```abap
DATA gv_revenue TYPE s_price.

CALL FUNCTION 'Z_TR15_CALC_REVENUE'
  EXPORTING
    iv_price      = '1500.00'
    iv_seatsocc   = 200
  IMPORTING
    ev_revenue    = gv_revenue
  EXCEPTIONS
    invalid_input = 1
    OTHERS        = 2.
IF sy-subrc = 0.
  WRITE: / '營收 =', gv_revenue.
ELSE.
  WRITE: / '呼叫失敗，sy-subrc =', sy-subrc.
ENDIF.
```

FM 名是**字串**（大寫、加引號）；參數名不加引號

---

## 兩個最容易搞混的點

**方向反轉**——區段名稱站在「自己」的立場：

- FM 的 IMPORTING（它要**收**）→ 呼叫端寫在 **EXPORTING**（我要**送**）
- FM 的 EXPORTING（它要**給**）→ 呼叫端寫在 **IMPORTING**（我要**收**）

**EXCEPTIONS 的數字**——「發生該例外時 sy-subrc 變成幾」：

- FM `RAISE invalid_input.` → 呼叫端 sy-subrc = 1
- `OTHERS = 2` 接住沒列名的例外
- **沒列 EXCEPTIONS 又沒 OTHERS → 例外直接 dump**
- CALL FUNCTION 後檢查 sy-subrc 是鐵律

---

## 5. 什麼時候用 FM

- 邏輯給**多支程式**共用 → FM（OOP 課程後：Class Method）
- 只是本程式內拆段 → FORM 就好，不必為拆而拆
- FM 是 RFC（跨系統）與 BAPI 的技術基礎
- **開發前先搜尋**：標準 FM 幾千支
  日期換算、單位轉換、彈窗多半已有現成的

---

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| `iv_price` 寫在 IMPORTING 下報錯 | 方向搞反：FM 的 IMPORTING 寫在呼叫端 EXPORTING |
| dump RAISE_EXCEPTION | FM RAISE 了，呼叫端沒列 EXCEPTIONS |
| sy-subrc = 2 查不出原因 | 落進 OTHERS——具名例外逐一列出 |
| FM 名對了卻說不存在 | 字串沒大寫、或 FM 沒啟用 |
| SE37 正常、程式呼叫結果不同 | 參數對應錯（檢查每個等號左邊） |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex15**：

建 `ZFG_TR15` 與營收計算 FM（含防呆例外）
SE37 單測通過

再寫報表呼叫並驗證正常/例外兩條路
