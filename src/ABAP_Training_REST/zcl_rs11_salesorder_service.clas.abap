CLASS zcl_rs11_salesorder_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* REST 練習 11：Header(1)+Item(多筆) 一次 BAPI 呼叫——BAPI_SALESORDER_CREATEFROMDAT2
* 跨出 SFLIGHT/SBOOK 主題改用銷售訂單模型，因為 SFLIGHT/SBOOK 沒有這種「一次呼叫、介面本身吃 1 對多」的標準 BAPI
* items 巢狀在 header 底下（不是跟 header 同一層的陣列），呼應「訂單抬頭底下才有品項明細」的業務語意
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_item,
             material TYPE bapisditm-material,
             quantity TYPE bapisditm-target_qty,
             unit     TYPE bapisditm-target_qu,
           END OF ty_item,

           tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,

           BEGIN OF ty_header,
             doc_type   TYPE auart,
             sales_org  TYPE vkorg,
             distr_chan TYPE vtweg,
             division   TYPE spart,
             sold_to    TYPE kunnr,
             items      TYPE tt_item,
           END OF ty_header,

           BEGIN OF ty_create_request,
             header TYPE ty_header,
           END OF ty_create_request,

           tt_message TYPE STANDARD TABLE OF string WITH EMPTY KEY,

           BEGIN OF ty_result,
             sales_document TYPE bapivbeln-vbeln,
             testrun        TYPE abap_bool,
             messages       TYPE tt_message,
           END OF ty_result.

    CLASS-METHODS:
* 純邏輯，不碰資料庫／BAPI——ABAP Unit 全部覆蓋
      validate_request
        IMPORTING is_request TYPE ty_create_request
        RAISING   zcx_rs11_salesorder_error,

* 會呼叫 BAPI，依課程慣例（rs08~rs10）不寫 ABAP Unit test，保持「薄」
      create_sales_order
        IMPORTING is_request      TYPE ty_create_request
                  iv_testrun      TYPE abap_bool DEFAULT abap_false
        RETURNING VALUE(rs_result) TYPE ty_result
        RAISING   zcx_rs11_salesorder_error.
ENDCLASS.

CLASS zcl_rs11_salesorder_service IMPLEMENTATION.

  METHOD validate_request.
    IF is_request-header-doc_type   IS INITIAL OR
       is_request-header-sales_org  IS INITIAL OR
       is_request-header-distr_chan IS INITIAL OR
       is_request-header-division   IS INITIAL OR
       is_request-header-sold_to    IS INITIAL.
      RAISE EXCEPTION TYPE zcx_rs11_salesorder_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'VALIDATION_FAILED'
          iv_message     = |header 的 docType、salesOrg、distrChan、division、soldTo 都必填|.
    ENDIF.

    IF is_request-header-items IS INITIAL.
      RAISE EXCEPTION TYPE zcx_rs11_salesorder_error
        EXPORTING
          iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
          iv_error_code  = 'VALIDATION_FAILED'
          iv_message     = |header.items 至少要有一筆|.
    ENDIF.

    LOOP AT is_request-header-items INTO DATA(ls_item).
      IF ls_item-material IS INITIAL OR ls_item-unit IS INITIAL OR ls_item-quantity <= 0.
        RAISE EXCEPTION TYPE zcx_rs11_salesorder_error
          EXPORTING
            iv_status_code = cl_rest_status_code=>gc_client_error_bad_request
            iv_error_code  = 'VALIDATION_FAILED'
            iv_message     = |第 { sy-tabix } 筆 header.items 的 material、quantity（須大於 0）、unit 都必填|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD create_sales_order.
    DATA ls_header_in     TYPE bapisdhd1.
    DATA ls_header_inx    TYPE bapisdhd1x.
    DATA lt_items_in      TYPE STANDARD TABLE OF bapisditm.
    DATA lt_items_inx     TYPE STANDARD TABLE OF bapisditmx.
    DATA lt_partners      TYPE STANDARD TABLE OF bapiparnr.
    DATA lt_return        TYPE STANDARD TABLE OF bapiret2.
    DATA lv_salesdocument TYPE bapivbeln-vbeln.

    ls_header_in-doc_type   = is_request-header-doc_type.
    ls_header_in-sales_org  = is_request-header-sales_org.
    ls_header_in-distr_chan = is_request-header-distr_chan.
    ls_header_in-division   = is_request-header-division.

* 全新建立：updateflag = 'I'，並且明確把有填值的欄位都標成 'X'
* （比只設 updateflag 更保守、跨版本相容性更好，是這支 BAPI 常見教學範例的做法）
    ls_header_inx-updateflag = 'I'.
    ls_header_inx-doc_type   = 'X'.
    ls_header_inx-sales_org  = 'X'.
    ls_header_inx-distr_chan = 'X'.
    ls_header_inx-division   = 'X'.

* Sold-to Party（角色 AG）是必填的 TABLES 參數，itm_number 留白代表這是抬頭層級的夥伴
    APPEND VALUE #( partn_role = 'AG'
                    partn_numb = is_request-header-sold_to ) TO lt_partners.

    LOOP AT is_request-header-items INTO DATA(ls_item).
      DATA(lv_itm_number) = CONV bapisditm-itm_number( sy-tabix * 10 ).

      APPEND VALUE #( itm_number = lv_itm_number
                      material   = ls_item-material
                      target_qty = ls_item-quantity
                      target_qu  = ls_item-unit ) TO lt_items_in.

      APPEND VALUE #( itm_number = lv_itm_number
                      updateflag = 'I'
                      material   = 'X'
                      target_qty = 'X'
                      target_qu  = 'X' ) TO lt_items_inx.
    ENDLOOP.

    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
        order_header_in  = ls_header_in
        order_header_inx = ls_header_inx
        testrun           = COND bapiflag-bapiflag( WHEN iv_testrun = abap_true THEN 'X' ELSE space )
      IMPORTING
        salesdocument    = lv_salesdocument
      TABLES
        return           = lt_return
        order_items_in   = lt_items_in
        order_items_inx  = lt_items_inx
        order_partners   = lt_partners.

    DATA(lv_has_error) = abap_false.
    DATA lt_messages TYPE tt_message.
    LOOP AT lt_return INTO DATA(ls_msg) WHERE message IS NOT INITIAL.
      APPEND ls_msg-message TO lt_messages.
      IF ls_msg-type = 'E' OR ls_msg-type = 'A'.
        lv_has_error = abap_true.
      ENDIF.
    ENDLOOP.

    IF lv_has_error = abap_true.
* 呼叫過的 BAPI 不管成功失敗都該收尾，失敗這條路也要 ROLLBACK 釋放內部緩衝
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      RAISE EXCEPTION TYPE zcx_rs11_salesorder_error
        EXPORTING
* 這版 CL_REST_STATUS_CODE 沒有 422 Unprocessable Entity 的常數，直接用字面值
          iv_status_code = 422
          iv_error_code  = 'SALES_ORDER_REJECTED'
          iv_message     = concat_lines_of( table = lt_messages sep = `; ` ).
    ENDIF.

    IF iv_testrun = abap_true.
* testrun 不寫入任何資料，但官方建議仍呼叫 ROLLBACK 清除當次呼叫累積的內部緩衝
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.
    ENDIF.

    rs_result-sales_document = lv_salesdocument.
    rs_result-testrun        = iv_testrun.
    rs_result-messages       = lt_messages.
  ENDMETHOD.

ENDCLASS.
