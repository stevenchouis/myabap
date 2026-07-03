*&---------------------------------------------------------------------*
*& Report  ZR_TR04_ITAB_BASICS
*& 練習 4：Internal Table 基礎（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr04_itab_basics.

* 延續練習 3 的結構型別
TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,     " 學號
         name  TYPE string,         " 姓名
         score TYPE i,              " 成績
       END OF ty_student.

* Internal Table 型別：同一種結構的「多筆」集合
TYPES tt_student TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id.

DATA: gt_students TYPE tt_student,     " internal table：存多筆
      gs_student  TYPE ty_student.     " work area：一次一筆，配合 itab 使用

START-OF-SELECTION.
*----------------------------------------------------------------------*
* APPEND：把 work area 的內容「附加」到 internal table 的尾端
*----------------------------------------------------------------------*
  gs_student-id = 'S0001'. gs_student-name = '王小明'. gs_student-score = 85.
  APPEND gs_student TO gt_students.

  gs_student-id = 'S0002'. gs_student-name = '李小美'. gs_student-score = 92.
  APPEND gs_student TO gt_students.

  gs_student-id = 'S0003'. gs_student-name = '陳大文'. gs_student-score = 67.
  APPEND gs_student TO gt_students.

*----------------------------------------------------------------------*
* LOOP AT ... INTO：逐筆讀進 work area 處理
* sy-tabix：迴圈中「目前是第幾筆」
*----------------------------------------------------------------------*
  WRITE / '=== 全部學生 ==='.
  LOOP AT gt_students INTO gs_student.
    WRITE: / sy-tabix, gs_student-id, gs_student-name, gs_student-score.
  ENDLOOP.

*----------------------------------------------------------------------*
* READ TABLE ... WITH KEY：依「條件」讀單筆
* 讀單筆之後一定要檢查 sy-subrc（0 = 有找到）！
*----------------------------------------------------------------------*
  READ TABLE gt_students INTO gs_student WITH KEY id = 'S0002'.
  IF sy-subrc = 0.
    WRITE: / 'WITH KEY 找到 S0002：', gs_student-name.
  ENDIF.

*----------------------------------------------------------------------*
* READ TABLE ... INDEX：依「第幾筆」讀單筆
*----------------------------------------------------------------------*
  READ TABLE gt_students INTO gs_student INDEX 3.
  IF sy-subrc = 0.
    WRITE: / 'INDEX 3 讀到的是：', gs_student-name.
  ENDIF.

*----------------------------------------------------------------------*
* 找不到的情況：sy-subrc 不等於 0，work area 內容維持原樣
* 忘記檢查 sy-subrc 是實務上非常常見的 bug！
*----------------------------------------------------------------------*
  READ TABLE gt_students INTO gs_student WITH KEY id = 'S9999'.
  IF sy-subrc <> 0.
    WRITE: / '查無 S9999，sy-subrc =', sy-subrc.
  ENDIF.
