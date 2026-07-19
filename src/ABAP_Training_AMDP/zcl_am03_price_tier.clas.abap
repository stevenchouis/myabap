CLASS zcl_am03_price_tier DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    TYPES:
      BEGIN OF ty_flight_tier,
        carrid     TYPE s_carr_id,
        connid     TYPE s_conn_id,
        fldate     TYPE s_date,
        price      TYPE s_price,
        currency   TYPE s_currcode,
        price_tier TYPE string,
      END OF ty_flight_tier,
      tt_flight_tier TYPE STANDARD TABLE OF ty_flight_tier WITH EMPTY KEY.

    CLASS-METHODS classify_flight_prices
      IMPORTING
        VALUE(iv_mandt)      TYPE mandt
        VALUE(iv_carrid)     TYPE s_carr_id
      EXPORTING
        VALUE(et_flights)    TYPE tt_flight_tier
        VALUE(ev_low_cnt)    TYPE i
        VALUE(ev_medium_cnt) TYPE i
        VALUE(ev_high_cnt)   TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am03_price_tier IMPLEMENTATION.

  METHOD classify_flight_prices BY DATABASE PROCEDURE
    FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING sflight.

    DECLARE lv_low_cnt    INTEGER := 0;
    DECLARE lv_medium_cnt INTEGER := 0;
    DECLARE lv_high_cnt   INTEGER := 0;

    DECLARE CURSOR cur_prices FOR
      SELECT price FROM sflight
       WHERE mandt = :iv_mandt AND carrid = :iv_carrid;

    et_flights = SELECT carrid, connid, fldate, price, currency,
                        CASE
                          WHEN price < 300 THEN 'LOW'
                          WHEN price < 700 THEN 'MEDIUM'
                          ELSE 'HIGH'
                        END AS price_tier
                   FROM sflight
                   WHERE mandt = :iv_mandt
                     AND carrid = :iv_carrid
                   ORDER BY connid, fldate;

    FOR cur_row AS cur_prices DO
      IF cur_row.price < 300 THEN
        lv_low_cnt := lv_low_cnt + 1;
      ELSEIF cur_row.price < 700 THEN
        lv_medium_cnt := lv_medium_cnt + 1;
      ELSE
        lv_high_cnt := lv_high_cnt + 1;
      END IF;
    END FOR;

    ev_low_cnt    := lv_low_cnt;
    ev_medium_cnt := lv_medium_cnt;
    ev_high_cnt   := lv_high_cnt;

  ENDMETHOD.

ENDCLASS.
