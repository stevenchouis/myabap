CLASS zcl_oo12_flight_revenue DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* OOP 練習 12：航班營收——ex13 的商業邏輯搬進類別
*   設計重點：
*   - get_revenues：取數（SELECT）+ 計算，查無資料丟 ZCX_OO12_NO_DATA
*   - build：純計算、不碰 DB——單元測試餵假資料就能測（op10 的教訓落地）
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_revenue,
             carrid   TYPE sflight-carrid,     " 航空公司
             carrname TYPE scarr-carrname,     " 公司名稱
             connid   TYPE sflight-connid,     " 航線
             fldate   TYPE sflight-fldate,     " 航班日期
             seatsocc TYPE sflight-seatsocc,   " 已售座位
             price    TYPE sflight-price,      " 票價
             currency TYPE sflight-currency,   " 幣別
             revenue  TYPE p LENGTH 12 DECIMALS 2,  " 營收 = 票價 × 已售座位
           END OF ty_revenue,
           tt_revenue TYPE STANDARD TABLE OF ty_revenue WITH DEFAULT KEY,
           tr_carrid  TYPE RANGE OF sflight-carrid,
           tr_fldate  TYPE RANGE OF sflight-fldate.

    METHODS:
*     取數 + 計算（= ex13 的 FORM get_data）
      get_revenues IMPORTING ir_carrid          TYPE tr_carrid OPTIONAL
                             ir_fldate          TYPE tr_fldate OPTIONAL
                             iv_skip_unsold     TYPE abap_bool DEFAULT abap_true
                   RETURNING VALUE(rt_revenues) TYPE tt_revenue
                   RAISING   zcx_oo12_no_data,

*     純計算：排除未售出（可選）+ 逐筆算營收；不碰 DB，測試餵假資料即可
      build IMPORTING it_flights         TYPE tt_revenue
                      iv_skip_unsold     TYPE abap_bool DEFAULT abap_true
            RETURNING VALUE(rt_revenues) TYPE tt_revenue.
ENDCLASS.

CLASS zcl_oo12_flight_revenue IMPLEMENTATION.
  METHOD get_revenues.
    DATA lt_flights TYPE tt_revenue.

    SELECT f~carrid, c~carrname, f~connid, f~fldate,
           f~seatsocc, f~price, f~currency
      INTO CORRESPONDING FIELDS OF TABLE @lt_flights
      FROM sflight AS f
      INNER JOIN scarr AS c ON f~carrid = c~carrid
      WHERE f~carrid IN @ir_carrid
        AND f~fldate IN @ir_fldate.

    rt_revenues = build( it_flights     = lt_flights
                         iv_skip_unsold = iv_skip_unsold ).

    IF rt_revenues IS INITIAL.
      RAISE EXCEPTION TYPE zcx_oo12_no_data.
    ENDIF.
  ENDMETHOD.

  METHOD build.
    rt_revenues = it_flights.

    IF iv_skip_unsold = abap_true.
      DELETE rt_revenues WHERE seatsocc = 0.
    ENDIF.

    LOOP AT rt_revenues ASSIGNING FIELD-SYMBOL(<ls_revenue>).
      <ls_revenue>-revenue = <ls_revenue>-price * <ls_revenue>-seatsocc.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

