CLASS zcl_am04_route_load DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    TYPES:
      BEGIN OF ty_route_load,
        carrid     TYPE s_carr_id,
        carrname   TYPE s_carrname,
        connid     TYPE s_conn_id,
        flight_cnt TYPE i,
        seats_occ  TYPE i,
        seats_max  TYPE i,
        load_pct   TYPE p LENGTH 5 DECIMALS 1,
      END OF ty_route_load,
      tt_route_load TYPE STANDARD TABLE OF ty_route_load WITH EMPTY KEY.

    CLASS-METHODS get_route_load_factor
      IMPORTING
        VALUE(iv_mandt)  TYPE mandt
      EXPORTING
        VALUE(et_routes) TYPE tt_route_load.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am04_route_load IMPLEMENTATION.

  METHOD get_route_load_factor BY DATABASE PROCEDURE
    FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING scarr sflight.

    et_routes =
      WITH route_totals AS (
        SELECT f.mandt,
               f.carrid,
               f.connid,
               COUNT(*) AS flight_cnt,
               SUM(f.seatsocc) AS seats_occ,
               SUM(f.seatsmax) AS seats_max
          FROM sflight AS f
          WHERE f.mandt = :iv_mandt
          GROUP BY f.mandt, f.carrid, f.connid
      )
      SELECT rt.carrid,
             c.carrname,
             rt.connid,
             rt.flight_cnt,
             rt.seats_occ,
             rt.seats_max,
             CAST(rt.seats_occ * 100.0 / rt.seats_max AS DECIMAL(5,1)) AS load_pct
        FROM route_totals AS rt
        JOIN scarr AS c
          ON c.mandt = rt.mandt
         AND c.carrid = rt.carrid
        ORDER BY rt.carrid, rt.connid;

  ENDMETHOD.

ENDCLASS.
