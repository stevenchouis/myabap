CLASS ltc_ar_post DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_ale09_ar_post.

    METHODS setup.
    METHODS parse_maps_header_and_items FOR TESTING.
    METHODS bapi_data_balances_to_zero FOR TESTING.
    METHODS bapi_data_signs_and_accounts FOR TESTING.
    METHODS build_ctrl RETURNING VALUE(rs_ctrl) TYPE zale09_ctrl.
    METHODS build_doc RETURNING VALUE(rs_doc) TYPE zcl_ale09_ar_post=>ty_doc.
ENDCLASS.


CLASS ltc_ar_post IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
  ENDMETHOD.


  METHOD build_ctrl.
    rs_ctrl = VALUE #( bukrs = '1010' lifnr = '0000100001' bukrs_ar = '1100'
                       kunnr = '0000200001' saknr = '0000400000' blart_ar = 'DR' ).
  ENDMETHOD.


  METHOD build_doc.
    rs_doc = VALUE #(
      bukrs = '1010'
      belnr = '5105600123'
      gjahr = '2026'
      lifnr = '0000100001'
      waers = 'TWD'
      bldat = '20260921'
      budat = '20260921'
      items = VALUE #(
        ( rblgp = '000001' ebeln = '4500000001' ebelp = '00010' wrbtr = '100.00' )
        ( rblgp = '000002' ebeln = '4500000001' ebelp = '00020' wrbtr = '50.50' ) ) ).
  ENDMETHOD.


  METHOD parse_maps_header_and_items.
    DATA ls_head TYPE z1ale09h.
    DATA ls_item TYPE z1ale09i.
    DATA lt_data TYPE zcl_ale09_ar_post=>tt_edidd.

    ls_head-bukrs    = '1010'.
    ls_head-re_belnr = '5105600123'.
    ls_head-gjahr    = '2026'.
    ls_head-lifre    = '0000100001'.
    ls_head-waers    = 'TWD'.
    ls_head-bldat    = '20260921'.
    ls_head-budat    = '20260921'.
    APPEND VALUE #( segnam = 'Z1ALE09H' sdata = ls_head ) TO lt_data.

    ls_item-rblgp = '000001'.
    ls_item-ebeln = '4500000001'.
    ls_item-ebelp = '00010'.
    ls_item-wrbtr = '100.00'.
    APPEND VALUE #( segnam = 'Z1ALE09I' sdata = ls_item ) TO lt_data.

    DATA(ls_doc) = mo_cut->parse( lt_data ).

    cl_abap_unit_assert=>assert_equals( act = ls_doc-belnr exp = '5105600123' ).
    cl_abap_unit_assert=>assert_equals( act = ls_doc-bldat exp = CONV bldat( '20260921' ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_doc-items ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_doc-items[ 1 ]-wrbtr exp = CONV bapiaccr09-amt_doccur( '100.00' ) ).
  ENDMETHOD.


  METHOD bapi_data_balances_to_zero.
    DATA lv_sum TYPE bapiaccr09-amt_doccur.

    DATA(ls_bapi) = mo_cut->build_bapi_data( is_ctrl = build_ctrl( ) is_doc = build_doc( ) ).

    LOOP AT ls_bapi-amount ASSIGNING FIELD-SYMBOL(<ls_amount>).
      lv_sum = lv_sum + <ls_amount>-amt_doccur.
    ENDLOOP.

    cl_abap_unit_assert=>assert_equals( act = lines( ls_bapi-amount ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lv_sum exp = CONV bapiaccr09-amt_doccur( 0 ) ).
  ENDMETHOD.


  METHOD bapi_data_signs_and_accounts.
    DATA(ls_bapi) = mo_cut->build_bapi_data( is_ctrl = build_ctrl( ) is_doc = build_doc( ) ).

    cl_abap_unit_assert=>assert_equals( act = ls_bapi-header-comp_code exp = '1100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_bapi-header-ref_doc_no exp = '51056001232026' ).
    cl_abap_unit_assert=>assert_equals( act = ls_bapi-ar[ 1 ]-customer exp = '0000200001' ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_bapi-gl ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_bapi-gl[ 1 ]-gl_account exp = '0000400000' ).
    cl_abap_unit_assert=>assert_true( xsdbool( ls_bapi-amount[ 1 ]-amt_doccur > 0 ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( ls_bapi-amount[ 2 ]-amt_doccur < 0 ) ).
  ENDMETHOD.

ENDCLASS.
