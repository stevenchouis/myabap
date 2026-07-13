CLASS zcl_rs04_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 4：URI 路徑參數與單筆查詢——集合用 /flights，單筆用完整鍵值 /flights/{carrid}/{connid}/{fldate}
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
ENDCLASS.

CLASS zcl_rs04_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
    DATA(lo_router) = NEW cl_rest_router( ).
    lo_router->attach(
      iv_template      = '/flights'
      iv_handler_class = 'ZCL_RS04_FLIGHTS' ).
    lo_router->attach(
      iv_template      = '/flights/{carrid}/{connid}/{fldate}'
      iv_handler_class = 'ZCL_RS04_FLIGHT' ).
    ro_root_handler = lo_router.
  ENDMETHOD.
ENDCLASS.
