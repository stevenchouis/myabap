*&---------------------------------------------------------------------*
*& Report  ZR_TR05_ITAB_ADVANCED
*& 練習 5：Internal Table 進階（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr05_itab_advanced.

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,     " 學號
         name  TYPE string,         " 姓名
         score TYPE i,              " 成績
         grade TYPE c LENGTH 1,     " 等第（稍後才填）
       END OF ty_student.

DATA: gt_students TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id,
      gs_student  TYPE ty_student,
      gv_lines    TYPE i.           " 存筆數用

START-OF-SELECTION.
* 建立測試資料（4 筆，故意不照成績順序）
  gs_student-id = 'S0001'. gs_student-name = '王小明'. gs_student-score = 85.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0002'. gs_student-name = '李小美'. gs_student-score = 92.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0003'. gs_student-name = '陳大文'. gs_student-score = 67.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0004'. gs_student-name = '張三豐'. gs_student-score = 45.
  APPEND gs_student TO gt_students.

*----------------------------------------------------------------------*
* lines( )：取得目前筆數
*----------------------------------------------------------------------*
  gv_lines = lines( gt_students ).
  WRITE: / '原始筆數：', gv_lines.

*----------------------------------------------------------------------*
* SORT ... BY：排序，加 DESCENDING 反向
*----------------------------------------------------------------------*
  SORT gt_students BY score DESCENDING.
  WRITE / '=== 依成績由高到低 ==='.
  LOOP AT gt_students INTO gs_student.
    WRITE: / sy-tabix, gs_student-id, gs_student-name, gs_student-score.
  ENDLOOP.

*----------------------------------------------------------------------*
* MODIFY：在 LOOP 中修改 work area 後「寫回目前這一筆」
* （沒有 MODIFY 的話，改動只存在 work area，itab 不會變）
*----------------------------------------------------------------------*
  LOOP AT gt_students INTO gs_student.
    IF gs_student-score >= 80.
      gs_student-grade = 'A'.
    ELSEIF gs_student-score >= 60.
      gs_student-grade = 'B'.
    ELSE.
      gs_student-grade = 'C'.
    ENDIF.
    MODIFY gt_students FROM gs_student.
  ENDLOOP.

  WRITE / '=== 打上等第 ==='.
  LOOP AT gt_students INTO gs_student.
    WRITE: / sy-tabix, gs_student-id, gs_student-name,
             gs_student-score, gs_student-grade.
  ENDLOOP.

*----------------------------------------------------------------------*
* DELETE ... WHERE：整批刪除符合條件的資料列
*----------------------------------------------------------------------*
  DELETE gt_students WHERE score < 60.

  gv_lines = lines( gt_students ).
  WRITE: / '=== 刪除不及格後剩', gv_lines, '筆 ==='.
  LOOP AT gt_students INTO gs_student.
    WRITE: / sy-tabix, gs_student-id, gs_student-name,
             gs_student-score, gs_student-grade.
  ENDLOOP.
