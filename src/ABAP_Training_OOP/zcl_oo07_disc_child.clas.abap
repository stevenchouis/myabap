CLASS zcl_oo07_disc_child DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* OOP 練習 7：兒童票 65 折
*   op06 思考題 2 的解答：折扣不開艙等子類別，改用介面另立一族規則
  PUBLIC SECTION.
    INTERFACES zif_oo07_discount.
ENDCLASS.

CLASS zcl_oo07_disc_child IMPLEMENTATION.
  METHOD zif_oo07_discount~get_name.
    rv_name = |兒童票(65折)|.
  ENDMETHOD.

  METHOD zif_oo07_discount~apply.
    rv_fare = iv_fare * '0.65'.
  ENDMETHOD.
ENDCLASS.
