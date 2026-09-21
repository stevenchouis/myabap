CLASS zcl_ale08_po_in DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_item,
        ebelp TYPE ebelp,
        matnr TYPE matnr,
      END OF ty_item,
      tt_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY,
      BEGIN OF ty_po,
        ebeln TYPE ebeln,
        bukrs TYPE bukrs,
        lifnr TYPE elifn,
        items TYPE tt_item,
      END OF ty_po,
      tt_edidd TYPE STANDARD TABLE OF edidd WITH DEFAULT KEY,
      tt_log   TYPE STANDARD TABLE OF zale08_polog WITH DEFAULT KEY,
      BEGIN OF ty_result,
        success TYPE abap_bool,
        message TYPE string,
      END OF ty_result.

    CONSTANTS:
      c_seg_head TYPE edidd-segnam VALUE 'Z1ALE06H',
      c_seg_item TYPE edidd-segnam VALUE 'Z1ALE06I'.

    METHODS parse
      IMPORTING it_data      TYPE tt_edidd
      RETURNING VALUE(rs_po) TYPE ty_po.

    METHODS validate
      IMPORTING is_po           TYPE ty_po
      RETURNING VALUE(rv_error) TYPE string.

    METHODS process
      IMPORTING iv_docnum        TYPE edi_docnum
                it_data          TYPE tt_edidd
      RETURNING VALUE(rs_result) TYPE ty_result.
ENDCLASS.


CLASS zcl_ale08_po_in IMPLEMENTATION.

  METHOD parse.
    DATA ls_head TYPE z1ale06h.
    DATA ls_item TYPE z1ale06i.

    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<ls_seg>).
      CASE <ls_seg>-segnam.
        WHEN c_seg_head.
          ls_head = <ls_seg>-sdata.
          rs_po-ebeln = ls_head-ebeln.
          rs_po-bukrs = ls_head-bukrs.
          rs_po-lifnr = ls_head-elifn.
        WHEN c_seg_item.
          ls_item = <ls_seg>-sdata.
          APPEND VALUE #( ebelp = ls_item-ebelp matnr = ls_item-matnr18 ) TO rs_po-items.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD validate.
    IF is_po-ebeln IS INITIAL.
      rv_error = |No header segment|.
      RETURN.
    ENDIF.

    IF is_po-items IS INITIAL.
      rv_error = |No item segment|.
      RETURN.
    ENDIF.

    SELECT SINGLE bukrs FROM t001
      WHERE bukrs = @is_po-bukrs
      INTO @DATA(lv_bukrs).
    IF sy-subrc <> 0.
      rv_error = |Company code { is_po-bukrs } does not exist|.
      RETURN.
    ENDIF.

    SELECT SINGLE bukrs FROM zale08_ctrl
      WHERE bukrs = @is_po-bukrs
      INTO @lv_bukrs.
    IF sy-subrc <> 0.
      rv_error = |Company code { is_po-bukrs } not registered|.
      RETURN.
    ENDIF.

    SELECT SINGLE lifnr FROM lfa1
      WHERE lifnr = @is_po-lifnr
      INTO @DATA(lv_lifnr).
    IF sy-subrc <> 0.
      rv_error = |Vendor { is_po-lifnr } does not exist|.
    ENDIF.
  ENDMETHOD.


  METHOD process.
    DATA(ls_po) = parse( it_data ).

    DATA(lv_error) = validate( ls_po ).
    IF lv_error IS NOT INITIAL.
      rs_result-message = lv_error.
      RETURN.
    ENDIF.

    DATA(lt_log) = VALUE tt_log(
      FOR ls_item IN ls_po-items
      ( docnum = iv_docnum
        ebeln  = ls_po-ebeln
        ebelp  = ls_item-ebelp
        matnr  = ls_item-matnr
        bukrs  = ls_po-bukrs
        lifnr  = ls_po-lifnr
        erdat  = sy-datum
        erzet  = sy-uzeit ) ).
    MODIFY zale08_polog FROM TABLE @lt_log.

    rs_result-success = abap_true.
    rs_result-message = |PO { ls_po-ebeln } logged, { lines( ls_po-items ) } items|.
  ENDMETHOD.

ENDCLASS.
