REPORT zr_am07_demo.

SELECT carrid, carrname, connid, flight_cnt, seats_occ, seats_max, load_pct
  FROM ztf_am07_route_stats
  ORDER BY carrid, connid
  INTO TABLE @DATA(lt_routes).

LOOP AT lt_routes ASSIGNING FIELD-SYMBOL(<ls_route>).
  WRITE: / <ls_route>-carrid, <ls_route>-carrname, <ls_route>-connid,
           <ls_route>-flight_cnt, <ls_route>-seats_occ, <ls_route>-seats_max,
           <ls_route>-load_pct.
ENDLOOP.

WRITE: / 'Total rows:', lines( lt_routes ).
