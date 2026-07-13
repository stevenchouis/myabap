CLASS zcl_rs06_flights DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 6：POST 建立資源——讀取 Request Body、JSON 反序列化、寫入 SFLIGHT、201 Created + Location Header
  PUBLIC SECTION.
    METHODS if_rest_resource~post REDEFINITION.
ENDCLASS.

CLASS zcl_rs06_flights IMPLEMENTATION.
  METHOD if_rest_resource~post.
    TYPES: BEGIN OF ty_flight,
             carrid   TYPE s_carr_id,
             connid   TYPE s_conn_id,
             fldate   TYPE s_date,
             price    TYPE s_price,
             currency TYPE s_currcode,
           END OF ty_flight.

    DATA(lv_body) = io_entity->get_string_data( ).

    DATA ls_flight TYPE ty_flight.
    /ui2/cl_json=>deserialize(
      EXPORTING
        json        = lv_body
        pretty_name = /ui2/cl_json=>pretty_mode-camel_case
      CHANGING
        data        = ls_flight ).

    IF ls_flight-carrid IS INITIAL OR ls_flight-connid IS INITIAL OR ls_flight-fldate IS INITIAL.
      RAISE EXCEPTION TYPE cx_rest_resource_exception
        EXPORTING
          status_code    = cl_rest_status_code=>gc_client_error_bad_request
          request_method = if_rest_message=>gc_method_post.
    ENDIF.

    SELECT SINGLE carrid
      FROM scarr
      WHERE carrid = @ls_flight-carrid
      INTO @DATA(lv_carrid_check).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_rest_resource_exception
        EXPORTING
          status_code    = cl_rest_status_code=>gc_client_error_bad_request
          request_method = if_rest_message=>gc_method_post.
    ENDIF.

    DATA ls_sflight TYPE sflight.
    ls_sflight = CORRESPONDING #( ls_flight ).

    INSERT sflight FROM ls_sflight.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_rest_resource_exception
        EXPORTING
          status_code    = cl_rest_status_code=>gc_client_error_conflict
          request_method = if_rest_message=>gc_method_post.
    ENDIF.

    DATA(lv_fldate_str) = CONV string( ls_flight-fldate ).
    DATA(lv_location) = '/flights/' && ls_flight-carrid && '/' && ls_flight-connid && '/' && lv_fldate_str.

    mo_response->set_header_field(
      iv_name  = 'Location'
      iv_value = lv_location ).
    mo_response->set_status( cl_rest_status_code=>gc_success_created ).

    DATA(lv_json) = /ui2/cl_json=>serialize(
      data        = ls_flight
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    DATA(lo_resp_entity) = mo_response->create_entity( ).
    lo_resp_entity->set_string_data( lv_json ).
    lo_resp_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
  ENDMETHOD.
ENDCLASS.
