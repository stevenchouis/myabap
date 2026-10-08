REPORT zr_tr02_inline_chk.
* 驗證講義 2 §1：哪些位置可以用 DATA( ) 行內宣告、推導出什麼型別（2026-10-08）

TYPES: BEGIN OF ty_row,
         id   TYPE c LENGTH 3,
         name TYPE string,
       END OF ty_row.
TYPES tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

DATA gt TYPE tt_row.

START-OF-SELECTION.
  gt = VALUE #( ( id = 'A01' name = `Alice` ) ( id = 'B02' name = `Bob` ) ).

* 1) READ TABLE ... INTO DATA( )
  READ TABLE gt INTO DATA(gs_read) WITH KEY id = 'B02'.
  PERFORM show USING '1) READ TABLE INTO' gs_read.

* 2) CATCH ... INTO DATA( )
  TRY.
      DATA(gv_zero) = 0.
      DATA(gv_div) = 1 / gv_zero.
    CATCH cx_sy_zerodivide INTO DATA(gx_err).
      PERFORM show USING '2) CATCH INTO' gx_err.
  ENDTRY.

* 3) SPLIT ... INTO DATA( ) DATA( )
  SPLIT 'S0001,王小明,85' AT ',' INTO DATA(gv_p1) DATA(gv_p2) DATA(gv_p3).
  PERFORM show USING '3) SPLIT INTO' gv_p2.

* 4) CONCATENATE ... INTO DATA( )
  CONCATENATE 'AB' 'CD' INTO DATA(gv_cat).
  PERFORM show USING '4) CONCATENATE INTO' gv_cat.

* 5) FIND ... MATCH COUNT DATA( )
  FIND ALL OCCURRENCES OF 'a' IN 'banana' MATCH COUNT DATA(gv_cnt).
  PERFORM show USING '5) FIND MATCH COUNT' gv_cnt.

* 6) REPLACE ... REPLACEMENT COUNT DATA( )
  DATA(gv_str) = `banana`.
  REPLACE ALL OCCURRENCES OF 'a' IN gv_str WITH 'o' REPLACEMENT COUNT DATA(gv_rcnt).
  PERFORM show USING '6) REPLACE COUNT' gv_rcnt.

* 7) GET TIME STAMP FIELD DATA( )
  GET TIME STAMP FIELD DATA(gv_ts).
  PERFORM show USING '7) GET TIME STAMP' gv_ts.

* 8) DESCRIBE TABLE ... LINES DATA( )
  DESCRIBE TABLE gt LINES DATA(gv_lines).
  PERFORM show USING '8) DESCRIBE LINES' gv_lines.

* 9) WRITE ... TO DATA( )：不支援，啟用時報 Field "GV_WTXT" is unknown（實測），要先宣告接收變數
*  WRITE sy-datum TO DATA(gv_wtxt).

*&---------------------------------------------------------------------*
FORM show USING iv_label TYPE c
                iv_data  TYPE any.
  DATA(lo_type) = cl_abap_typedescr=>describe_by_data( iv_data ).
  WRITE: / iv_label, 'kind =', lo_type->type_kind, 'length =', lo_type->length,
           'name =', lo_type->absolute_name.
ENDFORM.
