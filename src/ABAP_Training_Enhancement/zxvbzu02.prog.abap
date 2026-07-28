*&---------------------------------------------------------------------*
*& INCLUDE          ZXVBZU02
*&---------------------------------------------------------------------*
* Enhancement course en02: custom batch number format YYMMDD + 4-digit
* serial (10 chars total, fits MCHA-CHARG length limit). Serial comes
* from our own Number Range Object ZEN02BAT (created via SNRO), not the
* standard BATCH_CLT range used by the framework above this exit.
DATA: lv_next_number(10) TYPE c.

CALL FUNCTION 'NUMBER_GET_NEXT'
  EXPORTING
    nr_range_nr = '01'
    object      = 'ZEN02BAT'
  IMPORTING
    number      = lv_next_number
  EXCEPTIONS
    OTHERS      = 1.

IF sy-subrc = 0.
  new_charg = sy-datum+2(6) && lv_next_number+6(4).
ENDIF.