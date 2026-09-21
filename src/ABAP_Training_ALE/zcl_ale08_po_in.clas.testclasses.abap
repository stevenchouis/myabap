CLASS ltc_po_in DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_ale08_po_in.

    METHODS setup.
    METHODS parse_maps_header_and_items FOR TESTING.
    METHODS validate_rejects_no_header FOR TESTING.
    METHODS validate_rejects_no_items FOR TESTING.
ENDCLASS.


CLASS ltc_po_in IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
  ENDMETHOD.


  METHOD parse_maps_header_and_items.
    DATA ls_head TYPE z1ale06h.
    DATA ls_item TYPE z1ale06i.
    DATA lt_data TYPE zcl_ale08_po_in=>tt_edidd.

    ls_head-ebeln = '4500000001'.
    ls_head-bukrs = '1010'.
    ls_head-elifn = '0000100001'.
    APPEND VALUE #( segnam = 'Z1ALE06H' sdata = ls_head ) TO lt_data.

    ls_item-ebelp   = '00010'.
    ls_item-matnr18 = '000000000000000021'.
    APPEND VALUE #( segnam = 'Z1ALE06I' sdata = ls_item ) TO lt_data.
    ls_item-ebelp   = '00020'.
    APPEND VALUE #( segnam = 'Z1ALE06I' sdata = ls_item ) TO lt_data.

    DATA(ls_po) = mo_cut->parse( lt_data ).

    cl_abap_unit_assert=>assert_equals( act = ls_po-ebeln exp = '4500000001' ).
    cl_abap_unit_assert=>assert_equals( act = ls_po-bukrs exp = '1010' ).
    cl_abap_unit_assert=>assert_equals( act = ls_po-lifnr exp = '0000100001' ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_po-items ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_po-items[ 2 ]-ebelp exp = '00020' ).
  ENDMETHOD.


  METHOD validate_rejects_no_header.
    DATA(lv_error) = mo_cut->validate( VALUE #( ) ).
    cl_abap_unit_assert=>assert_not_initial( lv_error ).
  ENDMETHOD.


  METHOD validate_rejects_no_items.
    DATA(lv_error) = mo_cut->validate( VALUE #( ebeln = '4500000001' bukrs = '1010' lifnr = '0000100001' ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_error exp = 'No item segment' ).
  ENDMETHOD.

ENDCLASS.
