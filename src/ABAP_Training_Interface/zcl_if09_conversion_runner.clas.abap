CLASS zcl_if09_conversion_runner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_item,
        item_type TYPE string,
        carrid    TYPE s_carr_id,
        connid    TYPE s_conn_id,
        fldate    TYPE s_date,
        customid  TYPE s_customer,
        class     TYPE s_class,
        passname  TYPE s_passname,
        counter   TYPE s_countnum,
      END OF ty_item,
      tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,

      BEGIN OF ty_result,
        index   TYPE i,
        route   TYPE string,
        success TYPE abap_bool,
        message TYPE string,
      END OF ty_result,
      tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    CLASS-METHODS:
* 純邏輯：依項目型態決定走哪條路徑（BAPI 或 BDC），附 ABAP Unit 測試
      route_item
        IMPORTING
          iv_item_type      TYPE string
        RETURNING VALUE(rv_route) TYPE string,

* 會呼叫 BAPI／碰資料庫，依課程慣例不寫 ABAP Unit
      run_conversion
        IMPORTING
          it_items          TYPE tt_item
        RETURNING VALUE(rt_result) TYPE tt_result.

ENDCLASS.


CLASS zcl_if09_conversion_runner IMPLEMENTATION.

  METHOD route_item.
* 有標準 BAPI 可用的項目型態走 BAPI；其餘一律退回 if05 教過的 BDC 路徑
    rv_route = COND #( WHEN iv_item_type = 'BOOKING' THEN 'BAPI' ELSE 'BDC' ).
  ENDMETHOD.

  METHOD run_conversion.
    DATA lv_all_success TYPE abap_bool VALUE abap_true.

    LOOP AT it_items INTO DATA(ls_item).
      DATA(lv_index) = sy-tabix.
      DATA(lv_route) = route_item( ls_item-item_type ).

      IF lv_route = 'BAPI'.
* 情境 A：呼叫標準 BAPI，逐筆收集 RETURN 訊息，先不 COMMIT——
* 等全部項目都跑完才統一決定 COMMIT 或 ROLLBACK（呼應 if03 的 LUW 邊界設計，
* 也是 REST 課 rs10 已經驗證過的同一支 BAPI／同一套呼叫模式）
        DATA: ls_booking_data TYPE bapisbonew,
              lv_airlineid    TYPE bapisbokey-airlineid,
              lv_bookingid    TYPE bapisbokey-bookingid,
              ls_price        TYPE bapisbopri,
              lt_return       TYPE STANDARD TABLE OF bapiret2.

        CLEAR: ls_booking_data, lv_airlineid, lv_bookingid, ls_price, lt_return.

        ls_booking_data-airlineid  = ls_item-carrid.
        ls_booking_data-connectid  = ls_item-connid.
        ls_booking_data-flightdate = ls_item-fldate.
        ls_booking_data-customerid = ls_item-customid.
        ls_booking_data-class      = ls_item-class.
        ls_booking_data-passname   = ls_item-passname.
        ls_booking_data-counter    = ls_item-counter.

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
          lv_all_success = abap_false.
          APPEND VALUE #( index = lv_index route = lv_route success = abap_false
                          message = lv_error_message ) TO rt_result.
        ELSE.
          APPEND VALUE #( index = lv_index route = lv_route success = abap_true
                          message = |訂位建立成功，單號 { lv_bookingid }| ) TO rt_result.
        ENDIF.

      ELSE.
* 情境 B：沒有對應 BAPI 的項目——實務上會呼叫 if05 的 ZCL_IF05_BDC_RUNNER=>run_via_call_transaction
* 或 run_via_session；這裡沒有真實的 BDCDATA（要靠 SHDB 錄製，本課程記錄過的 GUI-only 限制），
* 只示範路由判斷本身，不假造一組 BDCDATA 去呼叫一個不存在的目標交易碼
        APPEND VALUE #( index = lv_index route = lv_route success = abap_true
                        message = |已判定走 BDC 路徑，交給 ZCL_IF05_BDC_RUNNER 處理（本示範未實際執行，需真實 BDCDATA）| ) TO rt_result.
      ENDIF.
    ENDLOOP.

    IF lv_all_success = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
