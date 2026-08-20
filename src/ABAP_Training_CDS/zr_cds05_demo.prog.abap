REPORT zr_cds05_demo.

WRITE: / '=== 1. Layer 1: ZI_CDS05_FLIGHT (Interface View, p_carrid = AA) ==='.
SELECT carrid, connid, fldate, OccupancyRatePercent
  FROM zi_cds05_flight( p_carrid = 'AA' )
  ORDER BY carrid, connid, fldate
  INTO TABLE @DATA(lt_iv)
  UP TO 3 ROWS.
LOOP AT lt_iv INTO DATA(ls_iv).
  WRITE: / ls_iv-carrid, ls_iv-connid, ls_iv-fldate, ls_iv-occupancyratepercent,
           '(no CarrierName / OccupancyStatus at this layer)'.
ENDLOOP.

WRITE: / '=== 2. Layer 2: ZC_CDS05_FLIGHT_REPORT (Composite View, p_carrid = AA) ==='.
SELECT carrid, connid, fldate, OccupancyRatePercent, OccupancyStatus, CarrierName
  FROM zc_cds05_flight_report( p_carrid = 'AA' )
  ORDER BY carrid, connid, fldate
  INTO TABLE @DATA(lt_cv)
  UP TO 3 ROWS.
LOOP AT lt_cv INTO DATA(ls_cv).
  WRITE: / ls_cv-carrid, ls_cv-connid, ls_cv-fldate, ls_cv-occupancyratepercent,
           ls_cv-occupancystatus, ls_cv-carriername.
ENDLOOP.

WRITE: / '=== 3. Layer 2 correctly derives OccupancyStatus from Layer 1 computed field? ==='.
DATA(lv_ok) = abap_true.
LOOP AT lt_cv INTO ls_cv.
  DATA(lv_expected) = COND #(
    WHEN ls_cv-occupancyratepercent >= '95' THEN 'FULL'
    WHEN ls_cv-occupancyratepercent >= '80' THEN 'NEARLY_FULL'
    ELSE 'AVAILABLE' ).
  IF ls_cv-occupancystatus <> lv_expected OR ls_cv-carriername IS INITIAL.
    lv_ok = abap_false.
  ENDIF.
ENDLOOP.
IF lv_ok = abap_true AND lines( lt_cv ) > 0.
  WRITE: / 'MATCH: OccupancyStatus correctly derived, CarrierName populated via association, row count', lines( lt_cv ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
