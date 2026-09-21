CLASS zcl_ale09_ar_post DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_item,
        rblgp TYPE rseg-buzei,
        ebeln TYPE ebeln,
        ebelp TYPE ebelp,
        wrbtr TYPE bapiaccr09-amt_doccur,
      END OF ty_item,
      tt_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY,
      BEGIN OF ty_doc,
        bukrs TYPE bukrs,
        belnr TYPE rbkp-belnr,
        gjahr TYPE gjahr,
        lifnr TYPE lifre,
        waers TYPE waers,
        bldat TYPE bldat,
        budat TYPE budat,
        xblnr TYPE xblnr1,
        items TYPE tt_item,
      END OF ty_doc,
      tt_bapiacgl09 TYPE STANDARD TABLE OF bapiacgl09 WITH DEFAULT KEY,
      tt_bapiacar09 TYPE STANDARD TABLE OF bapiacar09 WITH DEFAULT KEY,
      tt_bapiaccr09 TYPE STANDARD TABLE OF bapiaccr09 WITH DEFAULT KEY,
      tt_bapiret2   TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY,
      BEGIN OF ty_bapi,
        header TYPE bapiache09,
        gl     TYPE tt_bapiacgl09,
        ar     TYPE tt_bapiacar09,
        amount TYPE tt_bapiaccr09,
      END OF ty_bapi,
      tt_edidd TYPE STANDARD TABLE OF edidd WITH DEFAULT KEY,
      BEGIN OF ty_result,
        success TYPE abap_bool,
        message TYPE string,
      END OF ty_result.

    CONSTANTS:
      c_seg_head TYPE edidd-segnam VALUE 'Z1ALE09H',
      c_seg_item TYPE edidd-segnam VALUE 'Z1ALE09I'.

    METHODS parse
      IMPORTING it_data       TYPE tt_edidd
      RETURNING VALUE(rs_doc) TYPE ty_doc
      RAISING   cx_sy_conversion_error.

    METHODS read_ctrl
      IMPORTING is_doc         TYPE ty_doc
      RETURNING VALUE(rs_ctrl) TYPE zale09_ctrl.

    METHODS build_bapi_data
      IMPORTING is_ctrl        TYPE zale09_ctrl
                is_doc         TYPE ty_doc
      RETURNING VALUE(rs_bapi) TYPE ty_bapi.

    METHODS process
      IMPORTING it_data          TYPE tt_edidd
      RETURNING VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    METHODS ref_key
      IMPORTING is_doc        TYPE ty_doc
      RETURNING VALUE(rv_ref) TYPE bkpf-xblnr.

    METHODS already_posted
      IMPORTING is_ctrl         TYPE zale09_ctrl
                is_doc          TYPE ty_doc
      RETURNING VALUE(rv_belnr) TYPE bkpf-belnr.
ENDCLASS.


CLASS zcl_ale09_ar_post IMPLEMENTATION.

  METHOD parse.
    DATA ls_head TYPE z1ale09h.
    DATA ls_item TYPE z1ale09i.

    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<ls_seg>).
      CASE <ls_seg>-segnam.
        WHEN c_seg_head.
          ls_head = <ls_seg>-sdata.
          rs_doc-bukrs = ls_head-bukrs.
          rs_doc-belnr = ls_head-re_belnr.
          rs_doc-gjahr = ls_head-gjahr.
          rs_doc-lifnr = ls_head-lifre.
          rs_doc-waers = ls_head-waers.
          rs_doc-bldat = ls_head-bldat.
          rs_doc-budat = ls_head-budat.
          rs_doc-xblnr = ls_head-xblnr1.
        WHEN c_seg_item.
          ls_item = <ls_seg>-sdata.
          APPEND VALUE #( rblgp = ls_item-rblgp
                          ebeln = ls_item-ebeln
                          ebelp = ls_item-ebelp
                          wrbtr = ls_item-wrbtr ) TO rs_doc-items.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_ctrl.
    SELECT SINGLE *
      FROM zale09_ctrl
      WHERE bukrs  = @is_doc-bukrs
        AND lifnr  = @is_doc-lifnr
        AND active = @abap_true
      INTO @rs_ctrl.
  ENDMETHOD.


  METHOD ref_key.
    rv_ref = |{ is_doc-belnr }{ is_doc-gjahr }|.
  ENDMETHOD.


  METHOD already_posted.
    SELECT SINGLE belnr
      FROM bkpf
      WHERE bukrs = @is_ctrl-bukrs_ar
        AND blart = @is_ctrl-blart_ar
        AND xblnr = @( ref_key( is_doc ) )
      INTO @rv_belnr.
  ENDMETHOD.


  METHOD build_bapi_data.
    DATA lv_total  TYPE bapiaccr09-amt_doccur.
    DATA lv_itemno TYPE posnr_acc.

    rs_bapi-header = VALUE #(
      bus_act    = 'RFBU'
      username   = sy-uname
      header_txt = |ALE09 { is_doc-bukrs }/{ is_doc-belnr }|
      comp_code  = is_ctrl-bukrs_ar
      doc_date   = is_doc-bldat
      pstng_date = is_doc-budat
      doc_type   = is_ctrl-blart_ar
      ref_doc_no = ref_key( is_doc ) ).

    LOOP AT is_doc-items ASSIGNING FIELD-SYMBOL(<ls_item>).
      lv_itemno = sy-tabix + 1.
      APPEND VALUE #( itemno_acc = lv_itemno
                      gl_account = is_ctrl-saknr
                      comp_code  = is_ctrl-bukrs_ar
                      item_text  = |PO { <ls_item>-ebeln }/{ <ls_item>-ebelp }| ) TO rs_bapi-gl.
      APPEND VALUE #( itemno_acc = lv_itemno
                      currency   = is_doc-waers
                      amt_doccur = 0 - <ls_item>-wrbtr ) TO rs_bapi-amount.
      lv_total = lv_total + <ls_item>-wrbtr.
    ENDLOOP.

    APPEND VALUE #( itemno_acc = '0000000001'
                    customer   = is_ctrl-kunnr
                    comp_code  = is_ctrl-bukrs_ar
                    item_text  = |Invoice { is_doc-belnr }/{ is_doc-gjahr }| ) TO rs_bapi-ar.
    INSERT VALUE #( itemno_acc = '0000000001'
                    currency   = is_doc-waers
                    amt_doccur = lv_total ) INTO rs_bapi-amount INDEX 1.
  ENDMETHOD.


  METHOD process.
    DATA lt_return TYPE tt_bapiret2.
    DATA lv_key    TYPE bapiache09-obj_key.

    TRY.
        DATA(ls_doc) = parse( it_data ).
      CATCH cx_sy_conversion_error.
        rs_result-message = |Invalid amount or date in IDoc|.
        RETURN.
    ENDTRY.

    IF ls_doc-belnr IS INITIAL OR ls_doc-items IS INITIAL.
      rs_result-message = |Incomplete IDoc: header or items missing|.
      RETURN.
    ENDIF.

    DATA(ls_ctrl) = read_ctrl( ls_doc ).
    IF ls_ctrl-bukrs_ar IS INITIAL.
      rs_result-message = |No active mapping for { ls_doc-bukrs }/{ ls_doc-lifnr }|.
      RETURN.
    ENDIF.

    DATA(lv_posted) = already_posted( is_ctrl = ls_ctrl is_doc = ls_doc ).
    IF lv_posted IS NOT INITIAL.
      rs_result-success = abap_true.
      rs_result-message = |Already posted as { lv_posted }|.
      RETURN.
    ENDIF.

    DATA(ls_bapi) = build_bapi_data( is_ctrl = ls_ctrl is_doc = ls_doc ).

    IF ls_ctrl-test_mode = abap_true.
      CALL FUNCTION 'BAPI_ACC_DOCUMENT_CHECK'
        EXPORTING
          documentheader    = ls_bapi-header
        TABLES
          accountgl         = ls_bapi-gl
          accountreceivable = ls_bapi-ar
          currencyamount    = ls_bapi-amount
          return            = lt_return.
    ELSE.
      CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
        EXPORTING
          documentheader    = ls_bapi-header
        IMPORTING
          obj_key           = lv_key
        TABLES
          accountgl         = ls_bapi-gl
          accountreceivable = ls_bapi-ar
          currencyamount    = ls_bapi-amount
          return            = lt_return.
    ENDIF.

    LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_return>) WHERE type CA 'EAX'.
      rs_result-message = <ls_return>-message.
      RETURN.
    ENDLOOP.

    rs_result-success = abap_true.
    IF ls_ctrl-test_mode = abap_true.
      rs_result-message = |Check OK (test mode), nothing posted|.
    ELSE.
      rs_result-message = |FI document { lv_key(10) } posted in { ls_ctrl-bukrs_ar }|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
