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

ABAP 基礎教育訓練

對應練習 ex15｜答案：`ZFG_TR15` / `Z_TR15_CALC_REVENUE` / `ZR_TR15_CALL_FM`

---

## 本講重點

- Function Module（FM）的定位：**跨程式共用**的邏輯單位
- Function Group：FM 的容器
- 介面四區：IMPORTING / EXPORTING / CHANGING / TABLES ＋ EXCEPTIONS
- SE37 建立與單獨測試
- `CALL FUNCTION` 呼叫：方向對應與例外處理
- FM vs FORM 的選擇

---

## 1. FM 是什麼、跟 FORM 差在哪

FORM 只能在同一支程式裡呼叫；FM 是**全系統共用**
你每天呼叫的 `REUSE_ALV_GRID_DISPLAY` 就是標準 FM

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

| 區 | 方向 | 前綴 |
|---|---|---|
| IMPORTING | 呼叫端 → FM | `iv_` |
| EXPORTING | FM → 呼叫端 | `ev_` |
| CHANGING | 雙向 | `cv_` |
| TABLES | 內表（舊式） | `t_` |

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
