CLASS zcl_rs09_booking DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 9（期末整合）：單筆訂位——GET/PUT/DELETE，薄層轉接（同 rs08 分層原則）
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
    METHODS if_rest_resource~put REDEFINITION.
    METHODS if_rest_resource~delete REDEFINITION.

  PRIVATE SECTION.
    METHODS:
      parse_request_keys
        RETURNING VALUE(rs_keys) TYPE zcl_rs09_booking_service=>ty_keys
        RAISING   zcx_rs09_booking_error,

      render_booking
        IMPORTING is_booking TYPE zcl_rs09_booking_service=>ty_booking,

      render_error
        IMPORTING ix_error TYPE REF TO zcx_rs09_booking_error,

      wrap_error
        IMPORTING ix_error         TYPE REF TO cx_root
        RETURNING VALUE(rx_result) TYPE REF TO zcx_rs09_booking_error.
ENDCLASS.

CLASS zcl_rs09_booking IMPLEMENTATION.

  METHOD parse_request_keys.
    rs_keys = zcl_rs09_booking_service=>parse_keys(
      iv_carrid = mo_request->get_uri_attribute( 'carrid' )
      iv_connid = mo_request->get_uri_attribute( 'connid' )
      iv_fldate = mo_request->get_uri_attribute( 'fldate' )
      iv_bookid = mo_request->get_uri_attribute( 'bookid' ) ).
  ENDMETHOD.

  METHOD render_booking.
    DATA(lv_json) = /ui2/cl_json=>serialize(
      data        = is_booking
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
    rx_result = NEW zcx_rs09_booking_error(
      iv_status_code = cl_rest_status_code=>gc_server_error_internal
      iv_error_code  = 'INTERNAL_ERROR'
      iv_message     = |系統發生未預期錯誤：{ ix_error->get_text( ) }|
      previous       = ix_error ).
  ENDMETHOD.

  METHOD if_rest_resource~get.
    TRY.
        DATA(ls_keys) = parse_request_keys( ).
        DATA(ls_booking) = zcl_rs09_booking_service=>get_booking( ls_keys ).
        render_booking( ls_booking ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_rest_resource~put.
    TRY.
        DATA(ls_keys) = parse_request_keys( ).

        DATA(lv_body) = io_entity->get_string_data( ).

        DATA ls_update TYPE zcl_rs09_booking_service=>ty_update.
        /ui2/cl_json=>deserialize(
          EXPORTING
            json        = lv_body
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data        = ls_update ).

        DATA(ls_booking) = zcl_rs09_booking_service=>update_booking(
          is_keys   = ls_keys
          is_update = ls_update ).

        render_booking( ls_booking ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_rest_resource~delete.
    TRY.
        DATA(ls_keys) = parse_request_keys( ).

        zcl_rs09_booking_service=>delete_booking( ls_keys ).

        mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
