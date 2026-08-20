REPORT zr_cds07_demo.

WRITE: / '=== 1. CDS Aggregation: ZC_CDS07_ROUTE_STATS (carrid = AA) ==='.
SELECT SINGLE carrid, FlightCount, TotalSeatsOccupied, AvgPrice
  FROM zc_cds07_route_stats
  WHERE carrid = 'AA'
  INTO @DATA(ls_cds_agg).
WRITE: / 'FlightCount:', ls_cds_agg-flightcount,
       / 'TotalSeatsOccupied:', ls_cds_agg-totalseatsoccupied,
       / 'AvgPrice:', ls_cds_agg-avgprice.

WRITE: / '=== 2. Application-layer aggregation: fetch raw rows, loop in ABAP ==='.
SELECT carrid, seatsocc, price
  FROM sflight
  WHERE carrid = 'AA'
  INTO TABLE @DATA(lt_raw).

DATA: lv_count TYPE i,
      lv_sum_seats TYPE i,
      lv_sum_price TYPE p LENGTH 9 DECIMALS 2,
      lv_avg_price TYPE p LENGTH 9 DECIMALS 2.

LOOP AT lt_raw INTO DATA(ls_raw).
  lv_count = lv_count + 1.
  lv_sum_seats = lv_sum_seats + ls_raw-seatsocc.
  lv_sum_price = lv_sum_price + ls_raw-price.
ENDLOOP.
lv_avg_price = lv_sum_price / lv_count.

WRITE: / 'FlightCount:', lv_count,
       / 'TotalSeatsOccupied:', lv_sum_seats,
       / 'AvgPrice:', lv_avg_price.

WRITE: / '=== 3. Do CDS aggregation and application-layer loop agree? ==='.
DATA(lv_diff) = abs( ls_cds_agg-avgprice - lv_avg_price ).
IF ls_cds_agg-flightcount = lv_count
   AND ls_cds_agg-totalseatsoccupied = lv_sum_seats
   AND lv_diff < 1.
  WRITE: / 'MATCH: CDS aggregation and manual application-layer loop produce identical results'.
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.

WRITE: / '=== 4. Row counts moved across the network: CDS approach vs. application-layer approach ==='.
SELECT COUNT(*) FROM zc_cds07_route_stats INTO @DATA(lv_agg_rows).
WRITE: / 'CDS aggregation approach: rows transferred to application server =', lv_agg_rows, '(one row per carrier)'.
WRITE: / 'Application-layer approach: rows transferred to application server =', lines( lt_raw ), '(one row per flight, for AA alone)'.
