*&---------------------------------------------------------------------*
*& Report  ZR_TR08_CALLER
*& 練習 8 選修：跨程式呼叫 FORM——PERFORM ... IN PROGRAM
*& 前提：Subroutine Pool ZR_TR08_POOL 已建立並啟用（見該程式檔頭的建立方式）
*&---------------------------------------------------------------------*
REPORT zr_tr08_caller.

DATA: gv_score TYPE i,
      gv_grade TYPE c LENGTH 1,
      gv_form  TYPE c LENGTH 30 VALUE 'CALC_GRADE',      " 動態呼叫：名稱必須大寫
      gv_prog  TYPE c LENGTH 30 VALUE 'ZR_TR08_POOL'.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 1) 靜態指定：FORM 名稱與程式名稱都直接寫出來
*    語法檢查不會確認 ZR_TR08_POOL 或 CALC_GRADE 存在，
*    也不檢查參數對不對——寫錯要到執行期才知道
*----------------------------------------------------------------------*
  WRITE / '=== 1) PERFORM ... IN PROGRAM（靜態指定）==='.
  gv_score = 85.
  PERFORM calc_grade IN PROGRAM zr_tr08_pool
    USING    gv_score
    CHANGING gv_grade.
  WRITE: / '85 分 →', gv_grade.                        " 輸出：85 分 → A

  gv_score = 45.
  PERFORM calc_grade IN PROGRAM zr_tr08_pool
    USING    gv_score
    CHANGING gv_grade.
  WRITE: / '45 分 →', gv_grade.                        " 輸出：45 分 → C

*----------------------------------------------------------------------*
* 2) IF FOUND：找不到 FORM 或程式時，安靜地跳過，不會出錯
*    NO_SUCH_FORM 不存在——因為有 IF FOUND，這句什麼都不做，
*    gv_grade 維持上一次的值 C
*----------------------------------------------------------------------*
  WRITE / '=== 2) IF FOUND：FORM 不存在時跳過 ==='.
  gv_score = 99.
  PERFORM no_such_form IN PROGRAM zr_tr08_pool IF FOUND
    USING    gv_score
    CHANGING gv_grade.
  WRITE: / '呼叫不存在的 FORM 後 gv_grade 仍是', gv_grade.   " 輸出：... 仍是 C

*----------------------------------------------------------------------*
* 3) 動態指定：FORM 名稱與程式名稱放在變數裡（括號包起來）
*    舊程式、User-Exit 常見；名稱變數的內容必須是大寫
*----------------------------------------------------------------------*
  WRITE / '=== 3) 動態指定 PERFORM (變數) IN PROGRAM (變數) ==='.
  gv_score = 72.
  PERFORM (gv_form) IN PROGRAM (gv_prog) IF FOUND
    USING    gv_score
    CHANGING gv_grade.
  WRITE: / '72 分 →', gv_grade.                        " 輸出：72 分 → B

* 實驗（打開註解看執行期錯誤）：拿掉 IF FOUND、FORM 名稱故意寫錯，
*   PERFORM no_such_form IN PROGRAM zr_tr08_pool USING gv_score CHANGING gv_grade.
* → 執行期 dump：找不到 FORM（可攔截的例外 CX_SY_DYN_CALL_ILLEGAL_FORM，沒攔截就 dump）
*   程式名稱寫錯則是 CX_SY_PROGRAM_NOT_FOUND
