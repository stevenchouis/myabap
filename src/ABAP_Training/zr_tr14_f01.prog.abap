*&---------------------------------------------------------------------*
*& Include          ZR_TR14_F01
*& FORM 副程式（報表的「邏輯面」都集中在這；量大時再拆 F02、F03...）
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
FORM get_data.
  SELECT carrid, connid, fldate, seatsocc, price, currency
    INTO CORRESPONDING FIELDS OF TABLE @gt_rev
    FROM sflight
    WHERE carrid IN @s_carrid
      AND fldate IN @s_fldate.

  LOOP AT gt_rev INTO gs_rev.
    gs_rev-revenue = gs_rev-price * gs_rev-seatsocc.
    MODIFY gt_rev FROM gs_rev.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  display_data
*&---------------------------------------------------------------------*
FORM display_data.
  IF gt_rev IS INITIAL.
    WRITE / '查無資料！請確認 SFLIGHT 有資料（SAPBC_DATA_GENERATOR）'.
    RETURN.
  ENDIF.

  gv_count = 0.
  LOOP AT gt_rev INTO gs_rev.
    gv_count = gv_count + 1.
    WRITE: / gs_rev-carrid, gs_rev-connid, gs_rev-fldate,
             gs_rev-seatsocc, gs_rev-revenue CURRENCY gs_rev-currency,
             gs_rev-currency.
  ENDLOOP.
  ULINE.
  WRITE: / '合計筆數：', gv_count.
ENDFORM.