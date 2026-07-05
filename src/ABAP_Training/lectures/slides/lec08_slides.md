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

# 講義 8
# 模組化——FORM / USING / CHANGING

ABAP 基礎教育訓練

對應練習 ex08｜答案程式 `ZR_TR08_MODULARIZE`

---

## 本講重點

- 為什麼要模組化：主流程一眼看懂、邏輯可重複使用
- `FORM ... ENDFORM` 定義副程式、`PERFORM` 呼叫
- `USING`（輸入）與 `CHANGING`（輸入兼輸出）的分工
- 參數要加型別（TYPE）；區域變數 vs 全域變數
- 傳統報表的標準骨架

---

## 1. 為什麼要模組化

所有邏輯塞在 START-OF-SELECTION → 兩百行後沒人讀得懂

主流程剩三行，**讀程式像讀目錄**：

```abap
START-OF-SELECTION.
  PERFORM get_data.
  PERFORM process_data.
  PERFORM display_data.
```

> 定位：FORM 是**傳統報表**的模組化手段，ZDQM 等既有程式大量使用，必須熟練。跨程式共用 → Function Module（講義 15）；新世代 → Class Method（OOP 課程）。三者是同一件事在不同時代的答案。

---

## 2. FORM 與 PERFORM

```abap
* 呼叫（事件區）
START-OF-SELECTION.
  PERFORM say_hello.

* 定義（放在程式最後面）
FORM say_hello.
  WRITE / 'Hello from FORM!'.
ENDFORM.
```

- FORM 定義**集中放檔尾**（所有事件之後）
- SE38 雙擊 FORM 名直接跳轉
- 沒被呼叫的 FORM 不執行；PERFORM 不存在的 FORM = 編譯錯誤

---

## 3. 參數：USING 與 CHANGING

```abap
* 呼叫端
PERFORM calc_grade USING    gs_student-score
                   CHANGING gv_grade.

* 定義端：參數務必加 TYPE
FORM calc_grade USING    iv_score TYPE i
                CHANGING cv_grade TYPE c.
  IF iv_score >= 80.
    cv_grade = 'A'.
  ELSEIF iv_score >= 60.
    cv_grade = 'B'.
  ELSE.
    cv_grade = 'C'.
  ENDIF.
ENDFORM.
```

| 區段 | 語意 | 慣例前綴 |
|---|---|---|
| `USING` | 輸入：FORM 只讀它 | `iv_` / `is_` / `it_` |
| `CHANGING` | 會改它，改動帶回呼叫端 | `cv_` / `cs_` / `ct_` |

---

## USING 的紀律與內表參數

- 技術上 USING 預設**傳參考**，改它其實改得到呼叫端
- **團隊紀律：USING 一律當唯讀**，要改就放 CHANGING
- 強制唯讀：`USING VALUE(iv_score) TYPE i`（傳值複本）
- 參數**一律加 TYPE**：不加雖能編譯，但失去檢查

```abap
FORM show_list USING it_students TYPE tt_student.
  DATA ls_student TYPE ty_student.        " 區域 work area
  LOOP AT it_students INTO ls_student.
    WRITE: / ls_student-id, ls_student-name.
  ENDLOOP.
ENDFORM.
```

表格型別（`tt_student`）的另一個好處：能拿來宣告參數

---

## 4. 區域變數 vs 全域變數

- FORM 裡 `DATA` = **區域變數**（`lv_`/`ls_`/`lt_`）
  只在該 FORM 內存在，每次呼叫重新初始化
- 程式開頭 = **全域變數**（`gv_`/`gs_`/`gt_`）
  所有事件與 FORM 都摸得到

> 原則：**能區域就區域**
> 全域誰都能改，程式一大就追不到是誰改的
> FORM 需要的資料盡量從參數進來，不要伸手拿全域

舊式 `TABLES` 參數（`FORM f TABLES t_x ...`）：
維護舊程式要認得，**新程式不要用**

---

## 5. 傳統報表標準骨架

從本講開始，練習程式都照這個結構寫：

```abap
REPORT zr_xxx.

* 1) 宣告區：TYPES / DATA / CONSTANTS

* 2) 選擇畫面：PARAMETERS / SELECT-OPTIONS

* 3) 事件區：INITIALIZATION / START-OF-SELECTION ...
*    事件裡只放 PERFORM，不放邏輯

* 4) FORM 區：所有副程式，集中在檔尾
```

這也是期末實作與正式程式的長相

---

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| PERFORM 報「FORM 不存在」 | FORM 名拼錯或沒定義 |
| 參數個數/順序錯 | 依**位置**對應，一個都不能錯位 |
| USING 參數被改，呼叫端也變 | USING 預設傳參考——紀律：要改放 CHANGING |
| FORM 裡讀到莫名的值 | 誤用同名全域變數；區域記得 `l` 前綴 |
| FORM 後面的事件不執行 | FORM 區塊吃掉後面程式——FORM 一律放檔尾 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex08**：

把學生報表重構成
get_data / process_data / display_data 三個 FORM

練習 USING 與 CHANGING
