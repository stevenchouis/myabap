CLASS zcl_am09_carrier_stats DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    CLASS-METHODS get_data
      FOR TABLE FUNCTION ztf_am09_carrier_stats.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am09_carrier_stats IMPLEMENTATION.

  METHOD get_data BY DATABASE FUNCTION
    FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING scarr sflight.

    RETURN
      WITH route_agg AS (
        SELECT f.mandt,
               f.carrid,
               f.connid,
               COUNT(*) AS flight_cnt,
               SUM(f.seatsocc) AS seats_occ,
               SUM(f.seatsmax) AS seats_max,
               SUM(CAST(f.price * f.seatsocc AS DECIMAL(15,2))) AS route_revenue
          FROM sflight AS f
          GROUP BY f.mandt, f.carrid, f.connid
      ),
      carrier_agg AS (
        SELECT mandt,
               carrid,
               COUNT(*) AS route_cnt,
               SUM(flight_cnt) AS total_flights,
               SUM(seats_occ) AS total_seats_occ,
               SUM(seats_max) AS total_seats_max,
               SUM(route_revenue) AS total_revenue
          FROM route_agg
          GROUP BY mandt, carrid
      )
      SELECT ca.mandt,
             ca.carrid,
             c.carrname,
             ca.route_cnt,
             ca.total_flights,
             ca.total_seats_occ,
             ca.total_seats_max,
             CAST(ca.total_seats_occ * 100.0 / ca.total_seats_max AS DECIMAL(5,1)) AS load_pct,
             ca.total_revenue
        FROM carrier_agg AS ca
        JOIN scarr AS c
          ON c.mandt = ca.mandt
         AND c.carrid = ca.carrid;

  ENDMETHOD.

ENDCLASS.
