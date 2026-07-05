*&---------------------------------------------------------------------*
*& Report  ZR_TR22_TEXTS
*& 練習 22：Message Class 與多語言文字元素（答案程式）
*&---------------------------------------------------------------------*
*& 本程式的文字元素（SE38 → Goto → Text Elements 維護後啟用）：
*&   Text Symbols：
*&     001  學生成績查詢
*&     002  查詢條件：
*&     003  符合筆數：
*&   Selection Texts：
*&     P_NAME   學生姓名
*&     S_SCORE  成績範圍
*& 訊息類別 ZTR22（SE91）：
*&     001  請至少輸入一個查詢條件
*&     002  查詢完成：共 &1 筆（由 &2 於 &3 執行）
*&     003  成績上限不可超過 &1
*&---------------------------------------------------------------------*
REPORT zr_tr22_texts.

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
       END OF ty_student.

DATA: gt_students TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id,
      gs_student  TYPE ty_student,
      gv_count    TYPE i.

DATA gv_score TYPE i.
SELECT-OPTIONS s_score FOR gv_score.      " Selection Text：成績範圍
PARAMETERS p_name TYPE c LENGTH 10.       " Selection Text：學生姓名

DATA gs_range LIKE LINE OF s_score.       " 要宣告在 s_score 之後才參考得到

*----------------------------------------------------------------------*
* 驗證：訊息「內容」在 SE91，「型別」在呼叫端（e = 擋在選擇畫面）
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF s_score[] IS INITIAL AND p_name IS INITIAL.
    MESSAGE e001(ztr22).
  ENDIF.
  LOOP AT s_score INTO gs_range.
    IF gs_range-high > 999.
      MESSAGE e003(ztr22) WITH 999.       " &1 = 999
    ENDIF.
  ENDLOOP.

START-OF-SELECTION.
  gs_student-id = 'S0001'. gs_student-name = '王小明'. gs_student-score = 85.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0002'. gs_student-name = '李小美'. gs_student-score = 92.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0003'. gs_student-name = '陳大文'. gs_student-score = 67.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0004'. gs_student-name = '張三豐'. gs_student-score = 45.
  APPEND gs_student TO gt_students.

*----------------------------------------------------------------------*
* 標題用「字面文字(符號)」寫法：翻譯缺漏時 fallback 到字面文字；
* 其餘用 text-nnn：該語言沒維護就開天窗（兩種行為都要認識）
*----------------------------------------------------------------------*
  WRITE / '學生成績查詢'(001).
  WRITE: / text-002, s_score-low, '～', s_score-high.
  ULINE.

  gv_count = 0.
  LOOP AT gt_students INTO gs_student WHERE score IN s_score.
    IF p_name IS NOT INITIAL AND gs_student-name <> p_name.
      CONTINUE.                           " 有給姓名就精確比對（空白=不過濾）
    ENDIF.
    gv_count = gv_count + 1.
    WRITE: / gs_student-id, gs_student-name, gs_student-score.
  ENDLOOP.
  WRITE: / text-003, gv_count.

*----------------------------------------------------------------------*
* S 訊息：顯示在下一畫面的狀態列，不中斷；WITH 依序填 &1 &2 &3
* （加 DISPLAY LIKE 'E' 可用錯誤樣式顯示但仍不中斷——實驗用）
*----------------------------------------------------------------------*
  MESSAGE s002(ztr22) WITH gv_count sy-uname sy-datum.
