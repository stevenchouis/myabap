REPORT zr_cds01_demo.

WRITE: / '=== 1. 直接查表 SCARR (Open SQL) ==='.
SELECT carrid, carrname, currcode
  FROM scarr
  ORDER BY carrid
  INTO TABLE @DATA(lt_table)
  UP TO 3 ROWS.

LOOP AT lt_table INTO DATA(ls_table).
  WRITE: / ls_table-carrid, ls_table-carrname, ls_table-currcode.
ENDLOOP.

WRITE: / '=== 2. 查 CDS View ZI_CDS01_CARRIER (DDL Name) ==='.
SELECT carrid, carrname, currcode, url
  FROM zi_cds01_carrier
  ORDER BY carrid
  INTO TABLE @DATA(lt_view)
  UP TO 3 ROWS.

LOOP AT lt_view INTO DATA(ls_view).
  WRITE: / ls_view-carrid, ls_view-carrname, ls_view-currcode, ls_view-url.
ENDLOOP.

WRITE: / '=== 3. 筆數是否一致 ==='.
IF lines( lt_table ) = lines( lt_view ).
  WRITE: / 'MATCH: row counts equal', lines( lt_table ).
ELSE.
  WRITE: / 'MISMATCH', lines( lt_table ), lines( lt_view ).
ENDIF.
