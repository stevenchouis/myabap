CLASS ltc_build_idoc DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_ale09_miro_out.

    METHODS setup.
    METHODS header_then_items FOR TESTING.
    METHODS header_carries_invoice_key FOR TESTING.
    METHODS item_amount_is_text_with_decimals FOR TESTING.
    METHODS build_doc RETURNING VALUE(rs_doc) TYPE zcl_ale09_miro_out=>ty_doc.
ENDCLASS.


CLASS ltc_build_idoc IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
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
      xblnr = 'INV-001'
      items = VALUE #(
        ( rblgp = '000001' ebeln = '4500000001' ebelp = '00010' wrbtr = '100.00' )
        ( rblgp = '000002' ebeln = '4500000001' ebelp = '00020' wrbtr = '50.5' ) ) ).
  ENDMETHOD.


  METHOD header_then_items.
    DATA(lt_data) = mo_cut->build_idoc( build_doc( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_data ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lt_data[ 1 ]-segnam exp = 'Z1ALE09H' ).
    cl_abap_unit_assert=>assert_equals( act = lt_data[ 2 ]-segnam exp = 'Z1ALE09I' ).
    cl_abap_unit_assert=>assert_equals( act = lt_data[ 3 ]-segnam exp = 'Z1ALE09I' ).
  ENDMETHOD.


  METHOD header_carries_invoice_key.
    DATA ls_head TYPE z1ale09h.

    DATA(lt_data) = mo_cut->build_idoc( build_doc( ) ).
    ls_head = lt_data[ 1 ]-sdata.

    cl_abap_unit_assert=>assert_equals( act = ls_head-bukrs exp = '1010' ).
    cl_abap_unit_assert=>assert_equals( act = ls_head-re_belnr exp = '5105600123' ).
    cl_abap_unit_assert=>assert_equals( act = ls_head-gjahr exp = '2026' ).
    cl_abap_unit_assert=>assert_equals( act = ls_head-waers exp = 'TWD' ).
  ENDMETHOD.


  METHOD item_amount_is_text_with_decimals.
    DATA ls_item TYPE z1ale09i.

    DATA(lt_data) = mo_cut->build_idoc( build_doc( ) ).

    ls_item = lt_data[ 2 ]-sdata.
    cl_abap_unit_assert=>assert_equals( act = condense( ls_item-wrbtr ) exp = '100.00' ).
    ls_item = lt_data[ 3 ]-sdata.
    cl_abap_unit_assert=>assert_equals( act = condense( ls_item-wrbtr ) exp = '50.50' ).
  ENDMETHOD.

ENDCLASS.
