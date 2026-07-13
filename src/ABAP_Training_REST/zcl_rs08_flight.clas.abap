CLASS zcl_rs08_flight DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 8：Resource 只做「解析 request → 呼叫 Service → 組 response」，
* 商業邏輯全部在 ZCL_RS08_FLIGHT_SERVICE（不依賴任何 REST 框架型別）
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
    METHODS if_rest_resource~put REDEFINITION.
    METHODS if_rest_resource~delete REDEFINITION.

  PRIVATE SECTION.
    METHODS:
      render_flight
        IMPORTING is_flight TYPE zcl_rs08_flight_service=>ty_flight,

      render_error
        IMPORTING ix_error TYPE REF TO zcx_rs08_flight_error,

      wrap_error
        IMPORTING ix_error         TYPE REF TO cx_root
        RETURNING VALUE(rx_result) TYPE REF TO zcx_rs08_flight_error.
ENDCLASS.

CLASS zcl_rs08_flight IMPLEMENTATION.

  METHOD render_flight.
    DATA(lv_json) = /ui2/cl_json=>serialize(
      data        = is_flight
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_string_data( lv_json ).
    lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
  ENDMETHOD.

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
    rx_result = NEW zcx_rs08_flight_error(
      iv_status_code = cl_rest_status_code=>gc_server_error_internal
      iv_error_code  = 'INTERNAL_ERROR'
      iv_message     = |系統發生未預期錯誤：{ ix_error->get_text( ) }|
      previous       = ix_error ).
  ENDMETHOD.

  METHOD if_rest_resource~get.
    TRY.
        DATA(ls_keys) = zcl_rs08_flight_service=>parse_keys(
          iv_carrid = mo_request->get_uri_attribute( 'carrid' )
          iv_connid = mo_request->get_uri_attribute( 'connid' )
          iv_fldate = mo_request->get_uri_attribute( 'fldate' ) ).

        DATA(ls_flight) = zcl_rs08_flight_service=>get_flight( ls_keys ).
        render_flight( ls_flight ).
      CATCH zcx_rs08_flight_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_rest_resource~put.
    TRY.
        DATA(ls_keys) = zcl_rs08_flight_service=>parse_keys(
          iv_carrid = mo_request->get_uri_attribute( 'carrid' )
          iv_connid = mo_request->get_uri_attribute( 'connid' )
          iv_fldate = mo_request->get_uri_attribute( 'fldate' ) ).

        DATA(lv_body) = io_entity->get_string_data( ).

        DATA ls_update TYPE zcl_rs08_flight_service=>ty_update.
        /ui2/cl_json=>deserialize(
          EXPORTING
            json        = lv_body
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data        = ls_update ).

        DATA(ls_flight) = zcl_rs08_flight_service=>update_flight(
          is_keys   = ls_keys
          is_update = ls_update ).

        render_flight( ls_flight ).
      CATCH zcx_rs08_flight_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_rest_resource~delete.
    TRY.
        DATA(ls_keys) = zcl_rs08_flight_service=>parse_keys(
          iv_carrid = mo_request->get_uri_attribute( 'carrid' )
          iv_connid = mo_request->get_uri_attribute( 'connid' )
          iv_fldate = mo_request->get_uri_attribute( 'fldate' ) ).

        zcl_rs08_flight_service=>delete_flight( ls_keys ).

        mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
      CATCH zcx_rs08_flight_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
