CLASS ltc_build_segment DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS below_limit_no_review FOR TESTING.
    METHODS at_limit_needs_review FOR TESTING.
    METHODS segment_carries_document_fields FOR TESTING.
    METHODS build_seg
      IMPORTING iv_netwr      TYPE vbdkr-netwr
      RETURNING VALUE(rs_ext) TYPE z1ale10.
ENDCLASS.


CLASS ltc_build_segment IMPLEMENTATION.

  METHOD build_seg.
    DATA(ls_seg) = zcl_ale10_invoic_ext=>build_segment(
      is_vbdkr = VALUE #( vbeln = '9000000001' vkorg = '1010' waerk = 'TWD' netwr = iv_netwr )
      is_ctrl  = VALUE #( vkorg = '1010' netwr = '10000.00' waerk = 'TWD' active = abap_true ) ).
    rs_ext = ls_seg-sdata.
  ENDMETHOD.


  METHOD below_limit_no_review.
    cl_abap_unit_assert=>assert_initial( build_seg( '9999.99' )-xfeld ).
  ENDMETHOD.


  METHOD at_limit_needs_review.
    cl_abap_unit_assert=>assert_equals( act = build_seg( '10000.00' )-xfeld exp = 'X' ).
  ENDMETHOD.


  METHOD segment_carries_document_fields.
    DATA(ls_ext) = build_seg( '12345.60' ).

    cl_abap_unit_assert=>assert_equals( act = ls_ext-vbeln_vf exp = '9000000001' ).
    cl_abap_unit_assert=>assert_equals( act = ls_ext-waerk exp = 'TWD' ).
    cl_abap_unit_assert=>assert_equals( act = condense( ls_ext-netwr ) exp = '12345.60' ).
  ENDMETHOD.

ENDCLASS.
