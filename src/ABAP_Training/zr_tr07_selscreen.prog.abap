*&---------------------------------------------------------------------*
*& Report  ZR_TR07_SELSCREEN
*& 練習 7：選擇畫面 PARAMETERS 與 SELECT-OPTIONS（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr07_selscreen.

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
       END OF ty_student.

DATA: gt_students TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id,
      gs_student  TYPE ty_student.

* SELECT-OPTIONS 需要一個「參考欄位」來決定型別
DATA gv_score TYPE i.

*----------------------------------------------------------------------*
* 選擇畫面：
*   PARAMETERS     → 單一輸入值（可加 DEFAULT / OBLIGATORY / AS CHECKBOX）
*   SELECT-OPTIONS → 範圍條件（可輸入低~高、多段、排除，畫面自動兩個欄位）
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
  PARAMETERS p_title TYPE c LENGTH 20 DEFAULT '學生成績清單'.
  SELECT-OPTIONS s_score FOR gv_score.          " 成績範圍
  PARAMETERS p_desc AS CHECKBOX.                " 勾選＝由高到低排序
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  t_b1 = '查詢條件'.

START-OF-SELECTION.
* 測試資料
  gs_student-id = 'S0001'. gs_student-name = '王小明'. gs_student-score = 85.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0002'. gs_student-name = '李小美'. gs_student-score = 92.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0003'. gs_student-name = '陳大文'. gs_student-score = 67.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0004'. gs_student-name = '張三豐'. gs_student-score = 45.
  APPEND gs_student TO gt_students.

  IF p_desc = 'X'.                  " checkbox 勾選時值是 'X'
    SORT gt_students BY score DESCENDING.
  ENDIF.

  WRITE: / p_title.
  ULINE.

*----------------------------------------------------------------------*
* IN：判斷值是否落在 SELECT-OPTIONS 的範圍內
* （s_score 沒輸入任何條件時，IN 對所有值都成立）
*----------------------------------------------------------------------*
  LOOP AT gt_students INTO gs_student WHERE score IN s_score.
    WRITE: / gs_student-id, gs_student-name, gs_student-score.
  ENDLOOP.
  IF sy-subrc <> 0.                 " LOOP 一筆都沒跑到時 sy-subrc <> 0
    WRITE / '沒有符合條件的資料'.
  ENDIF.
