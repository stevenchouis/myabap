REPORT zr_cds15_demo.

DATA: lv_t1 TYPE i, lv_t2 TYPE i, lv_t3 TYPE i, lv_diff TYPE i.

WRITE: / '=== Measurement 1: CDS aggregation (ZC_CDS07_ROUTE_STATS) vs manual ABAP loop aggregation ==='.

GET RUN TIME FIELD lv_t1.
SELECT carrid, FlightCount, TotalSeatsOccupied, AvgPrice
  FROM zc_cds07_route_stats
  INTO TABLE @DATA(lt_cds_agg).
GET RUN TIME FIELD lv_t2.
lv_diff = lv_t2 - lv_t1.
WRITE: / 'CDS aggregation elapsed (microseconds):', lv_diff, '| rows:', lines( lt_cds_agg ).

GET RUN TIME FIELD lv_t1.
SELECT carrid, seatsocc, price FROM sflight INTO TABLE @DATA(lt_raw).
TYPES: BEGIN OF ty_agg,
         carrid TYPE sflight-carrid,
         cnt    TYPE i,
         seats  TYPE i,
       END OF ty_agg.
DATA lt_manual TYPE STANDARD TABLE OF ty_agg WITH EMPTY KEY.
LOOP AT lt_raw INTO DATA(ls_raw).
  READ TABLE lt_manual WITH KEY carrid = ls_raw-carrid ASSIGNING FIELD-SYMBOL(<ls_m>).
  IF sy-subrc <> 0.
    APPEND VALUE #( carrid = ls_raw-carrid ) TO lt_manual ASSIGNING <ls_m>.
  ENDIF.
  <ls_m>-cnt = <ls_m>-cnt + 1.
  <ls_m>-seats = <ls_m>-seats + ls_raw-seatsocc.
ENDLOOP.
GET RUN TIME FIELD lv_t3.
lv_diff = lv_t3 - lv_t1.
WRITE: / 'Manual loop elapsed (microseconds):', lv_diff, '| raw rows fetched:', lines( lt_raw ), '| groups:', lines( lt_manual ).

WRITE: / '(!) Honest caveat: dataset is only 356 rows total - timing differences here are NOT a reliable performance benchmark,'.
WRITE: / 'they only demonstrate the MEASUREMENT TECHNIQUE (GET RUN TIME FIELD). See cds07 for the more meaningful comparison:'.
WRITE: / 'row-transfer-count differs by a known, data-volume-independent ratio (8 aggregated rows vs N raw rows).'.

WRITE: / '=== Measurement 2: Association pitfall - unconsumed vs consumed (recap of cds03 finding) ==='.
GET RUN TIME FIELD lv_t1.
SELECT carrid, connid, cityfrom, cityto FROM zi_cds03_flight_schedule WHERE carrid = 'LH' INTO TABLE @DATA(lt_unconsumed).
GET RUN TIME FIELD lv_t2.
lv_diff = lv_t2 - lv_t1.
WRITE: / 'Query WITHOUT consuming _Carrier association, elapsed (microseconds):', lv_diff, '| rows:', lines( lt_unconsumed ).

GET RUN TIME FIELD lv_t1.
SELECT carrid, connid, cityfrom, cityto, CarrierName FROM zc_cds03_flight_with_carrier WHERE carrid = 'LH' INTO TABLE @DATA(lt_consumed).
GET RUN TIME FIELD lv_t2.
lv_diff = lv_t2 - lv_t1.
WRITE: / 'Query consuming _Carrier association (extra JOIN), elapsed (microseconds):', lv_diff, '| rows:', lines( lt_consumed ).

WRITE: / '=== Common performance pitfalls this course has directly evidenced (not speculation) ==='.
WRITE: / '1. Consuming an Association you do not actually need pulls in an extra JOIN every single query (cds03).'.
WRITE: / '2. Aggregating in the CDS layer transfers far fewer rows to the application server than fetching details and looping (cds07).'.
WRITE: / '3. "Too many layers" is not always avoidable on this system: CASE WHEN cannot reference a same-statement computed'.
WRITE: / '   alias (cds02), and aggregate functions cannot take an expression as argument (cds11) - both FORCE an extra layer.'.
WRITE: / '   Do not blindly flatten every layered design; some layers exist because the compiler requires them, not for style.'.
