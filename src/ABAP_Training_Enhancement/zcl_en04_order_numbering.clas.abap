CLASS zcl_en04_order_numbering DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS get_custom_order_number
      IMPORTING
        iv_werks      TYPE zen04_pltauart-werks
        iv_auart      TYPE zen04_pltauart-auart
        iv_fevor      TYPE zen04_rule-fevor
        iv_wempf      TYPE zen04_rule-zgrtype
      EXPORTING
        ev_aufnr      TYPE zen04_seq-aufnr
        ev_applicable TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_en04_order_numbering IMPLEMENTATION.

  METHOD get_custom_order_number.

    CLEAR: ev_aufnr, ev_applicable.

    " 只有廠別＋製令類型組合有在啟用表登記，才會啟動自訂邏輯，其餘一律 fall through 走標準取號
    SELECT SINGLE werks FROM zen04_pltauart
      INTO @DATA(lv_found)
      WHERE werks = @iv_werks
        AND auart = @iv_auart.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " 規則比對採「精確優先、萬用（*）其次」：FEVOR/ZGRTYPE 各自可以是精確值或 '*'（代表不限）
    DATA: lv_leadcode     TYPE zen04_rule-leadcode,
          lv_stnum        TYPE zen04_rule-stnum,
          lv_match_fevor  TYPE zen04_rule-fevor,
          lv_match_zgrtyp TYPE zen04_rule-zgrtype,
          lv_rule_found   TYPE abap_bool VALUE abap_false.

    SELECT SINGLE leadcode, stnum FROM zen04_rule
      INTO (@lv_leadcode, @lv_stnum)
      WHERE werks = @iv_werks AND auart = @iv_auart
        AND fevor = @iv_fevor AND zgrtype = @iv_wempf.
    IF sy-subrc = 0.
      lv_rule_found   = abap_true.
      lv_match_fevor  = iv_fevor.
      lv_match_zgrtyp = iv_wempf.
    ELSE.
      SELECT SINGLE leadcode, stnum FROM zen04_rule
        INTO (@lv_leadcode, @lv_stnum)
        WHERE werks = @iv_werks AND auart = @iv_auart
          AND fevor = @iv_fevor AND zgrtype = '*'.
      IF sy-subrc = 0.
        lv_rule_found   = abap_true.
        lv_match_fevor  = iv_fevor.
        lv_match_zgrtyp = '*'.
      ELSE.
        SELECT SINGLE leadcode, stnum FROM zen04_rule
          INTO (@lv_leadcode, @lv_stnum)
          WHERE werks = @iv_werks AND auart = @iv_auart
            AND fevor = '*' AND zgrtype = @iv_wempf.
        IF sy-subrc = 0.
          lv_rule_found   = abap_true.
          lv_match_fevor  = '*'.
          lv_match_zgrtyp = iv_wempf.
        ELSE.
          SELECT SINGLE leadcode, stnum FROM zen04_rule
            INTO (@lv_leadcode, @lv_stnum)
            WHERE werks = @iv_werks AND auart = @iv_auart
              AND fevor = '*' AND zgrtype = '*'.
          IF sy-subrc = 0.
            lv_rule_found   = abap_true.
            lv_match_fevor  = '*'.
            lv_match_zgrtyp = '*'.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_rule_found = abap_false.
      RETURN.
    ENDIF.

    DATA(lv_zyear) = sy-datum+2(2).
    DATA(lv_month) = sy-datum+4(2).
    DATA lv_zmonth TYPE c LENGTH 1.

    CASE lv_month.
      WHEN '01'. lv_zmonth = '1'.
      WHEN '02'. lv_zmonth = '2'.
      WHEN '03'. lv_zmonth = '3'.
      WHEN '04'. lv_zmonth = '4'.
      WHEN '05'. lv_zmonth = '5'.
      WHEN '06'. lv_zmonth = '6'.
      WHEN '07'. lv_zmonth = '7'.
      WHEN '08'. lv_zmonth = '8'.
      WHEN '09'. lv_zmonth = '9'.
      WHEN '10'. lv_zmonth = 'A'.
      WHEN '11'. lv_zmonth = 'B'.
      WHEN '12'. lv_zmonth = 'C'.
    ENDCASE.

    SELECT SINGLE numno FROM zen04_seq
      INTO @DATA(lv_numno)
      WHERE werks    = @iv_werks
        AND auart    = @iv_auart
        AND fevor    = @lv_match_fevor
        AND zgrtype  = @lv_match_zgrtyp
        AND leadcode = @lv_leadcode
        AND zyear    = @lv_zyear
        AND zmonth   = @lv_zmonth.

    IF sy-subrc <> 0.
      lv_numno = lv_stnum.
      ev_aufnr = |{ lv_leadcode }{ lv_zyear }{ lv_zmonth }{ lv_numno }|.

      INSERT zen04_seq FROM @( VALUE #(
        mandt    = sy-mandt
        werks    = iv_werks
        auart    = iv_auart
        fevor    = lv_match_fevor
        zgrtype  = lv_match_zgrtyp
        leadcode = lv_leadcode
        zyear    = lv_zyear
        zmonth   = lv_zmonth
        numno    = lv_numno
        aufnr    = ev_aufnr ) ).
    ELSE.
      lv_numno = lv_numno + 1.
      ev_aufnr = |{ lv_leadcode }{ lv_zyear }{ lv_zmonth }{ lv_numno }|.

      UPDATE zen04_seq SET numno = @lv_numno,
                            aufnr = @ev_aufnr
        WHERE werks    = @iv_werks
          AND auart    = @iv_auart
          AND fevor    = @lv_match_fevor
          AND zgrtype  = @lv_match_zgrtyp
          AND leadcode = @lv_leadcode
          AND zyear    = @lv_zyear
          AND zmonth   = @lv_zmonth.
    ENDIF.

    ev_applicable = abap_true.

  ENDMETHOD.

ENDCLASS.