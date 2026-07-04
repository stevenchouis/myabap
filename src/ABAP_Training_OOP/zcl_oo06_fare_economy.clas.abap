CLASS zcl_oo06_fare_economy DEFINITION
  PUBLIC
  INHERITING FROM zcl_oo06_fare
  CREATE PUBLIC.

* 經濟艙：計價直接沿用父類別（原價），只需要實作抽象方法
  PUBLIC SECTION.
    METHODS get_cabin_name REDEFINITION.
ENDCLASS.

CLASS zcl_oo06_fare_economy IMPLEMENTATION.
  METHOD get_cabin_name.
    rv_name = '經濟艙'.
  ENDMETHOD.
ENDCLASS.
