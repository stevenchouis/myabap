REPORT zr_cds06_demo.

WRITE: / '=== 1. ZI_CDS06_FLIGHT (#CHECK, DCL role restricts to carrid = AA) ==='.
WRITE: / '    Query intentionally asks for ALL carriers (no WHERE clause):'.
SELECT carrid, connid, fldate
  FROM zi_cds06_flight
  ORDER BY carrid, connid, fldate
  INTO TABLE @DATA(lt_checked).
LOOP AT lt_checked INTO DATA(ls_checked) FROM 1 TO 5.
  WRITE: / ls_checked-carrid, ls_checked-connid, ls_checked-fldate.
ENDLOOP.
WRITE: / 'Total rows returned:', lines( lt_checked ).

WRITE: / '=== 2. Distinct carriers actually returned (should be AA only) ==='.
DATA(lv_only_aa) = abap_true.
LOOP AT lt_checked INTO ls_checked WHERE carrid <> 'AA'.
  lv_only_aa = abap_false.
ENDLOOP.
IF lv_only_aa = abap_true AND lines( lt_checked ) > 0.
  WRITE: / 'MATCH: DCL access control silently filtered to carrid = AA, row count', lines( lt_checked ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.

WRITE: / '=== 3. ZI_CDS02_FLIGHT (#NOT_REQUIRED, no access control) ==='.
WRITE: / '    Same kind of query, no WHERE clause:'.
SELECT AirlineID, ConnectionID, FlightDate
  FROM zi_cds02_flight
  ORDER BY AirlineID, ConnectionID, FlightDate
  INTO TABLE @DATA(lt_open).
DATA(lv_carriers) = VALUE string_table( ).
LOOP AT lt_open INTO DATA(ls_open).
  IF NOT line_exists( lv_carriers[ table_line = ls_open-airlineid ] ).
    APPEND ls_open-airlineid TO lv_carriers.
  ENDIF.
ENDLOOP.
WRITE: / 'Total rows returned:', lines( lt_open ), '| distinct carriers:', lines( lv_carriers ).
IF lines( lv_carriers ) > 1.
  WRITE: / 'MATCH: without access control, multiple carriers are visible (no silent filtering)'.
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
