REPORT zr_cds08_demo.

WRITE: / '=== 3-Layer CDS Report: ZR_CDS08_ROUTE_REVENUE_REPORT (p_carrid = LH) ==='.
SELECT carrid, connid, cityfrom, cityto, CarrierName,
       FlightCount, TotalRevenue, AvgSeatsOccupied, RevenueTier
  FROM zr_cds08_route_revenue_report( p_carrid = 'LH' )
  ORDER BY connid
  INTO TABLE @DATA(lt_cds_report).

LOOP AT lt_cds_report INTO DATA(ls_row).
  WRITE: / ls_row-carrid, ls_row-connid, ls_row-cityfrom, '->', ls_row-cityto,
           ls_row-carriername, ls_row-flightcount, ls_row-totalrevenue,
           ls_row-avgseatsoccupied, ls_row-revenuetier.
ENDLOOP.

WRITE: / '=== Sanity check: does RevenueTier match the same thresholds recomputed here? ==='.
DATA(lv_ok) = abap_true.
LOOP AT lt_cds_report INTO ls_row.
  DATA(lv_expected_tier) = COND string(
    WHEN ls_row-totalrevenue >= '2000000' THEN 'HIGH'
    WHEN ls_row-totalrevenue >= '1000000' THEN 'MEDIUM'
    ELSE 'LOW' ).
  IF ls_row-revenuetier <> lv_expected_tier.
    lv_ok = abap_false.
  ENDIF.
ENDLOOP.
IF lv_ok = abap_true AND lines( lt_cds_report ) = 5.
  WRITE: / 'MATCH: RevenueTier correctly derived through all 3 layers, route count', lines( lt_cds_report ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.

WRITE: / '=== Cross-check against ZR_CDS08_LEGACY_REPORT (run separately, same p_carrid = LH) ==='.
WRITE: / 'Legacy report route 0400 TotalRevenue = 2,151,305.97 (HIGH) -- confirm CDS report shows the same value/tier above'.
WRITE: / 'Legacy report route 2407 TotalRevenue =   304,920.00 (LOW)  -- confirm CDS report shows the same value/tier above'.
