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

  DATA(lo_columns) = lo_alv->get_columns( ).
  lo_columns->set_optimize( abap_true ).

  lo_columns->get_column( 'CARRID' )->set_medium_text( 'Carrier' ).
  lo_columns->get_column( 'CARRNAME' )->set_medium_text( 'Airline' ).
  lo_columns->get_column( 'ROUTE_CNT' )->set_medium_text( 'Routes' ).
  lo_columns->get_column( 'TOTAL_FLIGHTS' )->set_medium_text( 'Flights' ).
  lo_columns->get_column( 'TOTAL_SEATS_OCC' )->set_medium_text( 'Seats Occ.' ).
  lo_columns->get_column( 'TOTAL_SEATS_MAX' )->set_medium_text( 'Seats Max' ).
  lo_columns->get_column( 'LOAD_PCT' )->set_medium_text( 'Load %' ).
  lo_columns->get_column( 'TOTAL_REVENUE' )->set_medium_text( 'Revenue' ).

  lo_alv->display( ).
