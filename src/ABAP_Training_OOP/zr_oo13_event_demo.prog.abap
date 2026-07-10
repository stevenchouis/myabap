*&---------------------------------------------------------------------*
*& Report  ZR_OO13_EVENT_DEMO
*& OOP 練習 13：OO 事件（答案程式——訂閱端）
*& 發布者 ZCL_OO13_FLIGHT_MONITOR 不認識任何訂閱者；
*& 本程式的三個 local class 各自訂閱，彼此也互不相識
*&---------------------------------------------------------------------*
REPORT zr_oo13_event_demo.

DATA gt_flights TYPE zcl_oo13_flight_monitor=>tt_flights.

*----------------------------------------------------------------------*
* 訂閱者一：畫面告警
* FOR EVENT ... OF：宣告「我專門處理那個類別的那個事件」
* sender = 發事件的物件參考（多發布者時可分辨是誰發的）
*----------------------------------------------------------------------*
CLASS lcl_alerter DEFINITION.
  PUBLIC SECTION.
    METHODS on_seats_low
      FOR EVENT seats_low OF zcl_oo13_flight_monitor
      IMPORTING iv_carrid iv_connid iv_fldate iv_pct sender.
ENDCLASS.

CLASS lcl_alerter IMPLEMENTATION.
  METHOD on_seats_low.
    WRITE: / '【告警】', iv_carrid, iv_connid, iv_fldate,
             '乘載率', iv_pct, '%'.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 訂閱者二：只做統計——同一事件可有多個訂閱者；
* IMPORTING 只接自己用得到的參數即可
*----------------------------------------------------------------------*
CLASS lcl_logger DEFINITION.
  PUBLIC SECTION.
    DATA mv_count TYPE i READ-ONLY.
    METHODS on_seats_low
      FOR EVENT seats_low OF zcl_oo13_flight_monitor
      IMPORTING iv_carrid.
ENDCLASS.

CLASS lcl_logger IMPLEMENTATION.
  METHOD on_seats_low.
    mv_count = mv_count + 1.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 訂閱者三：標準 API 的事件——SALV 的 double_click（實戰）
* 跟自訂事件同一套機制，只是事件是 SAP 宣告的
*----------------------------------------------------------------------*
CLASS lcl_salv_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_double_click
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS lcl_salv_handler IMPLEMENTATION.
  METHOD on_double_click.
    READ TABLE gt_flights INTO DATA(ls_flight) INDEX row.
    IF sy-subrc = 0.
      DATA(lv_msg) = |{ ls_flight-carrid } { ls_flight-connid } | &&
                     |{ ls_flight-fldate DATE = USER }：已售 | &&
                     |{ ls_flight-seatsocc }／{ ls_flight-seatsmax } 座|.
      MESSAGE lv_msg TYPE 'I'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  SELECT * FROM sflight
    INTO TABLE gt_flights
    UP TO 200 ROWS.
  IF sy-subrc <> 0.
    MESSAGE '查無航班資料（先跑 SAPBC_DATA_GENERATOR）' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

* 發布者與訂閱者各自 NEW；此刻兩邊還沒有任何關係
  DATA(go_monitor) = NEW zcl_oo13_flight_monitor( iv_threshold = 50 ).
  DATA(go_alerter) = NEW lcl_alerter( ).
  DATA(go_logger)  = NEW lcl_logger( ).

* SET HANDLER：訂閱——把 handler 方法掛到「這個」發布者物件上
  SET HANDLER go_alerter->on_seats_low FOR go_monitor.
  SET HANDLER go_logger->on_seats_low  FOR go_monitor.

  WRITE / '=== 第一次掃描：兩個訂閱者都在 ==='.
  go_monitor->scan( gt_flights ).
  WRITE: / 'logger 統計：', go_logger->mv_count, '筆低乘載告警'.

* 退訂：同一句 SET HANDLER 加 ACTIVATION space
  SET HANDLER go_alerter->on_seats_low FOR go_monitor ACTIVATION space.

  ULINE.
  WRITE / '=== 第二次掃描：alerter 已退訂，只剩 logger 在數 ==='.
  go_monitor->scan( gt_flights ).
  WRITE: / 'logger 統計：', go_logger->mv_count, '筆（兩次累計）'.

*----------------------------------------------------------------------*
* 實戰：訂閱 cl_salv_table 的 double_click
* get_event( ) 回傳事件物件（cl_salv_events_table），對它 SET HANDLER
*----------------------------------------------------------------------*
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = DATA(go_alv)
        CHANGING  t_table      = gt_flights ).
      go_alv->get_functions( )->set_all( ).
      go_alv->get_columns( )->set_optimize( ).

      DATA(go_events)  = go_alv->get_event( ).
      DATA(go_handler) = NEW lcl_salv_handler( ).
      SET HANDLER go_handler->on_double_click FOR go_events.

      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx_salv).
      WRITE: / 'ALV 顯示失敗：', lx_salv->get_text( ).
  ENDTRY.
