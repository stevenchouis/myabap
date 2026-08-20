REPORT zr_cds11_demo.

WRITE: / '=== ZC_CDS11_ROUTE_ANALYTICS (carrid = LH) ==='.
SELECT carrid, connid, currency, TotalRevenue, TotalSeatsOccupied, FlightCount
  FROM zc_cds11_route_analytics
  WHERE carrid = 'LH'
  ORDER BY connid
  INTO TABLE @DATA(lt_result).

LOOP AT lt_result INTO DATA(ls_row).
  WRITE: / ls_row-carrid, ls_row-connid, ls_row-currency, ls_row-totalrevenue,
           ls_row-totalseatsoccupied, ls_row-flightcount.
ENDLOOP.

WRITE: / '=== Sanity check: matches cds08 legacy report numbers for LH ==='.
DATA(lv_ok) = abap_true.
LOOP AT lt_result INTO ls_row.
  CASE ls_row-connid.
    WHEN '0400'. IF ls_row-totalrevenue <> '2151305.97' OR ls_row-flightcount <> 16. lv_ok = abap_false. ENDIF.
    WHEN '2407'. IF ls_row-totalrevenue <> '304920.00'  OR ls_row-flightcount <> 15. lv_ok = abap_false. ENDIF.
  ENDCASE.
ENDLOOP.
IF lv_ok = abap_true AND lines( lt_result ) = 5.
  WRITE: / 'MATCH: analytical aggregation reproduces the same numbers as cds08, route count', lines( lt_result ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
