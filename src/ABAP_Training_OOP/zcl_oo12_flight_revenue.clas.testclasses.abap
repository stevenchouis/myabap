*"* use this source file for your ABAP unit test classes

* 測試對象是「純計算」的 build——不碰 DB，餵假資料就能驗證所有分支
CLASS ltc_flight_revenue DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      revenue_is_calculated FOR TESTING,
      unsold_removed_when_skip FOR TESTING,
      unsold_kept_when_no_skip FOR TESTING.
ENDCLASS.

CLASS ltc_flight_revenue IMPLEMENTATION.
  METHOD revenue_is_calculated.
*   given：一筆票價 100、已售 5 的假航班
    DATA(lo_calc) = NEW zcl_oo12_flight_revenue( ).
    DATA(lt_input) = VALUE zcl_oo12_flight_revenue=>tt_revenue(
      ( carrid = 'AA' price = '100.00' seatsocc = 5 currency = 'USD' ) ).

*   when
    DATA(lt_result) = lo_calc->build( lt_input ).

*   then：營收 = 100 × 5 = 500
    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 1 ]-revenue
      exp = '500.00'
      msg = '營收應為票價×已售座位' ).
  ENDMETHOD.

  METHOD unsold_removed_when_skip.
*   given：兩筆，其中一筆 seatsocc = 0
    DATA(lo_calc) = NEW zcl_oo12_flight_revenue( ).
    DATA(lt_input) = VALUE zcl_oo12_flight_revenue=>tt_revenue(
      ( carrid = 'AA' price = '100.00' seatsocc = 5 )
      ( carrid = 'LH' price = '200.00' seatsocc = 0 ) ).

*   when：預設 iv_skip_unsold = abap_true
    DATA(lt_result) = lo_calc->build( lt_input ).

*   then：未售出那筆被排除
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_result )
      exp = 1
      msg = '排除未售出時 seatsocc=0 應被刪除' ).
  ENDMETHOD.

  METHOD unsold_kept_when_no_skip.
*   given：同上，但不排除
    DATA(lo_calc) = NEW zcl_oo12_flight_revenue( ).
    DATA(lt_input) = VALUE zcl_oo12_flight_revenue=>tt_revenue(
      ( carrid = 'LH' price = '200.00' seatsocc = 0 ) ).

*   when
    DATA(lt_result) = lo_calc->build( it_flights     = lt_input
                                      iv_skip_unsold = abap_false ).

*   then：留著，且營收為 0（= ex13 取消 checkbox 的行為）
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_result )
      exp = 1
      msg = '不排除時 seatsocc=0 應保留' ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 1 ]-revenue
      exp = 0
      msg = '未售出航班營收應為 0' ).
  ENDMETHOD.
ENDCLASS.
