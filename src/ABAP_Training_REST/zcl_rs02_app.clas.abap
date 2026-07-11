CLASS zcl_rs02_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 2：一個 Service、多個資源——這次改用 CL_REST_ROUTER 分流
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
ENDCLASS.

CLASS zcl_rs02_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
    DATA(lo_router) = NEW cl_rest_router( ).

*   URI Pattern -> Resource Class 對照表；ATTACH 第二個參數只是類別
*   名稱字串，router 收到請求時才動態 CREATE OBJECT，資源類別彼此互不知情
    lo_router->attach(
      iv_template      = '/hello'
      iv_handler_class = 'ZCL_RS02_HELLO' ).
    lo_router->attach(
      iv_template      = '/carriers'
      iv_handler_class = 'ZCL_RS02_CARRIERS' ).

    ro_root_handler = lo_router.
  ENDMETHOD.
ENDCLASS.
