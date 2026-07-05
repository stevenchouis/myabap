# 講義 15：Function Module——SE37 與 CALL FUNCTION

> 對應練習：[ex15](../ex15_function_module.md)｜答案物件：`ZFG_TR15` / `Z_TR15_CALC_REVENUE` / `ZR_TR15_CALL_FM`

## 本講重點

- Function Module（FM）的定位：**跨程式共用**的邏輯單位
- Function Group：FM 的容器
- 介面四區：IMPORTING / EXPORTING / CHANGING / TABLES ＋ EXCEPTIONS
- SE37 建立與單獨測試
- `CALL FUNCTION` 呼叫：方向對應與例外處理
- FM vs FORM 的選擇

## 1. FM 是什麼、跟 FORM 差在哪

FORM 只能在同一支程式（含 INCLUDE）裡呼叫；FM 是**全系統共用**的邏輯單位——任何程式都能 `CALL FUNCTION` 呼叫，還能在 SE37 **單獨測試**（不用寫測試程式）。你每天呼叫的 `REUSE_ALV_GRID_DISPLAY` 就是 SAP 提供的標準 FM。

| | FORM | Function Module |
|---|---|---|
| 共用範圍 | 本程式內 | 全系統 |
| 單獨測試 | 不行 | SE37 直接測 |
| 介面 | USING / CHANGING | IMPORTING / EXPORTING / CHANGING / TABLES + EXCEPTIONS |
| 容器 | 報表程式 | Function Group |
| 定位 | 程式內部拆段 | 跨程式共用、RFC、BAPI 的基礎 |

## 2. Function Group：FM 的容器

FM 不能單獨存在，必須掛在 **Function Group**（SE37 → Goto → Function Groups → Create，或 SE80）底下。命名 `ZFG_xxx`，同一個 group 的 FM 共用全域資料與 subroutine——把同主題的 FM 收在同一個 group（如 `ZFG_TR15` 放訓練用計算類 FM）。

## 3. 定義介面（SE37 分頁）

範例：計算航班營收的 FM `Z_TR15_CALC_REVENUE`：

```abap
FUNCTION z_tr15_calc_revenue
  IMPORTING
    VALUE(iv_price)    TYPE s_price       " 收進來：票價
    VALUE(iv_seatsocc) TYPE s_seatsocc    " 收進來：已售座位
  EXPORTING
    VALUE(ev_revenue)  TYPE s_price       " 送出去：營收
  EXCEPTIONS
    invalid_input.                        " 錯誤情況丟給呼叫端

  IF iv_price < 0 OR iv_seatsocc < 0.
    RAISE invalid_input.                  " 丟例外：中止 FM，呼叫端 sy-subrc <> 0
  ENDIF.

  ev_revenue = iv_price * iv_seatsocc.

ENDFUNCTION.
```

介面四區＋例外：

| 區 | 方向 | 慣例前綴 |
|---|---|---|
| IMPORTING | 呼叫端 → FM（輸入） | `iv_` / `is_` / `it_` |
| EXPORTING | FM → 呼叫端（輸出） | `ev_` / `es_` / `et_` |
| CHANGING | 雙向 | `cv_` / `cs_` / `ct_` |
| TABLES | 內表（舊式，維護會遇到；新介面用 IMPORTING/EXPORTING 傳表格型別） | `t_` |
| EXCEPTIONS | 具名的錯誤情況，用 `RAISE 名稱.` 觸發 | 小寫底線命名 |

參數型別建議參考 DDIC（如 `s_price`），跨程式介面才有一致的語意。

## 4. SE37 單獨測試

SE37 → 輸入 FM 名 → Test（F8）→ 填 IMPORTING 值 → 執行，直接看 EXPORTING 結果與例外。**先在 SE37 測通，再寫呼叫端**——問題切成兩半，好查十倍。測試案例還能存起來（Test Data Directory）重複使用。

## 5. CALL FUNCTION：呼叫端

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

兩個最容易搞混的點：

**方向反轉**——區段名稱是站在「自己」的立場寫的：

- FM 定義的 IMPORTING（它要**收**的）→ 呼叫端寫在 **EXPORTING**（我要**送**的）
- FM 定義的 EXPORTING（它要**給**的）→ 呼叫端寫在 **IMPORTING**（我要**收**的）

**EXCEPTIONS 的數字**——「發生該例外時，我的 sy-subrc 要變成幾」：FM 裡 `RAISE invalid_input.` → 呼叫端 sy-subrc = 1；`OTHERS = 2` 接住沒列名的例外。**沒列 EXCEPTIONS 又沒 OTHERS 時，例外直接讓程式 dump**——CALL FUNCTION 之後檢查 sy-subrc 跟 READ TABLE 之後一樣是鐵律。

- FM 名稱是**字串**（大寫、加引號）；參數名不加引號。
- 常數/字面值可以直接餵 EXPORTING（如 `'1500.00'`），IMPORTING 必須接變數。

## 6. 什麼時候用 FM

- 邏輯要給**多支程式**共用 → FM（或 OOP 課程後：Class Method）。
- 只是本程式內拆段 → FORM 就好，不必為拆而拆 FM。
- FM 還是 RFC（跨系統呼叫）與 BAPI 的技術基礎——維護介面程式一定會遇到。
- 開發前先搜尋：標準 FM 幾千支，常見需求（日期換算、單位轉換、彈窗）多半已有現成的。

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 呼叫端寫 `iv_price` 在 IMPORTING 下報錯 | 方向搞反：FM 的 IMPORTING 要寫在呼叫端 EXPORTING |
| 執行到一半 dump（RAISE_EXCEPTION） | FM RAISE 了例外，呼叫端沒列 EXCEPTIONS 承接 |
| sy-subrc = 2 查不出原因 | 落進 OTHERS——把具名例外逐一列出對應數字好定位 |
| FM 名對了卻說不存在 | 呼叫字串沒大寫、或 FM 沒啟用 |
| SE37 測試正常、程式呼叫結果不同 | 呼叫端參數對應錯（依名稱對應，檢查每個等號左邊） |

## 8. 課堂練習

完成 [ex15](../ex15_function_module.md)：建 `ZFG_TR15` 與營收計算 FM（含防呆例外）、SE37 單測通過，再寫報表呼叫並驗證正常/例外兩條路。
