CLASS zcl_rs03_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 3：JSON 序列化與集合查詢——router 掛一個 /flights 資源
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
ENDCLASS.

CLASS zcl_rs03_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
    DATA(lo_router) = NEW cl_rest_router( ).
    lo_router->attach(
      iv_template      = '/flights'
      iv_handler_class = 'ZCL_RS03_FLIGHTS' ).
    ro_root_handler = lo_router.
  ENDMETHOD.
ENDCLASS.
