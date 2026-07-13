CLASS zcl_rs07_flight DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 7：單筆資源 GET/PUT/DELETE，統一用 ZCX_RS07_FLIGHT_ERROR 轉成一致的 JSON error body
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
    METHODS if_rest_resource~put REDEFINITION.
    METHODS if_rest_resource~delete REDEFINITION.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_keys,
             carrid TYPE s_carr_id,
             connid TYPE s_conn_id,
             fldate TYPE s_date,
           END OF ty_keys,

           BEGIN OF ty_flight,
             carrid   TYPE s_carr_id,
             connid   TYPE s_conn_id,
             fldate   TYPE s_date,
             price    TYPE s_price,
             currency TYPE s_currcode,
           END OF ty_flight.

    METHODS:
      read_keys
        RETURNING VALUE(rs_keys) TYPE ty_keys
        RAISING   zcx_rs07_flight_error,

      read_flight
        IMPORTING is_keys          TYPE ty_keys
        RETURNING VALUE(rs_flight) TYPE ty_flight
        RAISING   zcx_rs07_flight_error,

      render_flight
        IMPORTING is_flight TYPE ty_flight,

      render_error
        IMPORTING ix_error TYPE REF TO zcx_rs07_flight_error,

      wrap_error
        IMPORTING ix_error         TYPE REF TO cx_root
        RETURNING VALUE(rx_result) TYPE REF TO zcx_rs07_flight_error.
ENDCLASS.

CLASS zcl_rs07_flight IMPLEMENTATION.

  METHOD read_keys.
    rs_keys-carrid = mo_request->get_uri_attribute( 'carrid' ).
    rs_keys-connid = mo_request->get_uri_attribute( 'connid' ).

    DATA(lv_fldate_raw) = mo_request->get_uri_attribute( 'fldate' ).

* CONV dats( ... ) 對非數字字串不會拋出例外（DATS 底層是字元型別，不做內容檢查），
* 必須自己驗證字元組成與長度，不能依賴轉型失敗來偵測格式錯誤
    IF strlen( lv_fldate_raw ) <> 8 OR lv_fldate_raw CN '0123456789'.
      RAISE EXCEPTION TYPE zcx_rs07_flight_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'INVALID_DATE'
          iv_message     = |fldate 格式不正確，必須是 8 碼數字（YYYYMMDD）|.
    ENDIF.

    rs_keys-fldate = lv_fldate_raw.
  ENDMETHOD.

  METHOD read_flight.
    SELECT SINGLE carrid, connid, fldate, price, currency
      FROM sflight
      WHERE carrid = @is_keys-carrid
        AND connid = @is_keys-connid
        AND fldate = @is_keys-fldate
      INTO @rs_flight.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_rs07_flight_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_not_found
          iv_error_code  = 'FLIGHT_NOT_FOUND'
          iv_message     = |找不到航班 { is_keys-carrid }/{ is_keys-connid }/{ CONV string( is_keys-fldate ) }|.
    ENDIF.
  ENDMETHOD.

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
    rx_result = NEW zcx_rs07_flight_error(
      iv_status_code = cl_rest_status_code=>gc_server_error_internal
      iv_error_code  = 'INTERNAL_ERROR'
      iv_message     = |系統發生未預期錯誤：{ ix_error->get_text( ) }|
      previous       = ix_error ).
  ENDMETHOD.

  METHOD if_rest_resource~get.
    TRY.
        DATA(ls_keys) = read_keys( ).
        DATA(ls_flight) = read_flight( ls_keys ).
        render_flight( ls_flight ).
      CATCH zcx_rs07_flight_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_rest_resource~put.
    TRY.
        DATA(ls_keys) = read_keys( ).
        read_flight( ls_keys ).

        DATA(lv_body) = io_entity->get_string_data( ).

        TYPES: BEGIN OF ty_update,
                 price    TYPE s_price,
                 currency TYPE s_currcode,
               END OF ty_update.
        DATA ls_update TYPE ty_update.

        /ui2/cl_json=>deserialize(
          EXPORTING
            json        = lv_body
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data        = ls_update ).

        IF ls_update-price IS INITIAL OR ls_update-currency IS INITIAL.
          RAISE EXCEPTION TYPE zcx_rs07_flight_error
            EXPORTING
              iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
              iv_error_code  = 'VALIDATION_FAILED'
              iv_message     = |price 與 currency 都必填|.
        ENDIF.

        UPDATE sflight
          SET price    = ls_update-price
              currency = ls_update-currency
          WHERE carrid = ls_keys-carrid
            AND connid = ls_keys-connid
            AND fldate = ls_keys-fldate.

        DATA(ls_updated) = read_flight( ls_keys ).
        render_flight( ls_updated ).
      CATCH zcx_rs07_flight_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_rest_resource~delete.
    TRY.
        DATA(ls_keys) = read_keys( ).
        read_flight( ls_keys ).

        DELETE FROM sflight
          WHERE carrid = ls_keys-carrid
            AND connid = ls_keys-connid
            AND fldate = ls_keys-fldate.

        mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
      CATCH zcx_rs07_flight_error INTO DATA(lx_error).
        render_error( lx_error ).
      CATCH cx_root INTO DATA(lx_unexpected).
        render_error( wrap_error( lx_unexpected ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
