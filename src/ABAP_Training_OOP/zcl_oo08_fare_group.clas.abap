CLASS zcl_oo08_fare_group DEFINITION
  PUBLIC
  INHERITING FROM zcl_oo06_fare
  CREATE PUBLIC.

* OOP 練習 8：團體票——有「子類別專屬」方法 set_headcount
*   這正是向下轉型（downcast）的動機：
*   用父類別參考裝著它時，看不到 set_headcount，要 CAST 回子類別才叫得到
  PUBLIC SECTION.
    METHODS:
      set_headcount IMPORTING iv_count TYPE i,
      get_cabin_name REDEFINITION,
      calc_fare REDEFINITION.

  PRIVATE SECTION.
    DATA mv_headcount TYPE i VALUE 1.
ENDCLASS.

CLASS zcl_oo08_fare_group IMPLEMENTATION.
  METHOD set_headcount.
    mv_headcount = iv_count.
  ENDMETHOD.

  METHOD get_cabin_name.
    rv_name = |團體票({ mv_headcount }人)|.
  ENDMETHOD.

  METHOD calc_fare.
*   全團總價；10 人以上打 9 折
    rv_fare = super->calc_fare( iv_base_price ) * mv_headcount.
    IF mv_headcount >= 10.
      rv_fare = rv_fare * '0.9'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
