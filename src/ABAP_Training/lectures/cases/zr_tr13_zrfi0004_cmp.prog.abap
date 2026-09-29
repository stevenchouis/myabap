REPORT zr_tr13_zrfi0004_cmp NO STANDARD PAGE HEADING LINE-SIZE 255.

* 比對 ZR_TR13_ZRFI0004_ORG（原程式）與 ZR_TR13_ZRFI0004（重構版）的清單輸出
* 同一組條件各 SUBMIT 一次，清單轉成文字後逐行比較

TYPES: BEGIN OF ty_case,
         name  TYPE c LENGTH 30,
         gjahr TYPE bkpf-gjahr,
         low   TYPE bkpf-belnr,
         high  TYPE bkpf-belnr,
         post  TYPE c LENGTH 1,
         park  TYPE c LENGTH 1,
         pdel  TYPE c LENGTH 1,
       END OF ty_case.

DATA: gt_case TYPE STANDARD TABLE OF ty_case,
      gs_case TYPE ty_case,
      gt_org  TYPE list_string_table,
      gt_new  TYPE list_string_table.

START-OF-SELECTION.
  PERFORM add_case USING '2026 posted'           '2026' space        space        'X' space space.
  PERFORM add_case USING '2024 posted+park+del'  '2024' space        space        'X' 'X'   'X'.
  PERFORM add_case USING '2022 posted 49xx'      '2022' '4900000000' '4900000040' 'X' space space.
  PERFORM add_case USING '2021 posted 26 items'  '2021' '5000000094' '5000000100' 'X' space space.

  LOOP AT gt_case INTO gs_case.
    PERFORM run_org CHANGING gt_org.
    PERFORM run_new CHANGING gt_new.
    PERFORM compare.
  ENDLOOP.

FORM add_case USING p_name p_gjahr p_low p_high p_post p_park p_pdel.
  CLEAR gs_case.
  gs_case-name  = p_name.
  gs_case-gjahr = p_gjahr.
  gs_case-low   = p_low.
  gs_case-high  = p_high.
  gs_case-post  = p_post.
  gs_case-park  = p_park.
  gs_case-pdel  = p_pdel.
  APPEND gs_case TO gt_case.
ENDFORM.

FORM run_org CHANGING pt_list TYPE list_string_table.
  DATA lr_belnr TYPE RANGE OF bkpf-belnr.
  DATA ls_belnr LIKE LINE OF lr_belnr.
  IF gs_case-low IS NOT INITIAL.
    ls_belnr-sign = 'I'. ls_belnr-option = 'BT'.
    ls_belnr-low = gs_case-low. ls_belnr-high = gs_case-high.
    APPEND ls_belnr TO lr_belnr.
  ENDIF.
  SUBMIT zr_tr13_zrfi0004_org
    WITH p_bukrs  = '1000'
    WITH s_gjahr  = gs_case-gjahr
    WITH s_belnr  IN lr_belnr
    WITH c_rfb01  = gs_case-post
    WITH c_rfbv1  = gs_case-park
    WITH c_rdfbv1 = gs_case-pdel
    EXPORTING LIST TO MEMORY AND RETURN.
  PERFORM get_list CHANGING pt_list.
ENDFORM.

FORM run_new CHANGING pt_list TYPE list_string_table.
  DATA lr_belnr TYPE RANGE OF bkpf-belnr.
  DATA ls_belnr LIKE LINE OF lr_belnr.
  IF gs_case-low IS NOT INITIAL.
    ls_belnr-sign = 'I'. ls_belnr-option = 'BT'.
    ls_belnr-low = gs_case-low. ls_belnr-high = gs_case-high.
    APPEND ls_belnr TO lr_belnr.
  ENDIF.
  SUBMIT zr_tr13_zrfi0004
    WITH p_bukrs = '1000'
    WITH s_gjahr = gs_case-gjahr
    WITH s_belnr IN lr_belnr
    WITH p_post  = gs_case-post
    WITH p_park  = gs_case-park
    WITH p_pdel  = gs_case-pdel
    EXPORTING LIST TO MEMORY AND RETURN.
  PERFORM get_list CHANGING pt_list.
ENDFORM.

FORM get_list CHANGING pt_list TYPE list_string_table.
  DATA lt_abaplist TYPE STANDARD TABLE OF abaplist.
  CLEAR pt_list.
  CALL FUNCTION 'LIST_FROM_MEMORY'
    TABLES
      listobject = lt_abaplist
    EXCEPTIONS
      not_found  = 1
      OTHERS     = 2.
  IF sy-subrc = 0.
    CALL FUNCTION 'LIST_TO_ASCI'
      IMPORTING
        list_string_ascii = pt_list
      TABLES
        listobject        = lt_abaplist
      EXCEPTIONS
        OTHERS            = 1.
  ENDIF.
  CALL FUNCTION 'LIST_FREE_MEMORY'.
ENDFORM.

FORM compare.
  DATA: lv_org_n TYPE i,
        lv_new_n TYPE i,
        lv_max   TYPE i,
        lv_diff  TYPE i,
        lv_rate  TYPE i,
        lv_org   TYPE string,
        lv_new   TYPE string.

  lv_org_n = lines( gt_org ).
  lv_new_n = lines( gt_new ).
  lv_max = lv_org_n.
  IF lv_new_n > lv_max. lv_max = lv_new_n. ENDIF.

  DO lv_max TIMES.
    CLEAR: lv_org, lv_new.
    READ TABLE gt_org INTO lv_org INDEX sy-index.
    READ TABLE gt_new INTO lv_new INDEX sy-index.
    IF lv_org <> lv_new AND lv_org CS '匯率：'.
*     原程式：沒有明細的傳票匯率 0 顯示空白；新程式一律印 1.00000
      REPLACE '1.00000' WITH '       ' INTO lv_new.
      IF lv_org = lv_new.
        lv_rate = lv_rate + 1.
        CONTINUE.
      ENDIF.
    ENDIF.
    IF lv_org <> lv_new.
      lv_diff = lv_diff + 1.
      IF lv_diff <= 6.
        WRITE: / 'DIFF line', sy-index.
        WRITE: / 'ORG:', lv_org.
        WRITE: / 'NEW:', lv_new.
      ENDIF.
    ENDIF.
  ENDDO.

  WRITE: / 'CASE', gs_case-name, 'ORG lines', lv_org_n, 'NEW lines', lv_new_n, 'DIFF', lv_diff, 'RATE-ONLY', lv_rate.
ENDFORM.
