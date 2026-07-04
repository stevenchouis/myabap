CLASS zcl_oo06_fare DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC.

* OOP 練習 6：艙等計價的抽象基底
*   ABSTRACT：本類別不能 NEW，只能被繼承——它是「規格」不是「商品」
  PUBLIC SECTION.
    METHODS:
*     基底給預設實作（原價），要加價的艙等自己 REDEFINITION
      calc_fare IMPORTING iv_base_price  TYPE s_price
                RETURNING VALUE(rv_fare) TYPE s_price,

*     抽象方法：只有宣告沒有實作，強迫每個子類別自報艙等名
      get_cabin_name ABSTRACT
        RETURNING VALUE(rv_name) TYPE string.
ENDCLASS.

CLASS zcl_oo06_fare IMPLEMENTATION.
  METHOD calc_fare.
    rv_fare = iv_base_price.
  ENDMETHOD.
ENDCLASS.
