CLASS zcl_oo13_flight_monitor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES tt_flights TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY.

*   事件宣告：發布者只定義「發生了什麼＋附帶哪些資料」
*   EXPORTING 參數強制 VALUE( ) 傳值——handler 拿到的是複本，
*   改了不會影響發布者或其他 handler
    EVENTS seats_low
      EXPORTING
        VALUE(iv_carrid) TYPE sflight-carrid
        VALUE(iv_connid) TYPE sflight-connid
        VALUE(iv_fldate) TYPE sflight-fldate
        VALUE(iv_pct)    TYPE i.

    METHODS constructor
      IMPORTING iv_threshold TYPE i DEFAULT 50.

    METHODS scan
      IMPORTING it_flights TYPE tt_flights.

    DATA mv_threshold TYPE i READ-ONLY.

ENDCLASS.


CLASS zcl_oo13_flight_monitor IMPLEMENTATION.

  METHOD constructor.
    mv_threshold = iv_threshold.
  ENDMETHOD.

  METHOD scan.
*   發布者只管 RAISE EVENT：有沒有人訂閱、訂閱者要做什麼，
*   它完全不知道——所以這個類別裡沒有任何 WRITE／輸出邏輯
    LOOP AT it_flights INTO DATA(ls_flight) WHERE seatsmax > 0.
      DATA(lv_pct) = ls_flight-seatsocc * 100 / ls_flight-seatsmax.
      IF lv_pct < mv_threshold.
        RAISE EVENT seats_low
          EXPORTING
            iv_carrid = ls_flight-carrid
            iv_connid = ls_flight-connid
            iv_fldate = ls_flight-fldate
            iv_pct    = lv_pct.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
