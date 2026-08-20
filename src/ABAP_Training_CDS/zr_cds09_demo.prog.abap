REPORT zr_cds09_demo.

WRITE: / '=== Query ZI_CDS01_CARRIER (original view, now carrying the extended field) ==='.
SELECT carrid, carrname, Status
  FROM zi_cds01_carrier
  ORDER BY carrid
  INTO TABLE @DATA(lt_result)
  UP TO 5 ROWS.

LOOP AT lt_result INTO DATA(ls_row).
  WRITE: / ls_row-carrid, ls_row-carrname, ls_row-status.
ENDLOOP.

WRITE: / '=== Sanity check: all rows carry Status = ACTIVE from the extension ==='.
DATA(lv_ok) = abap_true.
LOOP AT lt_result INTO ls_row WHERE status <> 'ACTIVE'.
  lv_ok = abap_false.
ENDLOOP.
IF lv_ok = abap_true AND lines( lt_result ) > 0.
  WRITE: / 'MATCH: extended field Status is available on the original view, row count', lines( lt_result ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
