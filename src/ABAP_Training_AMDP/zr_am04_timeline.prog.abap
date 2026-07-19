REPORT zr_am04_timeline LINE-SIZE 200.

PARAMETERS p_carrid TYPE s_carr_id DEFAULT 'LH'.

START-OF-SELECTION.

  zcl_am04_route_load=>get_flight_timeline(
    EXPORTING
      iv_mandt    = sy-mandt
      iv_carrid   = p_carrid
    IMPORTING
      et_timeline = DATA(lt_timeline) ).

  LOOP AT lt_timeline ASSIGNING FIELD-SYMBOL(<ls_line>).
    WRITE: / <ls_line>-route_code, <ls_line>-carrname_up, <ls_line>-fldate,
             <ls_line>-flight_status, <ls_line>-days_diff.
  ENDLOOP.

  WRITE: / 'Total rows:', lines( lt_timeline ).
