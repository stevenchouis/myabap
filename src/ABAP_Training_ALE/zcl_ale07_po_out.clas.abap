CLASS zcl_ale07_po_out DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_po_header,
        ebeln TYPE ebeln,
        bukrs TYPE bukrs,
        lifnr TYPE elifn,
      END OF ty_po_header,
      BEGIN OF ty_po_item,
        ebelp TYPE ebelp,
        matnr TYPE matnr,
      END OF ty_po_item,
      tt_po_item TYPE STANDARD TABLE OF ty_po_item WITH DEFAULT KEY,
      BEGIN OF ty_po,
        header TYPE ty_po_header,
        items  TYPE tt_po_item,
      END OF ty_po,
      tt_edidd TYPE STANDARD TABLE OF edidd WITH DEFAULT KEY,
      tt_edidc TYPE STANDARD TABLE OF edidc WITH DEFAULT KEY,
      BEGIN OF ty_result,
        success TYPE abap_bool,
        docnum  TYPE edi_docnum,
        message TYPE string,
      END OF ty_result.

    CONSTANTS:
      c_mestyp   TYPE edidc-mestyp VALUE 'ZALE06',
      c_idoctp   TYPE edidc-idoctp VALUE 'ZALE06_BT01',
      c_seg_head TYPE edidd-segnam VALUE 'Z1ALE06H',
      c_seg_item TYPE edidd-segnam VALUE 'Z1ALE06I'.

    METHODS read_po
      IMPORTING iv_ebeln     TYPE ebeln
      RETURNING VALUE(rs_po) TYPE ty_po.

    METHODS map_po
      IMPORTING is_po          TYPE ty_po
      RETURNING VALUE(rt_data) TYPE tt_edidd.

    METHODS send
      IMPORTING iv_ebeln         TYPE ebeln
      RETURNING VALUE(rs_result) TYPE ty_result.
ENDCLASS.


CLASS zcl_ale07_po_out IMPLEMENTATION.

  METHOD read_po.
    SELECT SINGLE ebeln, bukrs, lifnr
      FROM ekko
      WHERE ebeln = @iv_ebeln
      INTO CORRESPONDING FIELDS OF @rs_po-header.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT ebelp, matnr
      FROM ekpo
      WHERE ebeln = @iv_ebeln
        AND loekz = @space
      ORDER BY ebelp
      INTO CORRESPONDING FIELDS OF TABLE @rs_po-items.
  ENDMETHOD.


  METHOD map_po.
    DATA ls_head TYPE z1ale06h.
    DATA ls_item TYPE z1ale06i.

    ls_head-ebeln = is_po-header-ebeln.
    ls_head-bukrs = is_po-header-bukrs.
    ls_head-elifn = is_po-header-lifnr.
    APPEND VALUE #( segnam = c_seg_head sdata = ls_head ) TO rt_data.

    LOOP AT is_po-items ASSIGNING FIELD-SYMBOL(<ls_item>).
      CLEAR ls_item.
      ls_item-ebelp   = <ls_item>-ebelp.
      ls_item-matnr18 = <ls_item>-matnr.
      APPEND VALUE #( segnam = c_seg_item sdata = ls_item ) TO rt_data.
    ENDLOOP.
  ENDMETHOD.


  METHOD send.
    DATA lt_comm TYPE tt_edidc.

    DATA(ls_po) = read_po( iv_ebeln ).
    IF ls_po-header-ebeln IS INITIAL.
      rs_result-message = |Purchase order { iv_ebeln } not found|.
      RETURN.
    ENDIF.
    IF ls_po-items IS INITIAL.
      rs_result-message = |Purchase order { iv_ebeln } has no items|.
      RETURN.
    ENDIF.

    DATA(ls_control) = VALUE edidc( mestyp = c_mestyp idoctp = c_idoctp ).
    DATA(lt_data) = map_po( ls_po ).

    CALL FUNCTION 'MASTER_IDOC_DISTRIBUTE'
      EXPORTING
        master_idoc_control            = ls_control
      TABLES
        communication_idoc_control     = lt_comm
        master_idoc_data               = lt_data
      EXCEPTIONS
        error_in_idoc_control          = 1
        error_writing_idoc_status      = 2
        error_in_idoc_data             = 3
        sending_logical_system_unknown = 4
        OTHERS                         = 5.
    IF sy-subrc <> 0.
      rs_result-message = |MASTER_IDOC_DISTRIBUTE failed, sy-subrc { sy-subrc }|.
      RETURN.
    ENDIF.

    IF lt_comm IS INITIAL.
      rs_result-message = |No receiver determined, check BD64 model for { c_mestyp }|.
      RETURN.
    ENDIF.

    rs_result-success = abap_true.
    rs_result-docnum  = lt_comm[ 1 ]-docnum.
    rs_result-message = |IDoc { rs_result-docnum } created, caller must COMMIT WORK|.
  ENDMETHOD.

ENDCLASS.
