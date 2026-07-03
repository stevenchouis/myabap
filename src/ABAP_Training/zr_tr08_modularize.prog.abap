*&---------------------------------------------------------------------*
*& Report  ZR_TR08_MODULARIZE
*& 練習 8：模組化——FORM 副程式（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr08_modularize.

TYPES ty_avg TYPE p LENGTH 5 DECIMALS 1.

TYPES: BEGIN OF ty_student,
         id     TYPE c LENGTH 5,
         name   TYPE string,
         score1 TYPE i,           " 期中
         score2 TYPE i,           " 期末
         avg    TYPE ty_avg,      " 平均
       END OF ty_student.

DATA: gt_students TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id,
      gs_student  TYPE ty_student.

START-OF-SELECTION.
  PERFORM fill_data.

* 主流程只描述「做什麼」，細節交給副程式——這就是模組化的目的
  LOOP AT gt_students INTO gs_student.
    PERFORM calc_avg USING    gs_student-score1
                              gs_student-score2
                     CHANGING gs_student-avg.
    MODIFY gt_students FROM gs_student.
  ENDLOOP.

  PERFORM write_all.

*&---------------------------------------------------------------------*
*&      Form  fill_data
*&      建立測試資料（無參數的 FORM）
*&---------------------------------------------------------------------*
FORM fill_data.
  CLEAR gs_student.
  gs_student-id = 'S0001'. gs_student-name = '王小明'.
  gs_student-score1 = 78. gs_student-score2 = 91.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0002'. gs_student-name = '李小美'.
  gs_student-score1 = 88. gs_student-score2 = 95.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0003'. gs_student-name = '陳大文'.
  gs_student-score1 = 60. gs_student-score2 = 72.
  APPEND gs_student TO gt_students.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  calc_avg
*&      USING    ：輸入參數
*&      CHANGING ：輸出/雙向參數（會改到呼叫端的變數）
*&---------------------------------------------------------------------*
FORM calc_avg USING    iv_s1  TYPE i
                       iv_s2  TYPE i
              CHANGING cv_avg TYPE ty_avg.
  cv_avg = ( iv_s1 + iv_s2 ) / 2.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  write_all
*&---------------------------------------------------------------------*
FORM write_all.
  WRITE / '=== 成績與平均 ==='.
  LOOP AT gt_students INTO gs_student.
    WRITE: / gs_student-id, gs_student-name,
             gs_student-score1, gs_student-score2, gs_student-avg.
  ENDLOOP.
ENDFORM.
