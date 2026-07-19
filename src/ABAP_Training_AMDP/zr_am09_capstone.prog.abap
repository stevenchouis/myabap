REPORT zr_am09_capstone.

START-OF-SELECTION.

  SELECT carrid, carrname, route_cnt, total_flights, total_seats_occ,
         total_seats_max, load_pct, total_revenue
    FROM ztf_am09_carrier_stats
    ORDER BY carrid
    INTO TABLE @DATA(lt_stats).

  cl_salv_table=>factory(
    IMPORTING
      r_salv_table = DATA(lo_alv)
    CHANGING
      t_table      = lt_stats ).
  lo_alv->get_columns( )->set_optimize( abap_true ).
  lo_alv->display( ).
