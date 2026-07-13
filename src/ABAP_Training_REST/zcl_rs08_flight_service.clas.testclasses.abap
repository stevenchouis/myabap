*"* use this source file for your ABAP unit test classes

* 測試類別：只測純邏輯方法（parse_keys/validate_update），不碰資料庫
*   RISK LEVEL HARMLESS（不改系統狀態）DURATION SHORT（跑得快）
CLASS ltc_parse_keys DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      valid_input_passes         FOR TESTING RAISING zcx_rs08_flight_error,
      fldate_wrong_length_raises FOR TESTING,
      fldate_non_numeric_raises  FOR TESTING.
ENDCLASS.

CLASS ltc_parse_keys IMPLEMENTATION.
  METHOD valid_input_passes.
*   given/when：合法輸入
    DATA(ls_keys) = zcl_rs08_flight_service=>parse_keys(
      iv_carrid = 'AA'
      iv_connid = '0017'
      iv_fldate = '20260101' ).

*   then
    cl_abap_unit_assert=>assert_equals(
      act = ls_keys-carrid
      exp = 'AA'
      msg = 'carrid 應該原樣帶入' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_keys-fldate
      exp = '20260101'
      msg = 'fldate 應該原樣帶入' ).
  ENDMETHOD.

  METHOD fldate_wrong_length_raises.
*   given/when：fldate 只有 7 碼
    DATA(lv_raised) = abap_false.

    TRY.
        zcl_rs08_flight_service=>parse_keys(
          iv_carrid = 'AA'
          iv_connid = '0017'
          iv_fldate = '2026101' ).
      CATCH zcx_rs08_flight_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'INVALID_DATE'
          msg = '長度不對應該回 INVALID_DATE' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs08_flight_error' ).
  ENDMETHOD.

  METHOD fldate_non_numeric_raises.
*   given/when：這正是 rs07 實測才抓到的 bug 場景——
*   CONV dats( 'abcd' ) 當年不會拋例外，這裡改用 parse_keys 明確驗證格式，
*   測試直接覆蓋這個案例，以後這種回歸不用等到掛 SICF 才發現
    DATA(lv_raised) = abap_false.

    TRY.
        zcl_rs08_flight_service=>parse_keys(
          iv_carrid = 'LH'
          iv_connid = '0400'
          iv_fldate = 'abcd' ).
      CATCH zcx_rs08_flight_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'INVALID_DATE'
          msg = '非數字字元應該回 INVALID_DATE' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs08_flight_error' ).
  ENDMETHOD.
ENDCLASS.

CLASS ltc_validate_update DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      valid_input_passes      FOR TESTING RAISING zcx_rs08_flight_error,
      missing_price_raises    FOR TESTING,
      missing_currency_raises FOR TESTING.
ENDCLASS.

CLASS ltc_validate_update IMPLEMENTATION.
  METHOD valid_input_passes.
*   given：price/currency 都有填
    DATA(ls_update) = VALUE zcl_rs08_flight_service=>ty_update(
      price    = '680.00'
      currency = 'EUR' ).

*   when/then：不應該拋出例外
    zcl_rs08_flight_service=>validate_update( ls_update ).
  ENDMETHOD.

  METHOD missing_price_raises.
*   given：只有 currency，沒有 price
    DATA(ls_update) = VALUE zcl_rs08_flight_service=>ty_update( currency = 'EUR' ).
    DATA(lv_raised) = abap_false.

*   when
    TRY.
        zcl_rs08_flight_service=>validate_update( ls_update ).
      CATCH zcx_rs08_flight_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = '缺 price 應該回 VALIDATION_FAILED' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs08_flight_error' ).
  ENDMETHOD.

  METHOD missing_currency_raises.
*   given：只有 price，沒有 currency
    DATA(ls_update) = VALUE zcl_rs08_flight_service=>ty_update( price = '680.00' ).
    DATA(lv_raised) = abap_false.

*   when
    TRY.
        zcl_rs08_flight_service=>validate_update( ls_update ).
      CATCH zcx_rs08_flight_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = '缺 currency 應該回 VALIDATION_FAILED' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs08_flight_error' ).
  ENDMETHOD.
ENDCLASS.
