CLASS zcl_rs09_bookings DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 9（期末整合）：訂位集合——GET 列表（carrid/customid 篩選）、POST 建立
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
    METHODS if_rest_resource~post REDEFINITION.

  PRIVATE SECTION.
    METHODS:
      render_booking
        IMPORTING is_booking TYPE zcl_rs09_booking_service=>ty_booking,

      render_error
        IMPORTING ix_error TYPE REF TO zcx_rs09_booking_error,

      wrap_error
        IMPORTING ix_error         TYPE REF TO cx_root
        RETURNING VALUE(rx_result) TYPE REF TO zcx_rs09_booking_error.
ENDCLASS.

CLASS zcl_rs09_bookings IMPLEMENTATION.

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
        DATA(lv_has_carrid)   = mo_request->has_uri_query_parameter( 'carrid' ).
        DATA(lv_has_customid) = mo_request->has_uri_query_parameter( 'customid' ).

        DATA(lv_carrid) = COND s_carr_id( WHEN lv_has_carrid = abap_true
                                            THEN mo_request->get_uri_query_parameter( 'carrid' )
                                            ELSE `` ).
        DATA(lv_customid) = COND s_customer( WHEN lv_has_customid = abap_true
                                               THEN mo_request->get_uri_query_parameter( 'customid' )
                                               ELSE `` ).

        DATA(lt_booking) = zcl_rs09_booking_service=>list_bookings(
          iv_carrid       = lv_carrid
          iv_has_carrid   = lv_has_carrid
          iv_customid     = lv_customid
          iv_has_customid = lv_has_customid ).

        DATA(lv_json) = /ui2/cl_json=>serialize(
          data        = lt_booking
          pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

        DATA(lo_entity) = mo_response->create_entity( ).
        lo_entity->set_string_data( lv_json ).
        lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_rest_resource~post.
    TRY.
        DATA(lv_body) = io_entity->get_string_data( ).

        DATA ls_create TYPE zcl_rs09_booking_service=>ty_create.
        /ui2/cl_json=>deserialize(
          EXPORTING
            json        = lv_body
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data        = ls_create ).

        DATA(ls_booking) = zcl_rs09_booking_service=>create_booking( ls_create ).

        DATA(lv_location) = |/bookings/{ ls_booking-carrid }/{ ls_booking-connid }/{ CONV string( ls_booking-fldate ) }/{ ls_booking-bookid }|.

        mo_response->set_header_field(
          iv_name  = 'Location'
          iv_value = lv_location ).
        mo_response->set_status( cl_rest_status_code=>gc_success_created ).

        render_booking( ls_booking ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
