CLASS zcl_oo05_carrier_stats DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* OOP 練習 5：op03 的 lcl_carrier_stats 搬家成全域類別
*   跟 local class 的差別：不綁在任何程式裡，全系統都能 NEW
*   注意：op03 版本的 WRITE 全部拿掉——全域類別只管邏輯，輸出是呼叫端的事
  PUBLIC SECTION.
    DATA mv_carrid TYPE s_carr_id READ-ONLY.

    METHODS:
      constructor IMPORTING iv_carrid TYPE s_carr_id,
      add_flights IMPORTING iv_count TYPE i,
      get_flights RETURNING VALUE(rv_flights) TYPE i.

  PRIVATE SECTION.
    DATA mv_flights TYPE i.
ENDCLASS.

CLASS zcl_oo05_carrier_stats IMPLEMENTATION.
  METHOD constructor.
    mv_carrid = iv_carrid.
  ENDMETHOD.

  METHOD add_flights.
*   守門：只接受正數（正式做法是丟例外——op09）
    IF iv_count > 0.
      mv_flights = mv_flights + iv_count.
    ENDIF.
  ENDMETHOD.

  METHOD get_flights.
    rv_flights = mv_flights.
  ENDMETHOD.
ENDCLASS.
