CLASS zcl_rs10_booking_batch_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* REST 練習 10：JSON Array 反序列化為 Internal Table 後，LOOP 呼叫標準 BAPI
* BAPI_FLBOOKING_CREATEFROMDATA 批次建立訂位；每一筆獨立成功/失敗，不是全有全無
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_request,
             carrid   TYPE s_carr_id,
             connid   TYPE s_conn_id,
             fldate   TYPE s_date,
             customid TYPE s_customer,
             class    TYPE s_class,
             passname TYPE s_passname,
           END OF ty_request,

           tt_request TYPE STANDARD TABLE OF ty_request WITH EMPTY KEY,

           BEGIN OF ty_result,
             index   TYPE i,
             success TYPE abap_bool,
             carrid  TYPE s_carr_id,
             connid  TYPE s_conn_id,
             fldate  TYPE s_date,
             bookid  TYPE s_book_id,
             message TYPE string,
           END OF ty_result,

           tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    CLASS-METHODS:
* 純邏輯，不碰資料庫——ABAP Unit 覆蓋
      validate_requests
        IMPORTING it_requests TYPE tt_request
        RAISING   zcx_rs10_batch_error,

* 會呼叫 BAPI／碰資料庫，依課程慣例不寫 ABAP Unit test
      create_bookings
        IMPORTING it_requests      TYPE tt_request
        RETURNING VALUE(rt_result) TYPE tt_result.
ENDCLASS.

CLASS zcl_rs10_booking_batch_service IMPLEMENTATION.

  METHOD validate_requests.
    IF it_requests IS INITIAL.
      RAISE EXCEPTION TYPE zcx_rs10_batch_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'VALIDATION_FAILED'
          iv_message     = |至少要有一筆訂位資料|.
    ENDIF.
  ENDMETHOD.

  METHOD create_bookings.
    DATA ls_booking_data TYPE bapisbonew.
    DATA lv_airlineid    TYPE bapisbokey-airlineid.
    DATA lv_bookingid    TYPE bapisbokey-bookingid.
    DATA ls_price        TYPE bapisbopri.
    DATA lt_return       TYPE STANDARD TABLE OF bapiret2.

    LOOP AT it_requests INTO DATA(ls_request).
      DATA(lv_index) = sy-tabix - 1."跟輸入陣列的索引對齊（0-based）

      CLEAR: ls_booking_data, lv_airlineid, lv_bookingid, ls_price, lt_return.

      ls_booking_data-airlineid  = ls_request-carrid.
      ls_booking_data-connectid  = ls_request-connid.
      ls_booking_data-flightdate = ls_request-fldate.
      ls_booking_data-customerid = ls_request-customid.
      ls_booking_data-class      = ls_request-class.
      ls_booking_data-passname   = ls_request-passname.

      CALL FUNCTION 'BAPI_FLBOOKING_CREATEFROMDATA'
        EXPORTING
          booking_data  = ls_booking_data
        IMPORTING
          airlineid     = lv_airlineid
          bookingnumber = lv_bookingid
          ticket_price  = ls_price
        TABLES
          return        = lt_return.

      DATA(lv_error_message) = ``.
      LOOP AT lt_return INTO DATA(ls_msg) WHERE type = 'E' OR type = 'A'.
        lv_error_message = ls_msg-message.
        EXIT.
      ENDLOOP.

      IF lv_error_message IS NOT INITIAL.
        APPEND VALUE #( index   = lv_index
                        success = abap_false
                        carrid  = ls_request-carrid
                        connid  = ls_request-connid
                        fldate  = ls_request-fldate
                        message = lv_error_message ) TO rt_result.
      ELSE.
        APPEND VALUE #( index   = lv_index
                        success = abap_true
                        carrid  = ls_request-carrid
                        connid  = ls_request-connid
                        fldate  = ls_request-fldate
                        bookid  = lv_bookingid
                        message = |訂位建立成功| ) TO rt_result.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

ENDCLASS.
