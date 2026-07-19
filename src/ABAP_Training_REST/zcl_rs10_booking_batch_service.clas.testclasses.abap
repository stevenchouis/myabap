*"* use this source file for your ABAP unit test classes

* 測試類別：只測 validate_requests 這個純邏輯方法，不碰 BAPI／資料庫
*   RISK LEVEL HARMLESS（不改系統狀態）DURATION SHORT（跑得快）
CLASS ltc_validate_requests DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      non_empty_passes FOR TESTING RAISING zcx_rs10_batch_error,
      empty_raises      FOR TESTING.
ENDCLASS.

CLASS ltc_validate_requests IMPLEMENTATION.
  METHOD non_empty_passes.
*   given：至少一筆
    DATA(lt_requests) = VALUE zcl_rs10_booking_batch_service=>tt_request(
      ( carrid = 'LH' connid = '0400' fldate = '20190104' customid = '00000001' class = 'Y' passname = 'Mickey Mouse' counter = '00000001' ) ).

*   when/then：不應該拋出例外
    zcl_rs10_booking_batch_service=>validate_requests( lt_requests ).
  ENDMETHOD.

  METHOD empty_raises.
*   given：空陣列
    DATA(lt_requests) = VALUE zcl_rs10_booking_batch_service=>tt_request( ).
    DATA(lv_raised) = abap_false.

*   when
    TRY.
        zcl_rs10_booking_batch_service=>validate_requests( lt_requests ).
      CATCH zcx_rs10_batch_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = '空陣列應該回 VALIDATION_FAILED' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs10_batch_error' ).
  ENDMETHOD.
ENDCLASS.
