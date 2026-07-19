REPORT zr_am04_demo.

zcl_am04_route_load=>get_route_load_factor(
  EXPORTING
    iv_mandt  = sy-mandt
  IMPORTING
    et_routes = DATA(lt_routes) ).

LOOP AT lt_routes ASSIGNING FIELD-SYMBOL(<ls_route>).
  WRITE: / <ls_route>-carrid, <ls_route>-carrname, <ls_route>-connid,
           <ls_route>-flight_cnt, <ls_route>-seats_occ, <ls_route>-seats_max,
           <ls_route>-load_pct.
ENDLOOP.
