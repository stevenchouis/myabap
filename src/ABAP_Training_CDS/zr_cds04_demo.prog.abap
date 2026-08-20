REPORT zr_cds04_demo.

WRITE: / '=== 1. Parameterized query: p_carrid = AA ==='.
SELECT carrid, connid, fldate, DaysFromToday, TimeStatus, QueriedByUser
  FROM zi_cds04_flight( p_carrid = 'AA' )
  ORDER BY carrid, connid, fldate
  INTO TABLE @DATA(lt_aa)
  UP TO 5 ROWS.
LOOP AT lt_aa INTO DATA(ls_aa).
  WRITE: / ls_aa-carrid, ls_aa-connid, ls_aa-fldate, ls_aa-daysfromtoday,
           ls_aa-timestatus, ls_aa-queriedbyuser.
ENDLOOP.

WRITE: / '=== 2. All rows have carrid = AA? ==='.
DATA(lv_all_aa) = abap_true.
LOOP AT lt_aa INTO ls_aa WHERE carrid <> 'AA'.
  lv_all_aa = abap_false.
ENDLOOP.
IF lv_all_aa = abap_true AND lines( lt_aa ) > 0.
  WRITE: / 'MATCH: parameter filter applied correctly, row count', lines( lt_aa ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.

WRITE: / '=== 3. Parameterized query: p_carrid = LH (different parameter value) ==='.
SELECT carrid, connid, fldate, TimeStatus
  FROM zi_cds04_flight( p_carrid = 'LH' )
  ORDER BY carrid, connid, fldate
  INTO TABLE @DATA(lt_lh)
  UP TO 3 ROWS.
LOOP AT lt_lh INTO DATA(ls_lh).
  WRITE: / ls_lh-carrid, ls_lh-connid, ls_lh-fldate, ls_lh-timestatus.
ENDLOOP.

WRITE: / '=== 4. System date used for comparison ==='.
WRITE: / 'sy-datum:', sy-datum.
