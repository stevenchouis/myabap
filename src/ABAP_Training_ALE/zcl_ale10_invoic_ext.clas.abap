CLASS zcl_ale10_invoic_ext DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES tt_edidd TYPE STANDARD TABLE OF edidd WITH DEFAULT KEY.

    CONSTANTS:
      c_cimtype  TYPE edidc-cimtyp VALUE 'ZALE10_INVEXT',
      c_seg_head TYPE edidd-segnam VALUE 'E1EDK01',
      c_seg_ext  TYPE edidd-segnam VALUE 'Z1ALE10'.

    CLASS-METHODS get_ctrl
      IMPORTING iv_vkorg        TYPE vkorg
      RETURNING VALUE(rs_ctrl)  TYPE zale10_ctrl.

    CLASS-METHODS build_segment
      IMPORTING is_vbdkr      TYPE vbdkr
                is_ctrl       TYPE zale10_ctrl
      RETURNING VALUE(rs_seg) TYPE edidd.

    CLASS-METHODS fill_control
      IMPORTING is_vbdkr   TYPE vbdkr
      CHANGING  cs_control TYPE edidc.

    CLASS-METHODS fill_segment
      IMPORTING is_vbdkr     TYPE vbdkr
      CHANGING  ct_idoc_data TYPE tt_edidd.
ENDCLASS.


CLASS zcl_ale10_invoic_ext IMPLEMENTATION.

  METHOD get_ctrl.
    SELECT SINGLE *
      FROM zale10_ctrl
      WHERE vkorg  = @iv_vkorg
        AND active = @abap_true
      INTO @rs_ctrl.
  ENDMETHOD.


  METHOD build_segment.
    DATA ls_ext TYPE z1ale10.

    ls_ext-vbeln_vf = is_vbdkr-vbeln.
    ls_ext-netwr    = |{ is_vbdkr-netwr DECIMALS = 2 }|.
    ls_ext-waerk    = is_vbdkr-waerk.
    IF is_vbdkr-netwr >= is_ctrl-netwr.
      ls_ext-xfeld = abap_true.
    ENDIF.

    rs_seg = VALUE #( segnam = c_seg_ext sdata = ls_ext ).
  ENDMETHOD.


  METHOD fill_control.
    IF is_vbdkr IS INITIAL.
      RETURN.
    ENDIF.

    DATA(ls_ctrl) = get_ctrl( is_vbdkr-vkorg ).
    IF ls_ctrl IS INITIAL.
      RETURN.
    ENDIF.

    cs_control-cimtyp = c_cimtype.
  ENDMETHOD.


  METHOD fill_segment.
    DATA(ls_ctrl) = get_ctrl( is_vbdkr-vkorg ).
    IF ls_ctrl IS INITIAL.
      RETURN.
    ENDIF.

    READ TABLE ct_idoc_data WITH KEY segnam = c_seg_head TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DATA(lv_index) = sy-tabix + 1.

    DATA(ls_seg) = build_segment( is_vbdkr = is_vbdkr is_ctrl = ls_ctrl ).
    INSERT ls_seg INTO ct_idoc_data INDEX lv_index.
  ENDMETHOD.

ENDCLASS.
