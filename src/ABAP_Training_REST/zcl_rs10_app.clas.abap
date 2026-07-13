CLASS zcl_rs10_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 10：批次建立訂位——關閉 CSRF Token 檢查（比照 rs06~rs09，供 SPROX_HTTP_REQUEST 測試使用）
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
  PROTECTED SECTION.
    METHODS handle_csrf_token REDEFINITION.
ENDCLASS.

CLASS zcl_rs10_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
    DATA(lo_router) = NEW cl_rest_router( ).
    lo_router->attach(
      iv_template      = '/bookings/batch'
      iv_handler_class = 'ZCL_RS10_BATCH' ).
    ro_root_handler = lo_router.
  ENDMETHOD.

  METHOD handle_csrf_token.
* 刻意留空、不呼叫 SUPER->，跳過 CSRF Token 檢查（比照 rs06~rs09）
  ENDMETHOD.
ENDCLASS.
