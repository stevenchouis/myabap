CLASS zcl_rs09_booking_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* REST 練習 9（期末整合）：純 ABAP 商業邏輯層（同 rs08 分層原則），
* 不依賴任何 REST 框架型別，Resource 只負責解析 request / 組 response
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_keys,
             carrid TYPE s_carr_id,
             connid TYPE s_conn_id,
             fldate TYPE s_date,
             bookid TYPE s_book_id,
           END OF ty_keys,

           BEGIN OF ty_booking,
             carrid    TYPE s_carr_id,
             connid    TYPE s_conn_id,
             fldate    TYPE s_date,
             bookid    TYPE s_book_id,
             customid  TYPE s_customer,
             class     TYPE s_class,
             passname  TYPE s_passname,
             forcuram  TYPE s_f_cur_pr,
             forcurkey TYPE s_curr,
           END OF ty_booking,

           tt_booking TYPE STANDARD TABLE OF ty_booking WITH EMPTY KEY,

           BEGIN OF ty_create,
             carrid    TYPE s_carr_id,
             connid    TYPE s_conn_id,
             fldate    TYPE s_date,
             customid  TYPE s_customer,
             class     TYPE s_class,
             passname  TYPE s_passname,
             forcuram  TYPE s_f_cur_pr,
             forcurkey TYPE s_curr,
           END OF ty_create,

           BEGIN OF ty_update,
             customid  TYPE s_customer,
             class     TYPE s_class,
             passname  TYPE s_passname,
             forcuram  TYPE s_f_cur_pr,
             forcurkey TYPE s_curr,
           END OF ty_update.

    CLASS-METHODS:
* 純邏輯，不碰資料庫——ABAP Unit 全部覆蓋
      parse_keys
        IMPORTING iv_carrid      TYPE string
                  iv_connid      TYPE string
                  iv_fldate      TYPE string
                  iv_bookid      TYPE string
        RETURNING VALUE(rs_keys) TYPE ty_keys
        RAISING   zcx_rs09_booking_error,

      validate_booking_fields
        IMPORTING iv_customid TYPE s_customer
                  iv_class    TYPE s_class
                  iv_passname TYPE s_passname
        RAISING   zcx_rs09_booking_error,

* 會碰資料庫，依課程慣例（op10/op12/rs08）不寫 ABAP Unit test，保持「薄」
      check_flight_exists
        IMPORTING iv_carrid TYPE s_carr_id
                  iv_connid TYPE s_conn_id
                  iv_fldate TYPE s_date
        RAISING   zcx_rs09_booking_error,

      check_customer_exists
        IMPORTING iv_customid TYPE s_customer
        RAISING   zcx_rs09_booking_error,

      get_booking
        IMPORTING is_keys          TYPE ty_keys
        RETURNING VALUE(rs_booking) TYPE ty_booking
        RAISING   zcx_rs09_booking_error,

      list_bookings
        IMPORTING iv_carrid       TYPE s_carr_id OPTIONAL
                  iv_has_carrid   TYPE abap_bool
                  iv_customid     TYPE s_customer OPTIONAL
                  iv_has_customid TYPE abap_bool
        RETURNING VALUE(rt_booking) TYPE tt_booking,

      create_booking
        IMPORTING is_create        TYPE ty_create
        RETURNING VALUE(rs_booking) TYPE ty_booking
        RAISING   zcx_rs09_booking_error,

      update_booking
        IMPORTING is_keys          TYPE ty_keys
                  is_update        TYPE ty_update
        RETURNING VALUE(rs_booking) TYPE ty_booking
        RAISING   zcx_rs09_booking_error,

      delete_booking
        IMPORTING is_keys TYPE ty_keys
        RAISING   zcx_rs09_booking_error.
ENDCLASS.

CLASS zcl_rs09_booking_service IMPLEMENTATION.

  METHOD parse_keys.
* 同 rs07/rs08 修正過的做法：CONV dats( ... ) 對非數字字串不會拋例外，
* 必須自己驗證字元組成與長度
    IF strlen( iv_fldate ) <> 8 OR iv_fldate CN '0123456789'.
      RAISE EXCEPTION TYPE zcx_rs09_booking_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'INVALID_DATE'
          iv_message     = |fldate 格式不正確，必須是 8 碼數字（YYYYMMDD）|.
    ENDIF.

    rs_keys-carrid = iv_carrid.
    rs_keys-connid = iv_connid.
    rs_keys-fldate = iv_fldate.
    rs_keys-bookid = iv_bookid.
  ENDMETHOD.

  METHOD validate_booking_fields.
    IF iv_customid IS INITIAL OR iv_class IS INITIAL OR iv_passname IS INITIAL.
      RAISE EXCEPTION TYPE zcx_rs09_booking_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'VALIDATION_FAILED'
          iv_message     = |customid、class、passname 都必填|.
    ENDIF.

    IF iv_class <> 'F' AND iv_class <> 'C' AND iv_class <> 'Y'.
      RAISE EXCEPTION TYPE zcx_rs09_booking_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'INVALID_CLASS'
          iv_message     = |class 必須是 F（頭等艙）、C（商務艙）或 Y（經濟艙）之一|.
    ENDIF.
  ENDMETHOD.

  METHOD check_flight_exists.
    SELECT SINGLE carrid
      FROM sflight
      WHERE carrid = @iv_carrid
        AND connid = @iv_connid
        AND fldate = @iv_fldate
      INTO @DATA(lv_check).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_rs09_booking_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'INVALID_FLIGHT'
          iv_message     = |找不到航班 { iv_carrid }/{ iv_connid }/{ CONV string( iv_fldate ) }，無法建立訂位|.
    ENDIF.
  ENDMETHOD.

  METHOD check_customer_exists.
    SELECT SINGLE id
      FROM scustom
      WHERE id = @iv_customid
      INTO @DATA(lv_check).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_rs09_booking_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'INVALID_CUSTOMER'
          iv_message     = |找不到客戶 { iv_customid }，無法建立訂位|.
    ENDIF.
  ENDMETHOD.

  METHOD get_booking.
    SELECT SINGLE carrid, connid, fldate, bookid, customid, class, passname, forcuram, forcurkey
      FROM sbook
      WHERE carrid = @is_keys-carrid
        AND connid = @is_keys-connid
        AND fldate = @is_keys-fldate
        AND bookid = @is_keys-bookid
      INTO @rs_booking.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_rs09_booking_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_not_found
          iv_error_code  = 'BOOKING_NOT_FOUND'
          iv_message     = |找不到訂位 { is_keys-carrid }/{ is_keys-connid }/{ CONV string( is_keys-fldate ) }/{ is_keys-bookid }|.
    ENDIF.
  ENDMETHOD.

  METHOD list_bookings.
    SELECT carrid, connid, fldate, bookid, customid, class, passname, forcuram, forcurkey
      FROM sbook
      WHERE ( carrid   = @iv_carrid   OR @iv_has_carrid   = @abap_false )
        AND ( customid = @iv_customid OR @iv_has_customid = @abap_false )
      ORDER BY carrid, connid, fldate, bookid
      INTO TABLE @rt_booking
      UP TO 50 ROWS.
  ENDMETHOD.

  METHOD create_booking.
    check_flight_exists(
      iv_carrid = is_create-carrid
      iv_connid = is_create-connid
      iv_fldate = is_create-fldate ).

    check_customer_exists( is_create-customid ).

    validate_booking_fields(
      iv_customid = is_create-customid
      iv_class    = is_create-class
      iv_passname = is_create-passname ).

    SELECT MAX( bookid )
      FROM sbook
      WHERE carrid = @is_create-carrid
        AND connid = @is_create-connid
        AND fldate = @is_create-fldate
      INTO @DATA(lv_max_bookid).

    DATA(lv_next_bookid) = lv_max_bookid + 1.

    DATA ls_sbook TYPE sbook.
    ls_sbook-carrid     = is_create-carrid.
    ls_sbook-connid     = is_create-connid.
    ls_sbook-fldate     = is_create-fldate.
    ls_sbook-bookid     = lv_next_bookid.
    ls_sbook-customid   = is_create-customid.
    ls_sbook-class      = is_create-class.
    ls_sbook-passname   = is_create-passname.
    ls_sbook-forcuram   = is_create-forcuram.
    ls_sbook-forcurkey  = is_create-forcurkey.
    ls_sbook-order_date = sy-datum.

    INSERT sbook FROM ls_sbook.

    rs_booking = get_booking(
      VALUE ty_keys(
        carrid = is_create-carrid
        connid = is_create-connid
        fldate = is_create-fldate
        bookid = lv_next_bookid ) ).
  ENDMETHOD.

  METHOD update_booking.
    get_booking( is_keys )."確認訂位存在，查無資料會直接拋出 404

    check_customer_exists( is_update-customid ).

    validate_booking_fields(
      iv_customid = is_update-customid
      iv_class    = is_update-class
      iv_passname = is_update-passname ).

    UPDATE sbook
      SET customid  = is_update-customid
          class     = is_update-class
          passname  = is_update-passname
          forcuram  = is_update-forcuram
          forcurkey = is_update-forcurkey
      WHERE carrid = is_keys-carrid
        AND connid = is_keys-connid
        AND fldate = is_keys-fldate
        AND bookid = is_keys-bookid.

    rs_booking = get_booking( is_keys ).
  ENDMETHOD.

  METHOD delete_booking.
    get_booking( is_keys ).

    DELETE FROM sbook
      WHERE carrid = is_keys-carrid
        AND connid = is_keys-connid
        AND fldate = is_keys-fldate
        AND bookid = is_keys-bookid.
  ENDMETHOD.

ENDCLASS.
