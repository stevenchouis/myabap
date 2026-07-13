CLASS zcx_rs10_batch_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

* REST 練習 10：請求層級的例外（例如陣列是空的）——單筆結果的成功/失敗不用例外，
* 放在回應陣列的每一筆結果裡（見 ZCL_RS10_BOOKING_BATCH_SERVICE=>ty_result）
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

CLASS zcx_rs10_batch_error IMPLEMENTATION.
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
