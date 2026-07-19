REPORT zr_am03_demo.

PARAMETERS p_carrid TYPE s_carr_id DEFAULT 'LH'.

START-OF-SELECTION.

  zcl_am03_price_tier=>classify_flight_prices(
    EXPORTING
      iv_mandt      = sy-mandt
      iv_carrid     = p_carrid
    IMPORTING
      et_flights    = DATA(lt_flights)
      ev_low_cnt    = DATA(lv_low_cnt)
      ev_medium_cnt = DATA(lv_medium_cnt)
      ev_high_cnt   = DATA(lv_high_cnt) ).

  WRITE: / 'FLIGHTS (with tier):'.
  LOOP AT lt_flights ASSIGNING FIELD-SYMBOL(<ls_flight>).
    WRITE: / <ls_flight>-carrid, <ls_flight>-connid, <ls_flight>-fldate,
             <ls_flight>-price, <ls_flight>-currency, <ls_flight>-price_tier.
  ENDLOOP.

  WRITE: / 'TIER COUNTS:'.
  WRITE: / 'LOW   =', lv_low_cnt.
  WRITE: / 'MEDIUM=', lv_medium_cnt.
  WRITE: / 'HIGH  =', lv_high_cnt.
