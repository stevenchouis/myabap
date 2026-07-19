REPORT zr_am05_demo LINE-SIZE 250.

DATA(lt_test_carriers) = VALUE string_table( ( `LH` ) ( `ZZ` ) ).

LOOP AT lt_test_carriers INTO DATA(lv_carrid_str).
  DATA(lv_carrid) = CONV s_carr_id( lv_carrid_str ).

  TRY.
      zcl_am05_flight_validator=>check_carrier_exists(
        iv_mandt  = sy-mandt
        iv_carrid = lv_carrid ).
      WRITE: / lv_carrid, ': OK, carrier exists'.
    CATCH cx_amdp_error INTO DATA(lx_error).
      WRITE: / lv_carrid, ': ERROR -', lx_error->get_text( ).
  ENDTRY.
ENDLOOP.
