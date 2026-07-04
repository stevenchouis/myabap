CLASS zcl_oo06_fare_first DEFINITION
  PUBLIC
  INHERITING FROM zcl_oo06_fare_business
  FINAL
  CREATE PUBLIC.

* 頭等艙：繼承「商務艙」不是基底——super-> 會把兩層加價串起來
*   FINAL：封死繼承，沒有人可以再繼承頭等艙
  PUBLIC SECTION.
    METHODS:
      calc_fare      REDEFINITION,
      get_cabin_name REDEFINITION.
ENDCLASS.

CLASS zcl_oo06_fare_first IMPLEMENTATION.
  METHOD calc_fare.
*   商務艙價（原價 × 2.5）再乘 1.6 → 原價 × 4
    rv_fare = super->calc_fare( iv_base_price ) * '1.6'.
  ENDMETHOD.

  METHOD get_cabin_name.
    rv_name = '頭等艙'.
  ENDMETHOD.
ENDCLASS.
