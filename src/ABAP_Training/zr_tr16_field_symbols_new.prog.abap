*&---------------------------------------------------------------------*
*& Report  ZR_TR16_FIELD_SYMBOLS_NEW
*& 練習 16：Field-Symbol（答案程式，新式寫法版）
*& 對照 ZR_TR16_FIELD_SYMBOLS：輸出相同；FIELD-SYMBOL( ) 行內宣告、
*& ASSIGN itab[ ] 取代 READ TABLE ASSIGNING、COND 打等第、VALUE 建資料
*&---------------------------------------------------------------------*
REPORT zr_tr16_field_symbols_new.

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
         grade TYPE c LENGTH 1,
       END OF ty_student.
TYPES tt_student TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id.

DATA: gt_students TYPE tt_student,
      gs_student  TYPE ty_student,
      gv_total    TYPE i VALUE 100.

START-OF-SELECTION.
  PERFORM fill_data.

* 1) ASSIGN ... TO FIELD-SYMBOL( )：在 ASSIGN 這裡才宣告，型別跟 gv_total 一樣
  ASSIGN gv_total TO FIELD-SYMBOL(<fs_num>).
  IF <fs_num> IS ASSIGNED.
    <fs_num> = <fs_num> + 50.
  ENDIF.
  WRITE: / '=== 1) 別名不是複本 ==='.
  WRITE: / '改 <fs_num> 之後 gv_total =', gv_total.

* 2) LOOP AT ... ASSIGNING FIELD-SYMBOL( )
  LOOP AT gt_students ASSIGNING FIELD-SYMBOL(<ls_student>).
    <ls_student>-grade = COND #( WHEN <ls_student>-score >= 80 THEN 'A'
                                 WHEN <ls_student>-score >= 60 THEN 'B'
                                 ELSE 'C' ).
  ENDLOOP.
  WRITE: / '=== 2) LOOP ASSIGNING 打等第（沒有 MODIFY） ==='.
  PERFORM write_all.

* 3) ASSIGN itab[ 條件 ] TO FIELD-SYMBOL( )：取代 READ TABLE ... ASSIGNING
*    ASSIGN 找不到不會發生例外，而是設定 sy-subrc = 4
  ASSIGN gt_students[ id = 'S0004' ] TO FIELD-SYMBOL(<ls_hit>).
  IF sy-subrc = 0.
    <ls_hit>-score = <ls_hit>-score + 30.
    <ls_hit>-grade = 'B'.
  ENDIF.
  WRITE: / '=== 3) READ TABLE ASSIGNING 補考後 ==='.
  PERFORM write_all.

* 4) ASSIGN COMPONENT ... TO FIELD-SYMBOL( )：行內宣告的型別是 any
  WRITE: / '=== 4) ASSIGN COMPONENT 逐欄輸出第一筆 ==='.
  gs_student = gt_students[ 1 ].
  DO.
    ASSIGN COMPONENT sy-index OF STRUCTURE gs_student TO FIELD-SYMBOL(<fs_comp>).
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.
    WRITE: / '  欄位', sy-index, ':', <fs_comp>.
  ENDDO.

FORM fill_data.
  gt_students = VALUE #( ( id = 'S0001' name = '王小明' score = 85 )
                         ( id = 'S0002' name = '李小美' score = 92 )
                         ( id = 'S0003' name = '陳大文' score = 67 )
                         ( id = 'S0004' name = '張三豐' score = 45 ) ).
ENDFORM.

FORM write_all.
  LOOP AT gt_students INTO gs_student.
    WRITE: / gs_student-id, gs_student-name,
             gs_student-score, gs_student-grade.
  ENDLOOP.
ENDFORM.
