*&---------------------------------------------------------------------*
*& Report ZR_EN02_BATCH_DEMO
*&---------------------------------------------------------------------*
* Enhancement course en02: standalone check that ZEN02BAT + the
* YYMMDD/4-digit-serial formatting logic (same as ZXVBZU02) works,
* without touching any real goods movement.
REPORT zr_en02_batch_demo.

DATA: lv_next_number(10) TYPE c,
      lv_charg(10)       TYPE c.

DO 3 TIMES.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZEN02BAT'
    IMPORTING
      number      = lv_next_number
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc = 0.
    lv_charg = sy-datum+2(6) && lv_next_number+6(4).
    WRITE: / 'raw number:', lv_next_number, '  batch no:', lv_charg.
  ELSE.
    WRITE: / 'NUMBER_GET_NEXT failed, sy-subrc =', sy-subrc.
  ENDIF.
ENDDO.