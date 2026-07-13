CLASS zcl_rs05_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 5：Query Parameter 篩選——/flights?carrid=&connid=&minprice= 皆為可選
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
ENDCLASS.

CLASS zcl_rs05_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
    DATA(lo_router) = NEW cl_rest_router( ).
    lo_router->attach(
      iv_template      = '/flights'
      iv_handler_class = 'ZCL_RS05_FLIGHTS' ).
    ro_root_handler = lo_router.
  ENDMETHOD.
ENDCLASS.
