REPORT zr_am06_demo.

START-OF-SELECTION.

  zcl_am04_route_load=>get_route_load_factor(
    EXPORTING
      iv_mandt  = sy-mandt
    IMPORTING
      et_routes = DATA(lt_routes) ).

  DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
        ls_fieldcat TYPE slis_fieldcat_alv.

  DEFINE add_fieldcat.
    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = &1.
    ls_fieldcat-seltext_m = &2.
    ls_fieldcat-outputlen = &3.
    APPEND ls_fieldcat TO lt_fieldcat.
  END-OF-DEFINITION.

  add_fieldcat: 'CARRID'     'Carrier'     3,
                'CARRNAME'   'Carrier Name' 20,
                'CONNID'     'Connection'  4,
                'FLIGHT_CNT' 'Flights'     6,
                'SEATS_OCC'  'Seats Occ.'  8,
                'SEATS_MAX'  'Seats Max'   8,
                'LOAD_PCT'   'Load %'      6.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      it_fieldcat        = lt_fieldcat
    TABLES
      t_outtab           = lt_routes.
