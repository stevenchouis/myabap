REPORT zr_am02_demo.

PARAMETERS p_carrid TYPE s_carr_id DEFAULT 'LH'.

START-OF-SELECTION.

  zcl_am02_flight_stats=>get_flight_stats(
    EXPORTING
      iv_mandt   = sy-mandt
      iv_carrid  = p_carrid
    IMPORTING
      et_flights = DATA(lt_flights)
      et_stats   = DATA(lt_stats) ).

  cl_salv_table=>factory(
    IMPORTING
      r_salv_table = DATA(lo_alv_flights)
    CHANGING
      t_table      = lt_flights ).
  lo_alv_flights->get_columns( )->set_optimize( abap_true ).
  lo_alv_flights->display( ).

  cl_salv_table=>factory(
    IMPORTING
      r_salv_table = DATA(lo_alv_stats)
    CHANGING
      t_table      = lt_stats ).
  lo_alv_stats->get_columns( )->set_optimize( abap_true ).
  lo_alv_stats->display( ).
