CLASS zcl_rs08_flight_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* REST 練習 8：純 ABAP 商業邏輯層，完全不依賴 REST 框架型別（IF_REST_*），
* 可以直接被 ABAP Unit 呼叫測試，不需要假造 HTTP request/response
  PUBLIC SECTION.
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
           END OF ty_flight,

           BEGIN OF ty_update,
             price    TYPE s_price,
             currency TYPE s_currcode,
           END OF ty_update.

    CLASS-METHODS:
      parse_keys
        IMPORTING iv_carrid        TYPE string
                  iv_connid        TYPE string
                  iv_fldate        TYPE string
        RETURNING VALUE(rs_keys)   TYPE ty_keys
        RAISING   zcx_rs08_flight_error,

      validate_update
        IMPORTING is_update TYPE ty_update
        RAISING   zcx_rs08_flight_error,

      get_flight
        IMPORTING is_keys          TYPE ty_keys
        RETURNING VALUE(rs_flight) TYPE ty_flight
        RAISING   zcx_rs08_flight_error,

      update_flight
        IMPORTING is_keys          TYPE ty_keys
                  is_update        TYPE ty_update
        RETURNING VALUE(rs_flight) TYPE ty_flight
        RAISING   zcx_rs08_flight_error,

      delete_flight
        IMPORTING is_keys TYPE ty_keys
        RAISING   zcx_rs08_flight_error.
ENDCLASS.

CLASS zcl_rs08_flight_service IMPLEMENTATION.

  METHOD parse_keys.
* 純邏輯驗證，不碰資料庫：這裡就是 rs07 那個「CONV dats(...) 對非數字字串不會拋例外」的
* 修正版做法搬過來，現在可以直接寫 ABAP Unit 測試覆蓋這個案例
    IF strlen( iv_fldate ) <> 8 OR iv_fldate CN '0123456789'.
      RAISE EXCEPTION TYPE zcx_rs08_flight_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'INVALID_DATE'
          iv_message     = |fldate 格式不正確，必須是 8 碼數字（YYYYMMDD）|.
    ENDIF.

    rs_keys-carrid = iv_carrid.
    rs_keys-connid = iv_connid.
    rs_keys-fldate = iv_fldate.
  ENDMETHOD.

  METHOD validate_update.
* 純邏輯驗證，不碰資料庫
    IF is_update-price IS INITIAL OR is_update-currency IS INITIAL.
      RAISE EXCEPTION TYPE zcx_rs08_flight_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'VALIDATION_FAILED'
          iv_message     = |price 與 currency 都必填|.
    ENDIF.
  ENDMETHOD.

  METHOD get_flight.
* 會碰資料庫，依課程慣例（同 op10/op12）不寫 ABAP Unit test，保持這個方法「薄」
    SELECT SINGLE carrid, connid, fldate, price, currency
      FROM sflight
      WHERE carrid = @is_keys-carrid
        AND connid = @is_keys-connid
        AND fldate = @is_keys-fldate
      INTO @rs_flight.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_rs08_flight_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_not_found
          iv_error_code  = 'FLIGHT_NOT_FOUND'
          iv_message     = |找不到航班 { is_keys-carrid }/{ is_keys-connid }/{ CONV string( is_keys-fldate ) }|.
    ENDIF.
  ENDMETHOD.

  METHOD update_flight.
    get_flight( is_keys )."確認資源存在，查無資料會直接拋出 404
    validate_update( is_update ).

    UPDATE sflight
      SET price    = is_update-price
          currency = is_update-currency
      WHERE carrid = is_keys-carrid
        AND connid = is_keys-connid
        AND fldate = is_keys-fldate.

    rs_flight = get_flight( is_keys ).
  ENDMETHOD.

  METHOD delete_flight.
    get_flight( is_keys ).

    DELETE FROM sflight
      WHERE carrid = is_keys-carrid
        AND connid = is_keys-connid
        AND fldate = is_keys-fldate.
  ENDMETHOD.

ENDCLASS.
