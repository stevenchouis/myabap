*"* use this source file for your ABAP unit test classes

* 測試替身（test double）：實作 op07 折扣介面、行為固定（永遠半價）
*   有了它，測試不依賴任何真實折扣類別——介面的另一個回報
CLASS ltd_half_off DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_oo07_discount.
ENDCLASS.

CLASS ltd_half_off IMPLEMENTATION.
  METHOD zif_oo07_discount~get_name.
    rv_name = |測試用半價|.
  ENDMETHOD.

  METHOD zif_oo07_discount~apply.
    rv_fare = iv_fare / 2.
  ENDMETHOD.
ENDCLASS.

* 測試類別：RISK LEVEL HARMLESS（不改系統狀態）DURATION SHORT（跑得快）
CLASS ltc_quote DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      economy_no_discount     FOR TESTING,
      business_child_discount FOR TESTING,
      stub_discount_applies   FOR TESTING.
ENDCLASS.

CLASS ltc_quote IMPLEMENTATION.
  METHOD economy_no_discount.
*   given：經濟艙、無折扣
    DATA(lo_quote) = NEW zcl_oo10_quote( io_fare = NEW zcl_oo06_fare_economy( ) ).

*   when：報價
    DATA(lv_total) = lo_quote->calc_quote( '1000.00' ).

*   then：應為原價
    cl_abap_unit_assert=>assert_equals(
      act = lv_total
      exp = '1000.00'
      msg = '經濟艙無折扣應為原價' ).
  ENDMETHOD.

  METHOD business_child_discount.
*   given：商務艙（×2.5）+ 兒童票（65 折）
    DATA(lo_quote) = NEW zcl_oo10_quote(
      io_fare      = NEW zcl_oo06_fare_business( )
      it_discounts = VALUE #( ( NEW zcl_oo07_disc_child( ) ) ) ).

*   when
    DATA(lv_total) = lo_quote->calc_quote( '1000.00' ).

*   then：1000 × 2.5 × 0.65 = 1625
    cl_abap_unit_assert=>assert_equals(
      act = lv_total
      exp = '1625.00'
      msg = '商務艙 2500 套兒童 65 折應為 1625' ).
  ENDMETHOD.

  METHOD stub_discount_applies.
*   given：注入測試替身——不用任何真實折扣類別也能測 calc_quote 的迴圈邏輯
    DATA(lo_quote) = NEW zcl_oo10_quote(
      io_fare      = NEW zcl_oo06_fare_economy( )
      it_discounts = VALUE #( ( NEW ltd_half_off( ) ) ) ).

*   when / then：1000 → 半價 500
    cl_abap_unit_assert=>assert_equals(
      act = lo_quote->calc_quote( '1000.00' )
      exp = '500.00'
      msg = '測試替身半價應為 500' ).
  ENDMETHOD.
ENDCLASS.
