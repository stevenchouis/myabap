ENHANCEMENT 1  .
* EN04 教學案例：Implicit Enhancement Point 客製化工單自動給號
* 只有 ZEN04_PLTAUART 登記啟用的廠別/製令類型，才會用自訂編號取代標準 Number Range 取號
  DATA: lv_wempf       TYPE zen04_rule-zgrtype,
        lv_aufnr        TYPE zen04_seq-aufnr,
        lv_applicable   TYPE abap_bool.
  FIELD-SYMBOLS: <fs_wempf> TYPE any.

  IF object = 'AUFTRAG'.

    ASSIGN ('(SAPLCOKO1)AFPOD-WEMPF') TO <fs_wempf>.
    IF sy-subrc = 0.
      lv_wempf = <fs_wempf>.
    ENDIF.

    CALL METHOD zcl_en04_order_numbering=>get_custom_order_number
      EXPORTING
        iv_werks      = caufvd-werks
        iv_auart      = caufvd-auart
        iv_fevor      = caufvd-fevor
        iv_wempf      = lv_wempf
      IMPORTING
        ev_aufnr      = lv_aufnr
        ev_applicable = lv_applicable.

    IF lv_applicable = abap_true.
      caufvd-aufnr     = lv_aufnr.
      caufvd_exp-aufnr = lv_aufnr.
      EXIT.
    ENDIF.

  ENDIF.
ENDENHANCEMENT.
