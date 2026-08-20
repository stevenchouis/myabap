REPORT zr_cds12_demo.

WRITE: / '=== Attempt 1: plain Open SQL SELECT against the virtual-element view ==='.
SELECT carrid, connid, fldate, DaysUntilDeparture
  FROM zi_cds12_flight_virtual
  WHERE carrid = 'AA'
  ORDER BY carrid, connid, fldate
  INTO TABLE @DATA(lt_result)
  UP TO 3 ROWS.

LOOP AT lt_result INTO DATA(ls_row).
  WRITE: / ls_row-carrid, ls_row-connid, ls_row-fldate, ls_row-daysuntildeparture.
ENDLOOP.

DATA(lv_all_zero) = abap_true.
LOOP AT lt_result INTO ls_row WHERE daysuntildeparture <> 0.
  lv_all_zero = abap_false.
ENDLOOP.
IF lv_all_zero = abap_true.
  WRITE: / 'Result: all rows show DaysUntilDeparture = 0 (the placeholder value), the exit class was NOT triggered via plain Open SQL.'.
ELSE.
  WRITE: / 'Result: DaysUntilDeparture carries a real computed value even via plain Open SQL - the exit WAS triggered.'.
ENDIF.

WRITE: / '=== Attempt 2: call ZCL_CDS12_DAYS_CALC directly to verify its own logic ==='.

TYPES: BEGIN OF ty_flight_row,
         carrid TYPE sflight-carrid,
         connid TYPE sflight-connid,
         fldate TYPE sflight-fldate,
       END OF ty_flight_row.
TYPES: BEGIN OF ty_calc_row,
         daysuntildeparture TYPE i,
       END OF ty_calc_row.

DATA lt_orig TYPE STANDARD TABLE OF ty_flight_row WITH EMPTY KEY.
DATA lt_calc TYPE STANDARD TABLE OF ty_calc_row WITH EMPTY KEY.

lt_orig = VALUE #( ( carrid = 'AA' connid = '0017' fldate = sy-datum + 10 ) ).
lt_calc = VALUE #( ( daysuntildeparture = 0 ) ).

DATA(lo_calc) = NEW zcl_cds12_days_calc( ).
DATA lt_requested TYPE if_sadl_exit_calc_element_read=>tt_elements.

TRY.
    lo_calc->if_sadl_exit_calc_element_read~calculate(
      EXPORTING it_original_data           = lt_orig
                it_requested_calc_elements = lt_requested
      CHANGING  ct_calculated_data         = lt_calc ).
  CATCH cx_sadl_exit INTO DATA(lx_error).
    WRITE: / 'EXCEPTION:', lx_error->get_text( ).
ENDTRY.

READ TABLE lt_calc INTO DATA(ls_calc) INDEX 1.
WRITE: / 'Computed DaysUntilDeparture for fldate = today+10:', ls_calc-daysuntildeparture.

WRITE: / '=== Sanity check: exit class correctly computes 10 days ==='.
IF ls_calc-daysuntildeparture = 10.
  WRITE: / 'MATCH: exit class logic correctly computed the day difference'.
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
