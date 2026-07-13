CLASS zcl_rs06_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 6：POST 建立資源——關閉 CSRF Token 檢查（僅供本課程 SPROX_HTTP_REQUEST 測試使用，正式瀏覽器 API 不應如此）
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
  PROTECTED SECTION.
    METHODS handle_csrf_token REDEFINITION.
ENDCLASS.

CLASS zcl_rs06_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
    DATA(lo_router) = NEW cl_rest_router( ).
    lo_router->attach(
      iv_template      = '/flights'
      iv_handler_class = 'ZCL_RS06_FLIGHTS' ).
    ro_root_handler = lo_router.
  ENDMETHOD.

  METHOD handle_csrf_token.
* 刻意留空、不呼叫 SUPER->，跳過 CSRF Token 檢查
  ENDMETHOD.
ENDCLASS.
