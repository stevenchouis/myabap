CLASS zcl_ale09_miro_out DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_item,
        rblgp TYPE rseg-buzei,
        ebeln TYPE rseg-ebeln,
        ebelp TYPE rseg-ebelp,
        wrbtr TYPE rseg-wrbtr,
      END OF ty_item,
      tt_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY,
      BEGIN OF ty_doc,
        bukrs TYPE rbkp-bukrs,
        belnr TYPE rbkp-belnr,
        gjahr TYPE rbkp-gjahr,
        lifnr TYPE rbkp-lifnr,
        waers TYPE rbkp-waers,
        bldat TYPE rbkp-bldat,
        budat TYPE rbkp-budat,
        xblnr TYPE rbkp-xblnr,
        items TYPE tt_item,
      END OF ty_doc,
      tt_edidd TYPE STANDARD TABLE OF edidd WITH DEFAULT KEY,
      tt_edidc TYPE STANDARD TABLE OF edidc WITH DEFAULT KEY,
      BEGIN OF ty_result,
        belnr   TYPE rbkp-belnr,
        gjahr   TYPE rbkp-gjahr,
        success TYPE abap_bool,
        docnum  TYPE edi_docnum,
        message TYPE string,
      END OF ty_result,
      tt_result TYPE STANDARD TABLE OF ty_result WITH DEFAULT KEY.

    CONSTANTS:
      c_mestyp   TYPE edidc-mestyp VALUE 'ZALE09',
      c_idoctp   TYPE edidc-idoctp VALUE 'ZALE09_BT01',
      c_seg_head TYPE edidd-segnam VALUE 'Z1ALE09H',
      c_seg_item TYPE edidd-segnam VALUE 'Z1ALE09I'.

    CLASS-METHODS enqueue
      IMPORTING is_rbkp TYPE rbkp.

    METHODS read_doc
      IMPORTING iv_belnr      TYPE rbkp-belnr
                iv_gjahr      TYPE rbkp-gjahr
      RETURNING VALUE(rs_doc) TYPE ty_doc.

    METHODS build_idoc
      IMPORTING is_doc         TYPE ty_doc
      RETURNING VALUE(rt_data) TYPE tt_edidd.

    METHODS send_pending
      RETURNING VALUE(rt_result) TYPE tt_result.
ENDCLASS.


CLASS zcl_ale09_miro_out IMPLEMENTATION.

  METHOD enqueue.
    IF is_rbkp-stblg IS NOT INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE active
      FROM zale09_ctrl
      WHERE bukrs = @is_rbkp-bukrs
        AND lifnr = @is_rbkp-lifnr
      INTO @DATA(lv_active).
    IF sy-subrc <> 0 OR lv_active <> abap_true.
      RETURN.
    ENDIF.

    MODIFY zale09_queue FROM @( VALUE #(
      belnr = is_rbkp-belnr
      gjahr = is_rbkp-gjahr
      bukrs = is_rbkp-bukrs
      lifnr = is_rbkp-lifnr
      erdat = sy-datum
      erzet = sy-uzeit ) ).
  ENDMETHOD.


  METHOD read_doc.
    SELECT SINGLE bukrs, belnr, gjahr, lifnr, waers, bldat, budat, xblnr
      FROM rbkp
      WHERE belnr = @iv_belnr
        AND gjahr = @iv_gjahr
      INTO CORRESPONDING FIELDS OF @rs_doc.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT buzei AS rblgp, ebeln, ebelp, wrbtr
      FROM rseg
      WHERE belnr = @iv_belnr
        AND gjahr = @iv_gjahr
      ORDER BY buzei
      INTO CORRESPONDING FIELDS OF TABLE @rs_doc-items.
  ENDMETHOD.


  METHOD build_idoc.
    DATA ls_head TYPE z1ale09h.
    DATA ls_item TYPE z1ale09i.

    ls_head-bukrs    = is_doc-bukrs.
    ls_head-re_belnr = is_doc-belnr.
    ls_head-gjahr    = is_doc-gjahr.
    ls_head-lifre    = is_doc-lifnr.
    ls_head-waers    = is_doc-waers.
    ls_head-bldat    = is_doc-bldat.
    ls_head-budat    = is_doc-budat.
    ls_head-xblnr1   = is_doc-xblnr.
    APPEND VALUE #( segnam = c_seg_head sdata = ls_head ) TO rt_data.

    LOOP AT is_doc-items ASSIGNING FIELD-SYMBOL(<ls_item>).
      CLEAR ls_item.
      ls_item-rblgp = <ls_item>-rblgp.
      ls_item-ebeln = <ls_item>-ebeln.
      ls_item-ebelp = <ls_item>-ebelp.
      ls_item-wrbtr = |{ <ls_item>-wrbtr DECIMALS = 2 }|.
      APPEND VALUE #( segnam = c_seg_item sdata = ls_item ) TO rt_data.
    ENDLOOP.
  ENDMETHOD.


  METHOD send_pending.
    DATA lt_comm TYPE tt_edidc.

    SELECT belnr, gjahr
      FROM zale09_queue
      WHERE sent = @space
      ORDER BY belnr, gjahr
      INTO TABLE @DATA(lt_queue).

    LOOP AT lt_queue ASSIGNING FIELD-SYMBOL(<ls_queue>).
      DATA(ls_res) = VALUE ty_result( belnr = <ls_queue>-belnr gjahr = <ls_queue>-gjahr ).

      DATA(ls_doc) = read_doc( iv_belnr = <ls_queue>-belnr iv_gjahr = <ls_queue>-gjahr ).
      IF ls_doc-belnr IS INITIAL.
        ls_res-message = |Invoice document not found|.
        APPEND ls_res TO rt_result.
        CONTINUE.
      ENDIF.

      DATA(lt_data) = build_idoc( ls_doc ).
      CLEAR lt_comm.

      CALL FUNCTION 'MASTER_IDOC_DISTRIBUTE'
        EXPORTING
          master_idoc_control            = VALUE edidc( mestyp = c_mestyp idoctp = c_idoctp )
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
        ls_res-message = |MASTER_IDOC_DISTRIBUTE failed, sy-subrc { sy-subrc }|.
      ELSEIF lt_comm IS INITIAL.
        ls_res-message = |No receiver determined, check BD64 model for { c_mestyp }|.
      ELSE.
        ls_res-success = abap_true.
        ls_res-docnum  = lt_comm[ 1 ]-docnum.
        ls_res-message = |IDoc { ls_res-docnum } created|.
      ENDIF.

      IF ls_res-success = abap_true.
        UPDATE zale09_queue
          SET docnum = @ls_res-docnum,
              sent   = @abap_true,
              errmsg = @space
          WHERE belnr = @ls_res-belnr
            AND gjahr = @ls_res-gjahr.
      ELSE.
        UPDATE zale09_queue
          SET errmsg = @ls_res-message
          WHERE belnr = @ls_res-belnr
            AND gjahr = @ls_res-gjahr.
      ENDIF.
      APPEND ls_res TO rt_result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
