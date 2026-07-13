CLASS zcl_rs09_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 9（期末整合）：訂位 CRUD——關閉 CSRF Token 檢查（比照 rs06~rs08，供 SPROX_HTTP_REQUEST 測試使用）
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
  PROTECTED SECTION.
    METHODS handle_csrf_token REDEFINITION.
ENDCLASS.

CLASS zcl_rs09_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
    DATA(lo_router) = NEW cl_rest_router( ).
    lo_router->attach(
      iv_template      = '/bookings'
      iv_handler_class = 'ZCL_RS09_BOOKINGS' ).
    lo_router->attach(
      iv_template      = '/bookings/{carrid}/{connid}/{fldate}/{bookid}'
      iv_handler_class = 'ZCL_RS09_BOOKING' ).
    ro_root_handler = lo_router.
  ENDMETHOD.

  METHOD handle_csrf_token.
* 刻意留空、不呼叫 SUPER->，跳過 CSRF Token 檢查（比照 rs06~rs08）
  ENDMETHOD.
ENDCLASS.
