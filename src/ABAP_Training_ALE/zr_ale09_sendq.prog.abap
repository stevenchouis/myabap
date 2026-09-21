REPORT zr_ale09_sendq.

PARAMETERS p_test AS CHECKBOX DEFAULT 'X'.

START-OF-SELECTION.
  IF p_test = abap_true.
    SELECT belnr, gjahr, bukrs, lifnr, errmsg
      FROM zale09_queue
      WHERE sent = @space
      ORDER BY belnr, gjahr
      INTO TABLE @DATA(gt_pending).
    WRITE / |Pending records: { lines( gt_pending ) }|.
    LOOP AT gt_pending ASSIGNING FIELD-SYMBOL(<gs_pending>).
      WRITE: / <gs_pending>-belnr, <gs_pending>-gjahr, <gs_pending>-bukrs, <gs_pending>-lifnr, <gs_pending>-errmsg(60).
    ENDLOOP.
    RETURN.
  ENDIF.

  DATA(go_out) = NEW zcl_ale09_miro_out( ).
  DATA(gt_result) = go_out->send_pending( ).
  COMMIT WORK.

  LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<gs_result>).
    WRITE: / <gs_result>-belnr, <gs_result>-gjahr, <gs_result>-docnum, <gs_result>-message(80).
  ENDLOOP.
