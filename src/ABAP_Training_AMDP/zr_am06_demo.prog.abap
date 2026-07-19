REPORT zr_am06_demo.

START-OF-SELECTION.

  zcl_am04_route_load=>get_route_load_factor(
    EXPORTING
      iv_mandt  = sy-mandt
    IMPORTING
      et_routes = DATA(lt_routes) ).

  cl_salv_table=>factory(
    IMPORTING
      r_salv_table = DATA(lo_alv)
    CHANGING
      t_table      = lt_routes ).
  lo_alv->get_columns( )->set_optimize( abap_true ).
  lo_alv->display( ).
