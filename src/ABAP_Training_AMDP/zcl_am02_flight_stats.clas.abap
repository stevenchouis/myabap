CLASS zcl_am02_flight_stats DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    TYPES:
      BEGIN OF ty_flight,
        carrid   TYPE s_carr_id,
        connid   TYPE s_conn_id,
        fldate   TYPE s_date,
        price    TYPE s_price,
        currency TYPE s_currcode,
      END OF ty_flight,
      tt_flight TYPE STANDARD TABLE OF ty_flight WITH EMPTY KEY,

      BEGIN OF ty_stats,
        connid     TYPE s_conn_id,
        flight_cnt TYPE i,
        avg_price  TYPE s_price,
        min_price  TYPE s_price,
        max_price  TYPE s_price,
      END OF ty_stats,
      tt_stats TYPE STANDARD TABLE OF ty_stats WITH EMPTY KEY.

    CLASS-METHODS get_flight_stats
      IMPORTING
        VALUE(iv_mandt)   TYPE mandt
        VALUE(iv_carrid)  TYPE s_carr_id
      EXPORTING
        VALUE(et_flights) TYPE tt_flight
        VALUE(et_stats)   TYPE tt_stats.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am02_flight_stats IMPLEMENTATION.

  METHOD get_flight_stats BY DATABASE PROCEDURE
    FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING sflight.

    et_flights = SELECT carrid, connid, fldate, price, currency
                   FROM sflight
                   WHERE mandt = :iv_mandt
                     AND carrid = :iv_carrid
                   ORDER BY connid, fldate;

    et_stats = SELECT connid,
                      COUNT(*) AS flight_cnt,
                      AVG(price) AS avg_price,
                      MIN(price) AS min_price,
                      MAX(price) AS max_price
                 FROM sflight
                 WHERE mandt = :iv_mandt
                   AND carrid = :iv_carrid
                 GROUP BY connid
                 ORDER BY connid;

  ENDMETHOD.

ENDCLASS.
