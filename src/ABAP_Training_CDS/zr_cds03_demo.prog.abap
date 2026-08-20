REPORT zr_cds03_demo.

WRITE: / '=== 1. ZI_CDS03_FLIGHT_SCHEDULE (association declared, not consumed) ==='.
SELECT carrid, connid, cityfrom, cityto
  FROM zi_cds03_flight_schedule
  WHERE carrid = 'LH'
  ORDER BY carrid, connid
  INTO TABLE @DATA(lt_iv)
  UP TO 3 ROWS.
LOOP AT lt_iv INTO DATA(ls_iv).
  WRITE: / ls_iv-carrid, ls_iv-connid, ls_iv-cityfrom, '->', ls_iv-cityto,
           '(no carrier name exposed at this layer)'.
ENDLOOP.

WRITE: / '=== 2. ZC_CDS03_FLIGHT_WITH_CARRIER (consumes _Carrier association) ==='.
SELECT carrid, connid, cityfrom, cityto, CarrierName
  FROM zc_cds03_flight_with_carrier
  WHERE carrid = 'LH'
  ORDER BY carrid, connid
  INTO TABLE @DATA(lt_assoc)
  UP TO 3 ROWS.
LOOP AT lt_assoc INTO DATA(ls_assoc).
  WRITE: / ls_assoc-carrid, ls_assoc-connid, ls_assoc-cityfrom, '->', ls_assoc-cityto,
           '|', ls_assoc-carriername.
ENDLOOP.

WRITE: / '=== 3. ZI_CDS03_FLIGHT_JOIN (direct INNER JOIN) ==='.
SELECT carrid, connid, cityfrom, cityto, CarrierName
  FROM zi_cds03_flight_join
  WHERE carrid = 'LH'
  ORDER BY carrid, connid
  INTO TABLE @DATA(lt_join)
  UP TO 3 ROWS.
LOOP AT lt_join INTO DATA(ls_join).
  WRITE: / ls_join-carrid, ls_join-connid, ls_join-cityfrom, '->', ls_join-cityto,
           '|', ls_join-carriername.
ENDLOOP.

WRITE: / '=== 4. Carrier names match between Association-path and direct JOIN? ==='.
DATA(lv_match) = abap_true.
LOOP AT lt_assoc INTO ls_assoc.
  READ TABLE lt_join INTO ls_join WITH KEY carrid = ls_assoc-carrid connid = ls_assoc-connid.
  IF sy-subrc <> 0 OR ls_join-carriername <> ls_assoc-carriername.
    lv_match = abap_false.
  ENDIF.
ENDLOOP.
IF lv_match = abap_true AND lines( lt_assoc ) = lines( lt_join ) AND lines( lt_assoc ) > 0.
  WRITE: / 'MATCH: carrier names identical via both paths, row count', lines( lt_assoc ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
