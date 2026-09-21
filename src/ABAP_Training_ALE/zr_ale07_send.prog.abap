REPORT zr_ale07_send.

PARAMETERS p_ebeln TYPE ekko-ebeln OBLIGATORY.
PARAMETERS p_test  AS CHECKBOX DEFAULT 'X'.

START-OF-SELECTION.
  DATA(go_out) = NEW zcl_ale07_po_out( ).

  IF p_test = abap_true.
    DATA(gs_po) = go_out->read_po( p_ebeln ).
    IF gs_po-header-ebeln IS INITIAL.
      WRITE / |Purchase order { p_ebeln } not found|.
      RETURN.
    ENDIF.
    LOOP AT go_out->map_po( gs_po ) ASSIGNING FIELD-SYMBOL(<gs_seg>).
      WRITE: / <gs_seg>-segnam, <gs_seg>-sdata(60).
    ENDLOOP.
    RETURN.
  ENDIF.

  DATA(gs_result) = go_out->send( p_ebeln ).
  IF gs_result-success = abap_true.
    COMMIT WORK.
  ENDIF.
  WRITE / gs_result-message.
