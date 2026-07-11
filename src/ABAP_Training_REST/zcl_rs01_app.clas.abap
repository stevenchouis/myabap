CLASS zcl_rs01_app DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_http_handler.

* REST 練習 1：Application Class——SICF Service 掛的就是這個類別
*   繼承 CL_REST_HTTP_HANDLER 就自動有 IF_HTTP_EXTENSION~HANDLE_REQUEST
*   （CSRF 檢查、建立 request/response 物件、例外轉 HTTP 狀態碼都內建好了），
*   子類別只需要覆寫 GET_ROOT_HANDLER，決定「誰來處理這個 request」
  PUBLIC SECTION.
    METHODS if_rest_application~get_root_handler REDEFINITION.
ENDCLASS.

CLASS zcl_rs01_app IMPLEMENTATION.
  METHOD if_rest_application~get_root_handler.
*   整個 service 目前只有一個資源，直接回傳它的實例即可，
*   還不需要 CL_REST_ROUTER 做路由（多資源路由留到 rs02）
    ro_root_handler = NEW zcl_rs01_hello( ).
  ENDMETHOD.
ENDCLASS.
