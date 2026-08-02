*&---------------------------------------------------------------------*
*& Report  ZR_TR15_CALL_FM
*& 練習 15：呼叫 Function Module（答案程式——呼叫端）
*&---------------------------------------------------------------------*
* FM 是「跨程式共用」的邏輯單位：
*   SE37 可單獨測試、任何程式都能 CALL FUNCTION 呼叫
* 方向容易搞混：
*   FM 定義的 IMPORTING（它要「收」的）→ 呼叫端寫在 EXPORTING（我「送」的）
*   FM 定義的 EXPORTING（它要「給」的）→ 呼叫端寫在 IMPORTING（我「收」的）
*&---------------------------------------------------------------------*
REPORT zr_tr15_call_fm.

DATA gv_revenue TYPE s_price.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 正常呼叫
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_CALC_REVENUE'
    EXPORTING
      iv_price      = '1500.00'
      iv_seatsocc   = 200
    IMPORTING
      ev_revenue    = gv_revenue
    EXCEPTIONS
      invalid_input = 1
      OTHERS        = 2.
  IF sy-subrc = 0.
    WRITE: / '票價 1500.00 × 200 座 = 營收', gv_revenue.
  ENDIF.

*----------------------------------------------------------------------*
* 錯誤輸入：FM 裡 RAISE invalid_input → 呼叫端 sy-subrc = 1
* EXCEPTIONS 後面的數字是「發生該例外時 sy-subrc 要變成幾」
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_CALC_REVENUE'
    EXPORTING
      iv_price      = '-99.00'
      iv_seatsocc   = 10
    IMPORTING
      ev_revenue    = gv_revenue
    EXCEPTIONS
      invalid_input = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
    WRITE: / '負數票價被 FM 擋下，sy-subrc =', sy-subrc.
  ENDIF.

*----------------------------------------------------------------------*
* Part 4：CHANGING + Table Type（取代舊式 TABLES 參數）
* CT_FLIGHTS 是 CHANGING 參數：呼叫前先塞好 3 筆航班（REVENUE 都是 0），
* FM 直接在原表裡把 REVENUE 算出來、改回來——呼叫端不用另外接 EXPORTING。
*----------------------------------------------------------------------*
  DATA gt_flights TYPE ztr15_tt_flight_rev.

  APPEND VALUE #( carrid = 'LH' connid = '0400' price = '500.00'  seatsocc = 100 currency = 'EUR' ) TO gt_flights.
  APPEND VALUE #( carrid = 'LH' connid = '2402' price = '800.00'  seatsocc = 50  currency = 'EUR' ) TO gt_flights.
  APPEND VALUE #( carrid = 'AA' connid = '0017' price = '1200.00' seatsocc = 30  currency = 'USD' ) TO gt_flights.

  CALL FUNCTION 'Z_TR15_CALC_REVENUE_TAB'
    CHANGING
      ct_flights = gt_flights.

  WRITE / '=== CHANGING + Table Type：逐航班營收 ==='.
  LOOP AT gt_flights INTO DATA(gs_flight).
    WRITE: / gs_flight-carrid, gs_flight-connid, gs_flight-price,
             gs_flight-seatsocc, '=>', gs_flight-revenue, gs_flight-currency.
  ENDLOOP.