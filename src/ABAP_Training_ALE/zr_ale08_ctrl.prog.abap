REPORT zr_ale08_ctrl.

PARAMETERS p_bukrs TYPE t001-bukrs OBLIGATORY.
PARAMETERS p_add   RADIOBUTTON GROUP act DEFAULT 'X'.
PARAMETERS p_del   RADIOBUTTON GROUP act.

START-OF-SELECTION.
  IF p_add = abap_true.
    MODIFY zale08_ctrl FROM @( VALUE #( bukrs = p_bukrs ) ).
  ELSE.
    DELETE FROM zale08_ctrl WHERE bukrs = @p_bukrs.
  ENDIF.
  COMMIT WORK.

  SELECT bukrs FROM zale08_ctrl ORDER BY bukrs INTO TABLE @DATA(gt_ctrl).
  WRITE / |Registered company codes: { lines( gt_ctrl ) }|.
  LOOP AT gt_ctrl ASSIGNING FIELD-SYMBOL(<gs_ctrl>).
    WRITE / <gs_ctrl>-bukrs.
  ENDLOOP.
