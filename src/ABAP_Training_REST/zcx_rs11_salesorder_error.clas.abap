CLASS zcx_rs11_salesorder_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

* REST 練習 11：業務例外（同 rs07~rs10 設計），供 Service 層與 Resource 層共用
  PUBLIC SECTION.
    DATA mv_status_code TYPE i READ-ONLY.
    DATA mv_error_code  TYPE string READ-ONLY.
    DATA mv_message     TYPE string READ-ONLY.

    METHODS:
      constructor IMPORTING iv_status_code TYPE i
                            iv_error_code  TYPE string
                            iv_message     TYPE string
                            previous       LIKE previous OPTIONAL,
      get_text REDEFINITION.
ENDCLASS.

CLASS zcx_rs11_salesorder_error IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_status_code = iv_status_code.
    mv_error_code  = iv_error_code.
    mv_message     = iv_message.
  ENDMETHOD.

  METHOD get_text.
    result = mv_message.
  ENDMETHOD.
ENDCLASS.
