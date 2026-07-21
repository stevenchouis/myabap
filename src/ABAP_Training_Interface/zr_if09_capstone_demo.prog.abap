REPORT zr_if09_capstone_demo.

START-OF-SELECTION.

  DATA(lt_items) = VALUE zcl_if09_conversion_runner=>tt_item(
    ( item_type = 'BOOKING' carrid = 'LH' connid = '0400' fldate = '20270101'
      customid = '00000001' class = 'Y' passname = 'Capstone Demo One' counter = '00000001' )
    ( item_type = 'BOOKING' carrid = 'LH' connid = '0400' fldate = '20270101'
      customid = '00000001' class = 'Y' passname = 'Capstone Demo Two' counter = '00000001' )
    ( item_type = 'LEGACY_MASTER_DATA' ) ).

  DATA(lt_result) = zcl_if09_conversion_runner=>run_conversion( lt_items ).

  WRITE: / 'if09 期末綜合實作：混合批次（BAPI + BDC 路由）結果'.
  ULINE.

  LOOP AT lt_result INTO DATA(ls_result).
    WRITE: / ls_result-index, ls_result-route,
             COND #( WHEN ls_result-success = abap_true THEN 'OK' ELSE 'FAIL' ),
             ls_result-message.
  ENDLOOP.
