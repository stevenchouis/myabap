# 講義 8：模組化——FORM / USING / CHANGING

> 對應練習：[ex08](../ex08_modularize.md)｜答案程式：`ZR_TR08_MODULARIZE`

## 本講重點

- 為什麼要模組化：主流程一眼看懂、邏輯可重複使用
- `FORM ... ENDFORM` 定義副程式、`PERFORM` 呼叫
- `USING`（輸入）與 `CHANGING`（輸入兼輸出）的分工
- 參數要加型別（TYPE）；區域變數 vs 全域變數
- 傳統報表的標準骨架

## 1. 為什麼要模組化

所有邏輯塞在 START-OF-SELECTION 裡，兩百行之後沒人讀得懂。把「取數」「加工」「輸出」各自包成 FORM，主流程剩三行，讀程式像讀目錄：

```abap
START-OF-SELECTION.
  PERFORM get_data.
  PERFORM process_data.
  PERFORM display_data.
```

> 定位說明：FORM（subroutine）是傳統報表的模組化手段，本專案既有程式（如 ZDQM 系列）大量使用，必須熟練。跨程式共用的邏輯用 Function Module（講義 15）；新世代開發用 Class Method（OOP 課程）。三者是同一件事在不同時代的答案。

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

- FORM 定義習慣**集中放在程式尾端**（所有事件之後），與事件區隔開；SE38 內雙擊 FORM 名可直接跳轉。
- 定義了沒被呼叫的 FORM 不會執行；PERFORM 一個不存在的 FORM 是編譯錯誤。

## 3. 參數：USING 與 CHANGING

FORM 可以宣告參數，呼叫端與定義端順序一一對應：

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
| `CHANGING` | 輸入兼輸出：FORM 會改它，改動帶回呼叫端 | `cv_` / `cs_` / `ct_` |

技術上 USING 預設也是「傳參考」，在 FORM 裡改它其實改得到呼叫端——但**團隊紀律是 USING 一律當唯讀**，要改就放 CHANGING，讓介面誠實。想強制唯讀可寫 `USING VALUE(iv_score) TYPE i`（傳值複本）。

參數不加 TYPE 雖然能編譯（成為任意型別），但失去檢查、埋下錯誤——**一律加 TYPE**。內表參數這樣寫：

```abap
FORM show_list USING it_students TYPE tt_student.
  DATA ls_student TYPE ty_student.        " 區域 work area
  LOOP AT it_students INTO ls_student.
    WRITE: / ls_student-id, ls_student-name.
  ENDLOOP.
ENDFORM.
```

（`tt_student` 是講義 4 用 TYPES 定義的表格型別——這就是表格型別的另一個好處：能拿來宣告參數。）

## 4. 區域變數 vs 全域變數

- FORM 裡 `DATA` 宣告的是**區域變數**（`lv_`/`ls_`/`lt_`）：只在該 FORM 內存在，每次呼叫重新初始化。
- 程式開頭宣告的是**全域變數**（`gv_`/`gs_`/`gt_`）：所有事件與 FORM 都摸得到。

原則：**能區域就區域**。全域變數誰都能改，程式一大就追不到是誰改的；FORM 需要的資料盡量從參數進來，而不是伸手拿全域。傳統報表難免有核心全域內表（如 `gt_data`），但臨時變數絕不要全域。

## 5. 舊式 TABLES 參數（看得懂即可）

舊程式常見 `PERFORM f USING ... TABLES gt_x.` 或 `FORM f TABLES t_x STRUCTURE ...`——這是內表的舊式傳遞方式，**新程式不要用**（用 USING/CHANGING + 表格型別），但維護 ZDQM 等既有程式時要認得。

## 6. 傳統報表標準骨架

從本講開始，練習程式都照這個結構寫（也是期末實作與正式程式的長相）：

```abap
REPORT zr_xxx.

* 1) 宣告區：TYPES / DATA / CONSTANTS
* 2) 選擇畫面：PARAMETERS / SELECT-OPTIONS
* 3) 事件區：INITIALIZATION / START-OF-SELECTION ...
*    事件裡只放 PERFORM，不放邏輯
* 4) FORM 區：所有副程式，集中在檔尾
```

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| PERFORM 報「FORM 不存在」 | FORM 名拼錯，或定義根本沒寫 |
| 參數個數/順序錯 | 呼叫端與定義端依**位置**對應，一個都不能錯位 |
| USING 的參數在 FORM 裡被改，呼叫端也變了 | USING 預設傳參考——紀律：要改就宣告在 CHANGING |
| FORM 裡讀到莫名其妙的值 | 誤用了同名全域變數；區域變數記得 `l` 前綴 |
| FORM 定義寫在事件中間，後面的事件不執行 | FORM 區塊會「吃掉」後面的程式——FORM 一律放檔尾 |

## 8. 課堂練習

完成 [ex08](../ex08_modularize.md)：把前幾講的學生報表重構成 get_data / process_data / display_data 三個 FORM，練習 USING 與 CHANGING。
