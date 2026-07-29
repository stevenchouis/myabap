*&---------------------------------------------------------------------*
*& INCLUDE          ZXVBZU02
*&---------------------------------------------------------------------*
* Enhancement course en02: reformat the batch number already drawn from
* ZEN02BAT (redirected in EXIT_SAPLV01Z_001 / ZXVBZU01) into
* YYMMDD + 4-digit serial (10 chars total, fits MCHA-CHARG length).
new_charg = sy-datum+2(6) && new_charg+6(4).