REPORT zr_ale09_ctrl.

PARAMETERS p_bukrs  TYPE t001-bukrs OBLIGATORY.
PARAMETERS p_lifnr  TYPE lfa1-lifnr OBLIGATORY.
PARAMETERS p_tbukrs TYPE t001-bukrs.
PARAMETERS p_kunnr  TYPE kna1-kunnr.
PARAMETERS p_saknr  TYPE skb1-saknr.
PARAMETERS p_blart  TYPE t003-blart DEFAULT 'DR'.
PARAMETERS p_test   AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_add    RADIOBUTTON GROUP act DEFAULT 'X'.
PARAMETERS p_del    RADIOBUTTON GROUP act.

START-OF-SELECTION.
  IF p_del = abap_true.
    DELETE FROM zale09_ctrl WHERE bukrs = @p_bukrs AND lifnr = @p_lifnr.
    COMMIT WORK.
    PERFORM list_all.
    RETURN.
  ENDIF.

  SELECT SINGLE bukrs FROM t001 WHERE bukrs = @p_bukrs INTO @DATA(gv_dummy).
  IF sy-subrc <> 0.
    WRITE / |Source company code { p_bukrs } does not exist|.
    RETURN.
  ENDIF.
  SELECT SINGLE bukrs FROM t001 WHERE bukrs = @p_tbukrs INTO @gv_dummy.
  IF sy-subrc <> 0.
    WRITE / |Target company code { p_tbukrs } does not exist|.
    RETURN.
  ENDIF.
  SELECT SINGLE lifnr FROM lfa1 WHERE lifnr = @p_lifnr INTO @DATA(gv_lifnr).
  IF sy-subrc <> 0.
    WRITE / |Vendor { p_lifnr } does not exist|.
    RETURN.
  ENDIF.
  SELECT SINGLE kunnr FROM knb1 WHERE kunnr = @p_kunnr AND bukrs = @p_tbukrs INTO @DATA(gv_kunnr).
  IF sy-subrc <> 0.
    WRITE / |Customer { p_kunnr } is not maintained in { p_tbukrs }|.
    RETURN.
  ENDIF.
  SELECT SINGLE saknr FROM skb1 WHERE saknr = @p_saknr AND bukrs = @p_tbukrs INTO @DATA(gv_saknr).
  IF sy-subrc <> 0.
    WRITE / |G/L account { p_saknr } is not maintained in { p_tbukrs }|.
    RETURN.
  ENDIF.

  MODIFY zale09_ctrl FROM @( VALUE #(
    bukrs     = p_bukrs
    lifnr     = p_lifnr
    bukrs_ar  = p_tbukrs
    kunnr     = p_kunnr
    saknr     = p_saknr
    blart_ar  = p_blart
    test_mode = p_test
    active    = abap_true ) ).
  COMMIT WORK.
  PERFORM list_all.

FORM list_all.
  SELECT bukrs, lifnr, bukrs_ar, kunnr, saknr, blart_ar, test_mode, active
    FROM zale09_ctrl
    ORDER BY bukrs, lifnr
    INTO TABLE @DATA(lt_ctrl).
  WRITE / |Registered mappings: { lines( lt_ctrl ) }|.
  LOOP AT lt_ctrl ASSIGNING FIELD-SYMBOL(<ls_ctrl>).
    WRITE: / <ls_ctrl>-bukrs, <ls_ctrl>-lifnr, <ls_ctrl>-bukrs_ar, <ls_ctrl>-kunnr, <ls_ctrl>-saknr,
             <ls_ctrl>-blart_ar, <ls_ctrl>-test_mode, <ls_ctrl>-active.
  ENDLOOP.
ENDFORM.
