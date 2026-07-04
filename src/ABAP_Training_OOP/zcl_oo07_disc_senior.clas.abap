CLASS zcl_oo07_disc_senior DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* OOP 練習 7：敬老票 8 折
  PUBLIC SECTION.
    INTERFACES zif_oo07_discount.
ENDCLASS.

CLASS zcl_oo07_disc_senior IMPLEMENTATION.
  METHOD zif_oo07_discount~get_name.
    rv_name = |敬老票(8折)|.
  ENDMETHOD.

  METHOD zif_oo07_discount~apply.
    rv_fare = iv_fare * '0.8'.
  ENDMETHOD.
ENDCLASS.
