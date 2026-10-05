*&---------------------------------------------------------------------*
*& Report  ZR_TR21_SHLP_DEP
*& 講義 21 §3.3 驗證：選擇畫面上「先填工廠，再按倉別 F4」會不會連動
*& 四種寫法各一組欄位，每組都先填工廠 1010，再在倉別按 F4，
*& 看清單是不是只剩工廠 1010 的倉別
*&---------------------------------------------------------------------*
REPORT zr_tr21_shlp_dep.

TABLES mard.

TYPES: BEGIN OF ty_t001l,
         werks TYPE t001l-werks,
         lgort TYPE t001l-lgort,
         lgobe TYPE t001l-lgobe,
       END OF ty_t001l.

* 1) PARAMETERS 參考表格欄位（靠 MARD-LGORT 的外鍵）
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: p1_werks TYPE mard-werks,
            p1_lgort TYPE mard-lgort.
SELECTION-SCREEN END OF BLOCK b1.

* 2) SELECT-OPTIONS FOR 表格工作區欄位（TABLES mard）
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
SELECT-OPTIONS: s2_werks FOR mard-werks,
                s2_lgort FOR mard-lgort.
SELECTION-SCREEN END OF BLOCK b2.

* 3) PARAMETERS 加 MEMORY ID（SET/GET Parameter：WRK 工廠、LAG 倉別）
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-b03.
PARAMETERS: p3_werks TYPE mard-werks MEMORY ID wrk,
            p3_lgort TYPE mard-lgort MEMORY ID lag.
SELECTION-SCREEN END OF BLOCK b3.

* 4) 自己寫 F4：讀畫面上的工廠，再列出該工廠的倉別
SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-b04.
PARAMETERS: p4_werks TYPE mard-werks,
            p4_lgort TYPE mard-lgort.
SELECTION-SCREEN END OF BLOCK b4.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p4_lgort.
  PERFORM f4_lgort.

START-OF-SELECTION.
  WRITE: / '1)', p1_werks, p1_lgort.
  WRITE: / '3)', p3_werks, p3_lgort.
  WRITE: / '4)', p4_werks, p4_lgort.

*&---------------------------------------------------------------------*
*& FORM f4_lgort：倉別的自訂 F4
*& 選擇畫面的欄位值要按 Enter 才會傳進程式變數，
*& 所以按 F4 當下要用 DYNP_VALUES_READ 直接讀畫面上的工廠
*&---------------------------------------------------------------------*
FORM f4_lgort.
  DATA: lt_dynp  TYPE STANDARD TABLE OF dynpread,
        ls_dynp  TYPE dynpread,
        lv_werks TYPE t001l-werks,
        lt_t001l TYPE STANDARD TABLE OF ty_t001l.

  ls_dynp-fieldname = 'P4_WERKS'.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp
    EXCEPTIONS
      OTHERS     = 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE lt_dynp INTO ls_dynp INDEX 1.
  lv_werks = ls_dynp-fieldvalue.

  IF lv_werks IS INITIAL.
    SELECT werks lgort lgobe FROM t001l
      INTO TABLE lt_t001l
      ORDER BY werks lgort.
  ELSE.
    SELECT werks lgort lgobe FROM t001l
      INTO TABLE lt_t001l
      WHERE werks = lv_werks
      ORDER BY werks lgort.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'LGORT'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P4_LGORT'
      value_org   = 'S'
    TABLES
      value_tab   = lt_t001l
    EXCEPTIONS
      OTHERS      = 1.
ENDFORM.
