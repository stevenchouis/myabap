*"* use this source file for your ABAP unit test classes

* 測試類別：只測純邏輯方法（parse_keys/validate_booking_fields），不碰資料庫
*   RISK LEVEL HARMLESS（不改系統狀態）DURATION SHORT（跑得快）
CLASS ltc_parse_keys DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      valid_input_passes         FOR TESTING RAISING zcx_rs09_booking_error,
      fldate_wrong_length_raises FOR TESTING,
      fldate_non_numeric_raises  FOR TESTING.
ENDCLASS.

CLASS ltc_parse_keys IMPLEMENTATION.
  METHOD valid_input_passes.
*   given/when：合法輸入
    DATA(ls_keys) = zcl_rs09_booking_service=>parse_keys(
      iv_carrid = 'AA'
      iv_connid = '0017'
      iv_fldate = '20260101'
      iv_bookid = '00000001' ).

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
        zcl_rs09_booking_service=>parse_keys(
          iv_carrid = 'AA'
          iv_connid = '0017'
          iv_fldate = '2026101'
          iv_bookid = '00000001' ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'INVALID_DATE'
          msg = '長度不對應該回 INVALID_DATE' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs09_booking_error' ).
  ENDMETHOD.

  METHOD fldate_non_numeric_raises.
*   given/when：跟 rs07/rs08 同一個 bug 場景——CONV dats( 'abcd' ) 不會拋例外，
*   parse_keys 明確驗證格式，這裡直接覆蓋這個案例
    DATA(lv_raised) = abap_false.

    TRY.
        zcl_rs09_booking_service=>parse_keys(
          iv_carrid = 'LH'
          iv_connid = '0400'
          iv_fldate = 'abcd'
          iv_bookid = '00000001' ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'INVALID_DATE'
          msg = '非數字字元應該回 INVALID_DATE' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs09_booking_error' ).
  ENDMETHOD.
ENDCLASS.

CLASS ltc_validate_booking_fields DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      valid_input_passes      FOR TESTING RAISING zcx_rs09_booking_error,
      missing_customid_raises FOR TESTING,
      missing_class_raises    FOR TESTING,
      missing_passname_raises FOR TESTING,
      invalid_class_raises    FOR TESTING.
ENDCLASS.

CLASS ltc_validate_booking_fields IMPLEMENTATION.
  METHOD valid_input_passes.
*   given/when/then：合法輸入不應該拋出例外
    zcl_rs09_booking_service=>validate_booking_fields(
      iv_customid = '00000001'
      iv_class    = 'Y'
      iv_passname = 'Mickey Mouse' ).
  ENDMETHOD.

  METHOD missing_customid_raises.
    DATA(lv_raised) = abap_false.
    DATA lv_empty_customid TYPE s_customer."留空，初始值就是「未填」

    TRY.
        zcl_rs09_booking_service=>validate_booking_fields(
          iv_customid = lv_empty_customid
          iv_class    = 'Y'
          iv_passname = 'Mickey Mouse' ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = '缺 customid 應該回 VALIDATION_FAILED' ).
    ENDTRY.

    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs09_booking_error' ).
  ENDMETHOD.

  METHOD missing_class_raises.
    DATA(lv_raised) = abap_false.

    TRY.
        zcl_rs09_booking_service=>validate_booking_fields(
          iv_customid = '00000001'
          iv_class    = ''
          iv_passname = 'Mickey Mouse' ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = '缺 class 應該回 VALIDATION_FAILED' ).
    ENDTRY.

    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs09_booking_error' ).
  ENDMETHOD.

  METHOD missing_passname_raises.
    DATA(lv_raised) = abap_false.

    TRY.
        zcl_rs09_booking_service=>validate_booking_fields(
          iv_customid = '00000001'
          iv_class    = 'Y'
          iv_passname = '' ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = '缺 passname 應該回 VALIDATION_FAILED' ).
    ENDTRY.

    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs09_booking_error' ).
  ENDMETHOD.

  METHOD invalid_class_raises.
*   given/when：class 給一個不在 F/C/Y 之列的值
    DATA(lv_raised) = abap_false.

    TRY.
        zcl_rs09_booking_service=>validate_booking_fields(
          iv_customid = '00000001'
          iv_class    = 'X'
          iv_passname = 'Mickey Mouse' ).
      CATCH zcx_rs09_booking_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'INVALID_CLASS'
          msg = '不合法的 class 值應該回 INVALID_CLASS' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs09_booking_error' ).
  ENDMETHOD.
ENDCLASS.
