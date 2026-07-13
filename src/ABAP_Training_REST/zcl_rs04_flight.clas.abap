CLASS zcl_rs04_flight DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 4：單筆查詢——URI 路徑參數 /flights/{carrid}/{connid}/{fldate}
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
ENDCLASS.

CLASS zcl_rs04_flight IMPLEMENTATION.
  METHOD if_rest_resource~get.
    DATA(lv_carrid) = mo_request->get_uri_attribute( 'carrid' ).
    DATA(lv_connid) = mo_request->get_uri_attribute( 'connid' ).
    DATA(lv_fldate) = CONV dats( mo_request->get_uri_attribute( 'fldate' ) ).

    SELECT SINGLE carrid, connid, fldate, price, currency
      FROM sflight
      WHERE carrid = @lv_carrid
        AND connid = @lv_connid
        AND fldate = @lv_fldate
      INTO @DATA(ls_flight).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_rest_resource_exception
        EXPORTING
          status_code    = cl_rest_status_code=>gc_client_error_not_found
          request_method = if_rest_message=>gc_method_get
          textid         = cx_rest_resource_exception=>resource_not_found.
    ENDIF.

    DATA(lv_json) = /ui2/cl_json=>serialize(
      data        = ls_flight
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_string_data( lv_json ).
    lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
  ENDMETHOD.
ENDCLASS.
