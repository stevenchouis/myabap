CLASS ltc_map_po DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_ale07_po_out.

    METHODS setup.
    METHODS header_first_then_items FOR TESTING.
    METHODS header_carries_key_fields FOR TESTING.
    METHODS item_carries_key_fields FOR TESTING.
ENDCLASS.


CLASS ltc_map_po IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
  ENDMETHOD.


  METHOD header_first_then_items.
    DATA(lt_data) = mo_cut->map_po( VALUE #(
      header = VALUE #( ebeln = '4500000001' bukrs = '1010' lifnr = '0000100001' )
      items  = VALUE #( ( ebelp = '00010' matnr = '000000000000000021' )
                        ( ebelp = '00020' matnr = '000000000000000022' ) ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_data ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lt_data[ 1 ]-segnam exp = 'Z1ALE06H' ).
    cl_abap_unit_assert=>assert_equals( act = lt_data[ 2 ]-segnam exp = 'Z1ALE06I' ).
    cl_abap_unit_assert=>assert_equals( act = lt_data[ 3 ]-segnam exp = 'Z1ALE06I' ).
  ENDMETHOD.


  METHOD header_carries_key_fields.
    DATA ls_head TYPE z1ale06h.

    DATA(lt_data) = mo_cut->map_po( VALUE #(
      header = VALUE #( ebeln = '4500000001' bukrs = '1010' lifnr = '0000100001' )
      items  = VALUE #( ( ebelp = '00010' matnr = '000000000000000021' ) ) ) ).

    ls_head = lt_data[ 1 ]-sdata.
    cl_abap_unit_assert=>assert_equals( act = ls_head-ebeln exp = '4500000001' ).
    cl_abap_unit_assert=>assert_equals( act = ls_head-bukrs exp = '1010' ).
    cl_abap_unit_assert=>assert_equals( act = ls_head-elifn exp = '0000100001' ).
  ENDMETHOD.


  METHOD item_carries_key_fields.
    DATA ls_item TYPE z1ale06i.

    DATA(lt_data) = mo_cut->map_po( VALUE #(
      header = VALUE #( ebeln = '4500000001' bukrs = '1010' lifnr = '0000100001' )
      items  = VALUE #( ( ebelp = '00010' matnr = '000000000000000021' ) ) ) ).

    ls_item = lt_data[ 2 ]-sdata.
    cl_abap_unit_assert=>assert_equals( act = ls_item-ebelp exp = '00010' ).
    cl_abap_unit_assert=>assert_equals( act = ls_item-matnr18 exp = '000000000000000021' ).
  ENDMETHOD.

ENDCLASS.
