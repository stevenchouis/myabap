CLASS zcl_am08_flight_revenue DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    TYPES:
      BEGIN OF ty_revenue,
        carrid   TYPE s_carr_id,
        carrname TYPE s_carrname,
        connid   TYPE s_conn_id,
        fldate   TYPE s_date,
        seatsocc TYPE s_seatsocc,
        price    TYPE s_price,
        currency TYPE s_currcode,
        revenue  TYPE p LENGTH 8 DECIMALS 2,
      END OF ty_revenue,
      tt_revenue TYPE STANDARD TABLE OF ty_revenue WITH EMPTY KEY.

    CLASS-METHODS get_revenues
      IMPORTING
        VALUE(iv_mandt)        TYPE mandt
        VALUE(iv_carrid)       TYPE s_carr_id
        VALUE(iv_skip_unsold)  TYPE abap_bool
      EXPORTING
        VALUE(et_revenue)      TYPE tt_revenue.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am08_flight_revenue IMPLEMENTATION.

  METHOD get_revenues BY DATABASE PROCEDURE
    FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING scarr sflight.

    et_revenue = SELECT f.carrid,
                        c.carrname,
                        f.connid,
                        f.fldate,
                        f.seatsocc,
                        f.price,
                        f.currency,
                        CAST(f.price * f.seatsocc AS DECIMAL(15,2)) AS revenue
                   FROM sflight AS f
                   JOIN scarr AS c
                     ON c.mandt = f.mandt
                    AND c.carrid = f.carrid
                   WHERE f.mandt = :iv_mandt
                     AND f.carrid = :iv_carrid
                     AND ( f.seatsocc > 0 OR :iv_skip_unsold <> 'X' )
                   ORDER BY f.connid, f.fldate;

  ENDMETHOD.

ENDCLASS.
