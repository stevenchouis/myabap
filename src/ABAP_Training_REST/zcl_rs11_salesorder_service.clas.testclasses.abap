*"* use this source file for your ABAP unit test classes

* 測試類別 1：validate_request——只測純邏輯，不碰 BAPI／資料庫
*   RISK LEVEL HARMLESS（不改系統狀態）DURATION SHORT（跑得快）
CLASS ltc_validate_request DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      valid_request_passes         FOR TESTING RAISING zcx_rs11_salesorder_error,
      missing_header_field_raises  FOR TESTING,
      empty_items_raises           FOR TESTING,
      item_missing_material_raises FOR TESTING,
      item_zero_quantity_raises    FOR TESTING.
ENDCLASS.

CLASS ltc_validate_request IMPLEMENTATION.

  METHOD valid_request_passes.
*   given：header 五個必填欄位都有值，items（巢狀在 header 底下）有兩筆合法資料
    DATA(ls_request) = VALUE zcl_rs11_salesorder_service=>ty_create_request(
      header = VALUE #( doc_type = 'TA' sales_org = '1710' distr_chan = '10' division = '00' sold_to = '0017100002'
                         items = VALUE #( ( material = 'MZ-FG-C900' quantity = '10' unit = 'ST' )
                                          ( material = 'MZ-FG-C900' quantity = '5'  unit = 'ST' ) ) ) ).

*   when/then：不應該拋出例外
    zcl_rs11_salesorder_service=>validate_request( ls_request ).
  ENDMETHOD.

  METHOD missing_header_field_raises.
*   given：sold_to 缺值
    DATA(ls_request) = VALUE zcl_rs11_salesorder_service=>ty_create_request(
      header = VALUE #( doc_type = 'TA' sales_org = '1710' distr_chan = '10' division = '00'
                         items = VALUE #( ( material = 'MZ-FG-C900' quantity = '10' unit = 'ST' ) ) ) ).
    DATA(lv_raised) = abap_false.

*   when
    TRY.
        zcl_rs11_salesorder_service=>validate_request( ls_request ).
      CATCH zcx_rs11_salesorder_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = 'header 欄位缺值應該回 VALIDATION_FAILED' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs11_salesorder_error' ).
  ENDMETHOD.

  METHOD empty_items_raises.
*   given：header.items 空陣列
    DATA(ls_request) = VALUE zcl_rs11_salesorder_service=>ty_create_request(
      header = VALUE #( doc_type = 'TA' sales_org = '1710' distr_chan = '10' division = '00' sold_to = '0017100002' ) ).
    DATA(lv_raised) = abap_false.

*   when
    TRY.
        zcl_rs11_salesorder_service=>validate_request( ls_request ).
      CATCH zcx_rs11_salesorder_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = '空 header.items 應該回 VALIDATION_FAILED' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs11_salesorder_error' ).
  ENDMETHOD.

  METHOD item_missing_material_raises.
*   given：item 缺 material
    DATA(ls_request) = VALUE zcl_rs11_salesorder_service=>ty_create_request(
      header = VALUE #( doc_type = 'TA' sales_org = '1710' distr_chan = '10' division = '00' sold_to = '0017100002'
                         items = VALUE #( ( quantity = '10' unit = 'ST' ) ) ) ).
    DATA(lv_raised) = abap_false.

*   when
    TRY.
        zcl_rs11_salesorder_service=>validate_request( ls_request ).
      CATCH zcx_rs11_salesorder_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = 'item 缺 material 應該回 VALIDATION_FAILED' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs11_salesorder_error' ).
  ENDMETHOD.

  METHOD item_zero_quantity_raises.
*   given：item 數量是 0
    DATA(ls_request) = VALUE zcl_rs11_salesorder_service=>ty_create_request(
      header = VALUE #( doc_type = 'TA' sales_org = '1710' distr_chan = '10' division = '00' sold_to = '0017100002'
                         items = VALUE #( ( material = 'MZ-FG-C900' quantity = '0' unit = 'ST' ) ) ) ).
    DATA(lv_raised) = abap_false.

*   when
    TRY.
        zcl_rs11_salesorder_service=>validate_request( ls_request ).
      CATCH zcx_rs11_salesorder_error INTO DATA(lx_error).
        lv_raised = abap_true.
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->mv_error_code
          exp = 'VALIDATION_FAILED'
          msg = 'item 數量為 0 應該回 VALIDATION_FAILED' ).
    ENDTRY.

*   then
    cl_abap_unit_assert=>assert_true(
      act = lv_raised
      msg = '應該要拋出 zcx_rs11_salesorder_error' ).
  ENDMETHOD.

ENDCLASS.

* 測試類別 2：/UI2/CL_JSON 巢狀結構往返——header 底下同時有純量欄位跟子陣列 items（兩層巢狀）
*   這是這門課第一次出現巢狀 JSON，用往返測試驗證 CL_JSON 能正確處理，不需要真的掛 SICF 才能確認
CLASS ltc_json_roundtrip DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS: nested_structure_roundtrips FOR TESTING.
ENDCLASS.

CLASS ltc_json_roundtrip IMPLEMENTATION.

  METHOD nested_structure_roundtrips.
*   given：一個 header，底下巢狀兩筆 items
    DATA(ls_request) = VALUE zcl_rs11_salesorder_service=>ty_create_request(
      header = VALUE #( doc_type = 'TA' sales_org = '1710' distr_chan = '10' division = '00' sold_to = '0017100002'
                         items = VALUE #( ( material = 'MZ-FG-C900' quantity = '10' unit = 'ST' )
                                          ( material = 'MZ-FG-C900' quantity = '5'  unit = 'ST' ) ) ) ).

*   when：序列化成 JSON 再反序列化回來
    DATA(lv_json) = /ui2/cl_json=>serialize(
      data        = ls_request
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    DATA ls_roundtrip TYPE zcl_rs11_salesorder_service=>ty_create_request.
    /ui2/cl_json=>deserialize(
      EXPORTING
        json        = lv_json
        pretty_name = /ui2/cl_json=>pretty_mode-camel_case
      CHANGING
        data        = ls_roundtrip ).

*   then：header 欄位跟巢狀在 header 底下的 items 陣列都要正確還原
    cl_abap_unit_assert=>assert_equals(
      act = ls_roundtrip-header-sold_to
      exp = ls_request-header-sold_to
      msg = 'header 欄位應該正確還原' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_roundtrip-header-items )
      exp = 2
      msg = '巢狀在 header 底下的 items 陣列筆數應該正確還原' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_roundtrip-header-items[ 1 ]-material
      exp = 'MZ-FG-C900'
      msg = 'items 陣列內容應該正確還原' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_roundtrip-header-items[ 2 ]-quantity
      exp = ls_request-header-items[ 2 ]-quantity
      msg = 'items 陣列的數量欄位應該正確還原' ).
  ENDMETHOD.

ENDCLASS.
