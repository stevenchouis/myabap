CLASS ltc_route_item DEFINITION FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      booking_routes_to_bapi FOR TESTING,
      other_type_routes_to_bdc FOR TESTING,
      empty_type_routes_to_bdc FOR TESTING.

ENDCLASS.


CLASS ltc_route_item IMPLEMENTATION.

  METHOD booking_routes_to_bapi.
    DATA(lv_route) = zcl_if09_conversion_runner=>route_item( 'BOOKING' ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_route
      exp = 'BAPI' ).
  ENDMETHOD.

  METHOD other_type_routes_to_bdc.
    DATA(lv_route) = zcl_if09_conversion_runner=>route_item( 'LEGACY_MASTER_DATA' ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_route
      exp = 'BDC' ).
  ENDMETHOD.

  METHOD empty_type_routes_to_bdc.
* 沒有型態資訊時，安全預設值應該是「沒有對應 BAPI」而不是誤判成有 BAPI，
* 避免程式誤呼叫一個根本不對應的 BAPI
    DATA(lv_route) = zcl_if09_conversion_runner=>route_item( '' ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_route
      exp = 'BDC' ).
  ENDMETHOD.

ENDCLASS.
