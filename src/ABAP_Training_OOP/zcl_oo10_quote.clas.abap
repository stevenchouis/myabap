CLASS zcl_oo10_quote DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* OOP 練習 10：報價引擎——為「可測試」而設計
*   艙等與折扣都從建構子「注入」（不在方法裡自己 NEW）：
*   正式程式注入真的艙等/折扣，測試注入固定行為的測試替身
  PUBLIC SECTION.
    TYPES tt_discounts TYPE STANDARD TABLE OF REF TO zif_oo07_discount
                       WITH DEFAULT KEY.

    METHODS:
      constructor IMPORTING io_fare      TYPE REF TO zcl_oo06_fare
                            it_discounts TYPE tt_discounts OPTIONAL,

*     最終票價 = 艙等計價後，依序套用所有折扣
      calc_quote IMPORTING iv_base_price   TYPE s_price
                 RETURNING VALUE(rv_total) TYPE s_price.

  PRIVATE SECTION.
    DATA: mo_fare      TYPE REF TO zcl_oo06_fare,
          mt_discounts TYPE tt_discounts.
ENDCLASS.

CLASS zcl_oo10_quote IMPLEMENTATION.
  METHOD constructor.
    mo_fare      = io_fare.
    mt_discounts = it_discounts.
  ENDMETHOD.

  METHOD calc_quote.
    rv_total = mo_fare->calc_fare( iv_base_price ).

    LOOP AT mt_discounts INTO DATA(lo_discount).
      rv_total = lo_discount->apply( rv_total ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

