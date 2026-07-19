CLASS zcl_rs11_salesorders DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 11：銷售訂單集合——只有 POST（Header+Item 一次建立），沒有對應的 GET 單筆資源
* （這題的教學重點是「巢狀 JSON → 一次 BAPI 呼叫」，刻意不做完整 CRUD，跟 rs09/rs10 的批次資源一樣只聚焦單一動詞）
  PUBLIC SECTION.
    METHODS if_rest_resource~post REDEFINITION.

  PRIVATE SECTION.
    METHODS:
      render_error
        IMPORTING ix_error TYPE REF TO zcx_rs11_salesorder_error,

      wrap_error
        IMPORTING ix_error         TYPE REF TO cx_root
        RETURNING VALUE(rx_result) TYPE REF TO zcx_rs11_salesorder_error.
ENDCLASS.

CLASS zcl_rs11_salesorders IMPLEMENTATION.

  METHOD render_error.
    TYPES: BEGIN OF ty_error_body,
             error_code TYPE string,
             message    TYPE string,
           END OF ty_error_body.

    DATA(ls_error_body) = VALUE ty_error_body(
      error_code = ix_error->mv_error_code
      message    = ix_error->mv_message ).

    DATA(lv_json) = /ui2/cl_json=>serialize(
      data        = ls_error_body
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    mo_response->set_status( ix_error->mv_status_code ).

    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_string_data( lv_json ).
    lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
  ENDMETHOD.

  METHOD wrap_error.
    rx_result = NEW zcx_rs11_salesorder_error(
      iv_status_code = cl_rest_status_code=>gc_server_error_internal
      iv_error_code  = 'INTERNAL_ERROR'
      iv_message     = |系統發生未預期錯誤：{ ix_error->get_text( ) }|
      previous       = ix_error ).
  ENDMETHOD.

  METHOD if_rest_resource~post.
    TRY.
        DATA(lv_body) = io_entity->get_string_data( ).

        DATA ls_request TYPE zcl_rs11_salesorder_service=>ty_create_request.
        /ui2/cl_json=>deserialize(
          EXPORTING
            json        = lv_body
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data        = ls_request ).

        zcl_rs11_salesorder_service=>validate_request( ls_request ).

* ?testrun=true 讓學生／使用者可以先預覽 BAPI 是否接受這筆資料，不會真的建立訂單
* （官方文件建議新手用小規模 testrun 驗證欄位對應，這裡直接把它做成 API 的一部分）
        DATA(lv_testrun) = COND abap_bool(
          WHEN mo_request->has_uri_query_parameter( 'testrun' ) = abap_true AND
               mo_request->get_uri_query_parameter( 'testrun' ) = 'true'
          THEN abap_true ELSE abap_false ).

        DATA(ls_result) = zcl_rs11_salesorder_service=>create_sales_order(
          is_request = ls_request
          iv_testrun = lv_testrun ).

        DATA(lv_json) = /ui2/cl_json=>serialize(
          data        = ls_result
          pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

        mo_response->set_status(
          COND #( WHEN lv_testrun = abap_true THEN cl_rest_status_code=>gc_success_ok
                  ELSE cl_rest_status_code=>gc_success_created ) ).

        DATA(lo_entity) = mo_response->create_entity( ).
        lo_entity->set_string_data( lv_json ).
        lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
      CATCH zcx_rs11_salesorder_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
