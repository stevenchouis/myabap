CLASS zcl_oo06_fare_business DEFINITION
  PUBLIC
  INHERITING FROM zcl_oo06_fare
  CREATE PUBLIC.

* 商務艙：覆寫計價——先用 super-> 拿父類別的結果，再套自己的加價規則
  PUBLIC SECTION.
    METHODS:
      calc_fare      REDEFINITION,
      get_cabin_name REDEFINITION.
ENDCLASS.

CLASS zcl_oo06_fare_business IMPLEMENTATION.
  METHOD calc_fare.
*   子類別只寫「差異」，共通邏輯留在父類別一份
    rv_fare = super->calc_fare( iv_base_price ) * '2.5'.
  ENDMETHOD.

  METHOD get_cabin_name.
    rv_name = '商務艙'.
  ENDMETHOD.
ENDCLASS.
