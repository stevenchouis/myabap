CLASS zcl_am07_route_stats DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    CLASS-METHODS get_data
      FOR TABLE FUNCTION ztf_am07_route_stats.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am07_route_stats IMPLEMENTATION.

  METHOD get_data BY DATABASE FUNCTION
    FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING scarr sflight.

    RETURN
      WITH route_totals AS (
        SELECT f.mandt,
               f.carrid,
               f.connid,
               COUNT(*) AS flight_cnt,
               SUM(f.seatsocc) AS seats_occ,
               SUM(f.seatsmax) AS seats_max
          FROM sflight AS f
          GROUP BY f.mandt, f.carrid, f.connid
      )
      SELECT rt.mandt,
             rt.carrid,
             c.carrname,
             rt.connid,
             rt.flight_cnt,
             rt.seats_occ,
             rt.seats_max,
             CAST(rt.seats_occ * 100.0 / rt.seats_max AS DECIMAL(5,1)) AS load_pct
        FROM route_totals AS rt
        JOIN scarr AS c
          ON c.mandt = rt.mandt
         AND c.carrid = rt.carrid;

  ENDMETHOD.

ENDCLASS.
