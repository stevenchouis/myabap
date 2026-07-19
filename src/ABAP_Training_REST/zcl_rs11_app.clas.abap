CLASS zcl_rs11_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 11：Header/Item 單一 BAPI 呼叫（銷售訂單）——關閉 CSRF Token 檢查（比照 rs06~rs10，供 SPROX_HTTP_REQUEST/Postman 測試使用）
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
  PROTECTED SECTION.
    METHODS handle_csrf_token REDEFINITION.
ENDCLASS.

CLASS zcl_rs11_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
    DATA(lo_router) = NEW cl_rest_router( ).
    lo_router->attach(
      iv_template      = '/salesorders'
      iv_handler_class = 'ZCL_RS11_SALESORDERS' ).
    ro_root_handler = lo_router.
  ENDMETHOD.

  METHOD handle_csrf_token.
* 刻意留空、不呼叫 SUPER->，跳過 CSRF Token 檢查（比照 rs06~rs10）
  ENDMETHOD.
ENDCLASS.
