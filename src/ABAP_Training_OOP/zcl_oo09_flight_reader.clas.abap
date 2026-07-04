CLASS zcl_oo09_flight_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* OOP 練習 9：航班讀取——查無資料丟出類別型例外
*   對照 ex15 的 classic EXCEPTIONS：那套要呼叫端記得檢查 sy-subrc，
*   忘了檢查照樣往下跑；RAISING 宣告的例外不接就編譯不過
  PUBLIC SECTION.
    TYPES tt_flights TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY.

    METHODS get_flights
      IMPORTING iv_carrid         TYPE s_carr_id
      RETURNING VALUE(rt_flights) TYPE tt_flights
      RAISING   zcx_oo09_no_flight.
ENDCLASS.

CLASS zcl_oo09_flight_reader IMPLEMENTATION.
  METHOD get_flights.
    SELECT * FROM sflight
      WHERE carrid = @iv_carrid
      INTO TABLE @rt_flights.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_oo09_no_flight
        EXPORTING iv_carrid = iv_carrid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
