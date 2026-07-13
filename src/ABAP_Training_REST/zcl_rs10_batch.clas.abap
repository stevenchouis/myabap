CLASS zcl_rs10_batch DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 10：批次建立訂位——POST 收一個 JSON Array，
* /UI2/CL_JSON 反序列化直接進 Internal Table，逐筆呼叫 BAPI，回傳逐筆結果陣列
  PUBLIC SECTION.
    METHODS if_rest_resource~post REDEFINITION.

  PRIVATE SECTION.
    METHODS:
      render_error
        IMPORTING ix_error TYPE REF TO zcx_rs10_batch_error,

      wrap_error
        IMPORTING ix_error         TYPE REF TO cx_root
        RETURNING VALUE(rx_result) TYPE REF TO zcx_rs10_batch_error.
ENDCLASS.

CLASS zcl_rs10_batch IMPLEMENTATION.

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
    rx_result = NEW zcx_rs10_batch_error(
      iv_status_code = cl_rest_status_code=>gc_server_error_internal
      iv_error_code  = 'INTERNAL_ERROR'
      iv_message     = |系統發生未預期錯誤：{ ix_error->get_text( ) }|
      previous       = ix_error ).
  ENDMETHOD.

  METHOD if_rest_resource~post.
    TRY.
        DATA(lv_body) = io_entity->get_string_data( ).

        DATA lt_requests TYPE zcl_rs10_booking_batch_service=>tt_request.
        /ui2/cl_json=>deserialize(
          EXPORTING
            json        = lv_body
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data        = lt_requests ).

        zcl_rs10_booking_batch_service=>validate_requests( lt_requests ).

        DATA(lt_result) = zcl_rs10_booking_batch_service=>create_bookings( lt_requests ).

        DATA(lv_json) = /ui2/cl_json=>serialize(
          data        = lt_result
          pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

        mo_response->set_status( cl_rest_status_code=>gc_success_ok ).

        DATA(lo_entity) = mo_response->create_entity( ).
        lo_entity->set_string_data( lv_json ).
        lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
      CATCH zcx_rs10_batch_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
