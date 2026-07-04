INTERFACE zif_oo07_discount
  PUBLIC.

* OOP 練習 7：折扣規則介面
*   介面只有「規格」沒有實作——誰實作它，誰就承諾提供這些方法
  METHODS:
    get_name
      RETURNING VALUE(rv_name) TYPE string,

    apply
      IMPORTING iv_fare        TYPE s_price
      RETURNING VALUE(rv_fare) TYPE s_price.
ENDINTERFACE.
