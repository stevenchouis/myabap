REPORT zr_am08_demo.

PARAMETERS p_carrid TYPE s_carr_id DEFAULT 'LH'.
PARAMETERS p_skip AS CHECKBOX DEFAULT abap_true.

START-OF-SELECTION.

  GET RUN TIME FIELD DATA(lv_t1).
  DATA(lt_classic) = zcl_am08_revenue_classic=>get_revenues(
                        iv_carrid      = p_carrid
                        iv_skip_unsold = p_skip ).
  GET RUN TIME FIELD DATA(lv_t2).

  zcl_am08_flight_revenue=>get_revenues(
    EXPORTING
      iv_mandt       = sy-mandt
      iv_carrid      = p_carrid
      iv_skip_unsold = p_skip
    IMPORTING
      et_revenue     = DATA(lt_amdp) ).
  GET RUN TIME FIELD DATA(lv_t3).

  DATA(lv_time_classic) = lv_t2 - lv_t1.
  DATA(lv_time_amdp)    = lv_t3 - lv_t2.

  DATA: lv_sum_classic TYPE p LENGTH 8 DECIMALS 2,
        lv_sum_amdp    TYPE p LENGTH 8 DECIMALS 2.

  LOOP AT lt_classic INTO DATA(ls_c).
    lv_sum_classic += ls_c-revenue.
  ENDLOOP.

  LOOP AT lt_amdp INTO DATA(ls_a).
    lv_sum_amdp += ls_a-revenue.
  ENDLOOP.

  WRITE: / 'Classic ABAP  : rows =', lines( lt_classic ), '  time(us) =', lv_time_classic, '  total revenue =', lv_sum_classic.
  WRITE: / 'AMDP push-down: rows =', lines( lt_amdp ),    '  time(us) =', lv_time_amdp,    '  total revenue =', lv_sum_amdp.
