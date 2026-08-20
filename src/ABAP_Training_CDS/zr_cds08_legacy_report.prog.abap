REPORT zr_cds08_legacy_report.

PARAMETERS: p_carrid TYPE sflight-carrid DEFAULT 'LH'.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE sflight-carrid,
         connid   TYPE sflight-connid,
         price    TYPE sflight-price,
         seatsocc TYPE sflight-seatsocc,
       END OF ty_flight.

TYPES: BEGIN OF ty_route_stat,
         carrid            TYPE sflight-carrid,
         connid            TYPE sflight-connid,
         cityfrom          TYPE spfli-cityfrom,
         cityto            TYPE spfli-cityto,
         carrname          TYPE scarr-carrname,
         flight_count      TYPE i,
         total_revenue     TYPE p LENGTH 15 DECIMALS 2,
         sum_seats         TYPE i,
         avg_seats_occ     TYPE p LENGTH 9 DECIMALS 2,
         revenue_tier      TYPE string,
       END OF ty_route_stat.

DATA: lt_flight TYPE STANDARD TABLE OF ty_flight,
      lt_stats   TYPE STANDARD TABLE OF ty_route_stat,
      ls_stats   TYPE ty_route_stat.

START-OF-SELECTION.

  " Step 1: fetch raw flight data for the selected carrier
  SELECT carrid, connid, price, seatsocc
    FROM sflight
    WHERE carrid = @p_carrid
    INTO TABLE @lt_flight.

  " Step 2: manually group by route (carrid + connid) and accumulate stats
  SORT lt_flight BY carrid connid.
  LOOP AT lt_flight INTO DATA(ls_flight).
    READ TABLE lt_stats WITH KEY carrid = ls_flight-carrid connid = ls_flight-connid
      INTO ls_stats.
    IF sy-subrc <> 0.
      CLEAR ls_stats.
      ls_stats-carrid = ls_flight-carrid.
      ls_stats-connid = ls_flight-connid.
      APPEND ls_stats TO lt_stats.
    ENDIF.

    ls_stats-flight_count  = ls_stats-flight_count + 1.
    ls_stats-total_revenue = ls_stats-total_revenue + ( ls_flight-price * ls_flight-seatsocc ).
    ls_stats-sum_seats     = ls_stats-sum_seats + ls_flight-seatsocc.

    MODIFY lt_stats FROM ls_stats
      TRANSPORTING flight_count total_revenue sum_seats
      WHERE carrid = ls_stats-carrid AND connid = ls_stats-connid.
  ENDLOOP.

  " Step 3: for each route, look up city names and carrier name (separate SELECTs -
  "         this is the kind of repeated single-row lookup a pre-CDS report often has)
  LOOP AT lt_stats INTO ls_stats.
    ls_stats-avg_seats_occ = ls_stats-sum_seats / ls_stats-flight_count.

    SELECT SINGLE cityfrom, cityto FROM spfli
      WHERE carrid = @ls_stats-carrid AND connid = @ls_stats-connid
      INTO ( @ls_stats-cityfrom, @ls_stats-cityto ).

    SELECT SINGLE carrname FROM scarr
      WHERE carrid = @ls_stats-carrid
      INTO @ls_stats-carrname.

    " Step 4: manually classify revenue tier - same thresholds as the CDS version
    IF ls_stats-total_revenue >= 2000000.
      ls_stats-revenue_tier = 'HIGH'.
    ELSEIF ls_stats-total_revenue >= 1000000.
      ls_stats-revenue_tier = 'MEDIUM'.
    ELSE.
      ls_stats-revenue_tier = 'LOW'.
    ENDIF.

    MODIFY lt_stats FROM ls_stats.
  ENDLOOP.

  LOOP AT lt_stats INTO ls_stats.
    WRITE: / ls_stats-carrid, ls_stats-connid, ls_stats-cityfrom, '->', ls_stats-cityto,
             ls_stats-carrname, ls_stats-flight_count, ls_stats-total_revenue,
             ls_stats-avg_seats_occ, ls_stats-revenue_tier.
  ENDLOOP.
