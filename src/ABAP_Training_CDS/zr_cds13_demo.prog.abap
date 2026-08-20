REPORT zr_cds13_demo.

WRITE: / '=== ZI_CDS13_FLIGHT_VH: Open SQL still works normally (annotations are pure metadata) ==='.
SELECT carrid, connid, fldate, CarrierName
  FROM zi_cds13_flight_vh
  ORDER BY carrid, connid, fldate
  INTO TABLE @DATA(lt_result)
  UP TO 5 ROWS.

LOOP AT lt_result INTO DATA(ls_row).
  WRITE: / ls_row-carrid, ls_row-connid, ls_row-fldate, ls_row-carriername.
ENDLOOP.

WRITE: / '=== Sanity check: CarrierName populated via the same association used for value help/text ==='.
DATA(lv_ok) = abap_true.
LOOP AT lt_result INTO ls_row WHERE carriername IS INITIAL.
  lv_ok = abap_false.
ENDLOOP.
IF lv_ok = abap_true AND lines( lt_result ) > 0.
  WRITE: / 'MATCH: value help / text annotations do not affect normal query behavior, row count', lines( lt_result ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
