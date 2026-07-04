CLASS zcx_oo12_no_data DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

* OOP 練習 12：查無航班資料（期末重構用，做法同 op09）
  PUBLIC SECTION.
    METHODS get_text REDEFINITION.
ENDCLASS.

CLASS zcx_oo12_no_data IMPLEMENTATION.
  METHOD get_text.
    result = |查無資料！請確認 SFLIGHT 有資料（SAPBC_DATA_GENERATOR）|.
  ENDMETHOD.
ENDCLASS.

