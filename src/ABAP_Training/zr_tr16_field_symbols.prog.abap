*&---------------------------------------------------------------------*
*& Report  ZR_TR16_FIELD_SYMBOLS
*& 練習 16：Field-Symbol（答案程式）
*&---------------------------------------------------------------------*
* Field-Symbol 是「別名」：ASSIGN 之後，<fs> 就是那個變數本人，
* 不是複本——改 <fs> 等於改本尊。
*&---------------------------------------------------------------------*
REPORT zr_tr16_field_symbols.

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
         grade TYPE c LENGTH 1,
       END OF ty_student.

DATA: gt_students TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id,
      gs_student  TYPE ty_student,
      gv_total    TYPE i VALUE 100.

* 傳統宣告寫法（LOOP/READ 處會看到行內宣告的新寫法）
FIELD-SYMBOLS <fs_num> TYPE i.

START-OF-SELECTION.
  PERFORM fill_data.

* 1) 別名不是複本：改 <fs_num> = 改 gv_total
  ASSIGN gv_total TO <fs_num>.
  IF <fs_num> IS ASSIGNED.
    <fs_num> = <fs_num> + 50.
  ENDIF.
  WRITE: / '=== 1) 別名不是複本 ==='.
  WRITE: / '改 <fs_num> 之後 gv_total =', gv_total.

* 2) LOOP ASSIGNING：直接改表格那一列——不用 work area、不用 MODIFY
*    （對照 ex05 第 4 步：INTO 拿到的是複本，忘了 MODIFY 改動就丟失）
  LOOP AT gt_students ASSIGNING FIELD-SYMBOL(<ls_student>).
    IF <ls_student>-score >= 80.
      <ls_student>-grade = 'A'.
    ELSEIF <ls_student>-score >= 60.
      <ls_student>-grade = 'B'.
    ELSE.
      <ls_student>-grade = 'C'.
    ENDIF.
  ENDLOOP.
  WRITE: / '=== 2) LOOP ASSIGNING 打等第（沒有 MODIFY） ==='.
  PERFORM write_all.

* 3) READ TABLE ASSIGNING：單筆就地修改（張三豐補考 +30）
  READ TABLE gt_students ASSIGNING FIELD-SYMBOL(<ls_hit>)
    WITH KEY id = 'S0004'.
  IF sy-subrc = 0.
    <ls_hit>-score = <ls_hit>-score + 30.
    <ls_hit>-grade = 'B'.               " 75 分：等第也要跟著重打
  ENDIF.
  WRITE: / '=== 3) READ TABLE ASSIGNING 補考後 ==='.
  PERFORM write_all.

* 4) ASSIGN COMPONENT：動態逐欄存取（維護舊程式常見，先看得懂）
*    sy-index 從 1 開始一欄一欄要，要不到（sy-subrc <> 0）就結束
  WRITE: / '=== 4) ASSIGN COMPONENT 逐欄輸出第一筆 ==='.
  READ TABLE gt_students INTO gs_student INDEX 1.
  DO.
    ASSIGN COMPONENT sy-index OF STRUCTURE gs_student TO FIELD-SYMBOL(<fs_comp>).
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.
    WRITE: / '  欄位', sy-index, ':', <fs_comp>.
  ENDDO.

* 實驗（打開註解看執行期錯誤 GETWA_NOT_ASSIGNED）：
*  UNASSIGN <fs_num>.
*  <fs_num> = 999.        " 沒指向任何變數還去改——當掉

*&---------------------------------------------------------------------*
*&      Form  fill_data
*&---------------------------------------------------------------------*
FORM fill_data.
  CLEAR gs_student.
  gs_student-id = 'S0001'. gs_student-name = '王小明'. gs_student-score = 85.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0002'. gs_student-name = '李小美'. gs_student-score = 92.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0003'. gs_student-name = '陳大文'. gs_student-score = 67.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0004'. gs_student-name = '張三豐'. gs_student-score = 45.
  APPEND gs_student TO gt_students.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  write_all
*&---------------------------------------------------------------------*
FORM write_all.
  LOOP AT gt_students INTO gs_student.
    WRITE: / gs_student-id, gs_student-name,
             gs_student-score, gs_student-grade.
  ENDLOOP.
ENDFORM.
