REPORT zr_am01_demo.

zcl_am01_carriers=>get_carriers(
  EXPORTING
    iv_mandt    = sy-mandt
  IMPORTING
    et_carriers = DATA(lt_carriers) ).

LOOP AT lt_carriers ASSIGNING FIELD-SYMBOL(<ls_carrier>).
  WRITE: / <ls_carrier>-carrid, <ls_carrier>-carrname.
ENDLOOP.
