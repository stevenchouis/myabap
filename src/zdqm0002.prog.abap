*&---------------------------------------------------------------------*
*& Report  ZDQM0002
*& Data conversion program for inspection plan(BDC) - DC069
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ZDQM0002 message-id ys LINE-SIZE 200.

tables: qpmz,PLKO.
INCLUDE ZDQM0001F01.


data: bdcdata like bdcdata  occurs 0 with header line.
data: msg like bdcmsgcoll occurs 0 with header line.
data: msgtext(120) type c.

data: begin of itab occurs 0,
        plant(4) type C,
        group(8) type C,
        counter(2)  type c,
        text   like plko-KTEXT,
*        usage  like plko-VERWE,
*        VAGRP(2) type C,
        unit   like plko-PLNME,
        M_Rule(8) type C,   "Dynamic modification rule
        M_level(1) type C,  "Modification level
*        point  like plko-QKZRASTER,
        OP_no(4) type C,    "Operation no
        C_key(4) type C,    "Control key
        opdesc like plpo-LTXA1,
*        memo(1) type c,
        char_no(3) type N,   "Characteristic No
        insp   like PLMKB-VERWMERKM,
        plant_insp(4) type c,
        sample like PLMKB-STICHPRVER,
        err_msg(128)   TYPE c ,      "FOR keep error message
      end of itab.

data: err_itab like itab occurs 0 with header line.

data: begin of header occurs 0,
        plant(4) type C,
        group(8) type C,
        counter(2)  type c,
        text   like plko-KTEXT,
        usage  like plko-verwe,
        VAGRP(2) type C,
        unit   like plko-plnme,
        M_Rule(8) type C,   "Dynamic modification rule
        M_level(1) type C,  "Modification level
*        point  like plko-QKZRASTER,
      end of header.

data: begin of op occurs 0,
        plant(4) type C,
        group(8) type C,
        counter(2)  type c,
        OP_no(4) type C,    "Operation no
        C_key(4) type C,    "Control key
        opdesc like plpo-LTXA1,
      end of op.

data: begin of insp occurs 0,
        plant(4) type C,
        group(8) type C,
        counter(2)  type c,
        OP_no(4) type C,    "Operation no
        char_no(3) type N,   "Characteristic No
        insp   like PLMKB-VERWMERKM,
        plant_insp(4) type C,
        sample like PLMKB-STICHPRVER,
      end of insp.

DATA: W_FILENAME   LIKE RLGRAP-FILENAME.
data: op_count type i,
      insp_count type i.

DATA : total_input       LIKE sy-tabix .
DATA : total_bdc_ok      LIKE sy-tabix .
DATA : total_bdc_error   LIKE sy-tabix .
DATA : total_bdc_total   LIKE sy-tabix .
data: filename1 type string.

*PARAMETER: P_NAME like W_FILENAME obligatory lower case
PARAMETERS: P_NAME      LIKE rlgrap-filename OBLIGATORY
                        default 'c:\temp\INSP_PLAN.txt'.
PARAMETERS: P_ENAME like W_FILENAME obligatory lower case
                        default 'c:\temp\insp_err.txt'.
parameterS: p_date LIKE sy-datum DEFAULT '20250101'.

parameterS: b_mode OBLIGATORY default 'N'.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_name.
  PERFORM get_filename.
AT SELECTION-SCREEN.
  PERFORM check_file.

start-of-selection.
  perform load_data.
  perform process_data.

*&---------------------------------------------------------------------*
*&      Form  load_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM load_data.
  filename1 = p_name.
  refresh itab. clear itab.
    CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      FILENAME                      = filename1
      FILETYPE                      = 'ASC'
      HAS_FIELD_SEPARATOR           = 'X'
    TABLES
      DATA_TAB                      = itab
    EXCEPTIONS
      FILE_OPEN_ERROR               = 1
      FILE_READ_ERROR               = 2
      NO_BATCH                      = 3
      GUI_REFUSE_FILETRANSFER       = 4
      INVALID_TYPE                  = 5
      NO_AUTHORITY                  = 6
      UNKNOWN_ERROR                 = 7
      BAD_DATA_FORMAT               = 8
      HEADER_NOT_ALLOWED            = 9
      SEPARATOR_NOT_ALLOWED         = 10
      HEADER_TOO_LONG               = 11
      UNKNOWN_DP_ERROR              = 12
      ACCESS_DENIED                 = 13
      DP_OUT_OF_MEMORY              = 14
      DISK_FULL                     = 15
      DP_TIMEOUT                    = 16
      OTHERS                        = 17 .
*  CALL FUNCTION 'WS_UPLOAD'
*    EXPORTING
*      CODEPAGE                      = '8300'
*      FILENAME                      = p_name
*      FILETYPE                      = 'DAT'
*    TABLES
*      DATA_TAB                      = itab
*    EXCEPTIONS
*      CONVERSION_ERROR              = 1
*      FILE_OPEN_ERROR               = 2
*      FILE_READ_ERROR               = 3
*      INVALID_TYPE                  = 4
*      NO_BATCH                      = 5
*      UNKNOWN_ERROR                 = 6
*      INVALID_TABLE_WIDTH           = 7
*      GUI_REFUSE_FILETRANSFER       = 8
*      CUSTOMER_ERROR                = 9
*      OTHERS                        = 10.
  IF SY-SUBRC <> 0.
    message s999 with '資料檔不存在'.
    stop.
  ENDIF.

ENDFORM.                    " load_data

*&---------------------------------------------------------------------*
*&      Form  process_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_data.
data: position(3) type c,
      l_tabix like sy-tabix.
  SORT itab BY plant group counter op_no char_no.
  loop at itab.
    l_tabix = sy-tabix.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ITAB-group
      IMPORTING
        output = ITAB-group.
    modify itab index l_tabix TRANSPORTING group .
    move-corresponding itab to header.
    move-corresponding itab to op.
    move-corresponding itab to insp.
    collect header. clear header.
    collect op.     clear op.
    collect insp.   clear insp.
  endloop.
  refresh err_itab.
  loop at header.
   total_input = total_input + 1 .
   refresh bdcdata.
   perform append_bdc using 'X'  'SAPLCPDI'       '8010'.
   perform append_bdc using ' '  'RC27M-WERKS'    header-plant.
   perform append_bdc using ' '  'RC271-PLNNR'    header-group.
   perform append_bdc using ' '  'RC271-STTAG'    p_date.
   perform append_bdc using ' '  'BDC_OKCODE'     '/00'.
   select single * from PLKO where PLNTY = 'Q'
                               and PLNNR = header-group.
   if sy-subrc = 0.
    perform append_bdc using 'X'  'SAPLCPDI'       '1200'.
    perform append_bdc using ' '  'BDC_OKCODE'     '=ANLG'.
   endif.
   perform append_bdc using 'X'  'SAPLCPDA'       '1200'.
   perform append_bdc using ' '  'PLKOD-PLNAL'    header-counter.
   perform append_bdc using ' '  'PLKOD-KTEXT'    header-text.
*   perform append_bdc using ' '  'PLKOD-VERWE'    header-usage.
   perform append_bdc using ' '  'PLKOD-VERWE'    '5' . " 固定放 5 -IQC
   perform append_bdc using ' '  'PLKOD-STATU'    '4'.
*   perform append_bdc using ' '  'PLKOD-VAGRP'    header-VAGRP.

   perform append_bdc using ' '  'PLKOD-PLNME'    header-unit.
   PERFORM append_bdc USING ' '  'PLKOD-QDYNHEAD'    header-M_level.
   PERFORM append_bdc USING ' '  'PLKOD-QDYNREGEL'    header-M_rule.

   perform append_bdc using ' '  'BDC_OKCODE'     '=VOUE'.
   op_count = 0.
   loop at op where plant = header-plant and group = header-group
                and counter = header-counter.
    op_count = op_count + 1. position = op_count.
    if op_count = 1.
     perform append_bdc using 'X'  'SAPLCPDI'         '1400'.
     perform append_bdc using ' '  'PLPOD-STEUS(01)'  'QM01'.
     perform append_bdc using ' '  'PLPOD-LTXA1(01)'  op-opdesc.
    else.
     perform append_bdc using 'X'  'SAPLCPDI'         '1400'.
     perform append_bdc using ' '  'PLPOD-STEUS(02)'  'QM01'.
     perform append_bdc using ' '  'PLPOD-LTXA1(02)'  op-opdesc.
    endif.
    perform append_bdc using ' '  'BDC_OKCODE'        '/00'.
    perform append_bdc using 'X'  'SAPLCPDI'          '1400'.
    perform append_bdc using ' '  'BDC_OKCODE'        '=MALO'.
    perform append_bdc using 'X'  'SAPLCPDI'          '1400'.
    perform append_bdc using ' '  'RC27X-ENTRY_ACT'   position.
    perform append_bdc using ' '  'BDC_OKCODE'        '/00'.
    perform append_bdc using 'X'  'SAPLCPDI'          '1400'.
    perform append_bdc using ' '  'RC27X-FLG_SEL(01)' 'X'.
*    if op-memo <> space.
*     perform append_bdc using ' '  'BDC_OKCODE'       '=VOD1'.
*     perform append_bdc using 'X'  'SAPLCPDO'         '1200'.
*     perform append_bdc using ' '  'PLPOD-SLWID'      'Z000002'.
*     perform append_bdc using ' '  'BDC_OKCODE'       '/00'.
*     perform append_bdc using 'X'  'SAPLCPDO'         '1200'.
*     perform append_bdc using ' '  'PLPOD-USR10'      'X'.
*     perform append_bdc using ' '  'BDC_OKCODE'       '=BACK'.
*     perform append_bdc using 'X'  'SAPLCPDI'         '1400'.
*    endif.
    perform append_bdc using ' '  'BDC_OKCODE'        '=QMUE'.
    insp_count = 0.
    loop at insp where plant = op-plant and group = op-group
                                        and counter = op-counter
                                        and op_no = op-OP_no.
     insp_count = insp_count + 1. position = insp_count.
     if insp_count = 1.
      perform append_bdc using 'X'  'SAPLQPAA'             '0150'.
      perform append_bdc using ' '  'PLMKB-VERWMERKM(01)'  insp-insp.
      perform append_bdc using ' '  'PLMKB-MKVERSION(01)'  '1'.
      perform append_bdc using ' '  'PLMKB-STICHPRVER(01)' insp-sample.
     else.
      perform append_bdc using 'X'  'SAPLQPAA'             '0150'.
      perform append_bdc using ' '  'PLMKB-VERWMERKM(02)'  insp-insp.
      perform append_bdc using ' '  'PLMKB-MKVERSION(02)'  '1'.
      perform append_bdc using ' '  'PLMKB-STICHPRVER(02)' insp-sample.
     endif.
      perform append_bdc using ' '  'BDC_OKCODE'           '/00'.
      select single * from qpmz where ZAEHLER = header-plant
                                  and MKMNR = insp-insp
                                  and VERSION = '000001'
                                  and WERKPM = header-plant.
      if sy-subrc <> 0.
        qpmz-WERKPM = space.  qpmz-PMETHODE = space.
        qpmz-VERSPM = space.
      endif.
      perform append_bdc using 'X'  'SAPLQPAA'            '1501'.
      perform append_bdc using ' '  'PLMKB-MKVERSION'     '1'.
      perform append_bdc using ' '  'PLMKB-PMETHODE'      qpmz-PMETHODE.
      perform append_bdc using ' '  'PLMKB-QMTB_WERKS'    qpmz-WERKPM.
      perform append_bdc using ' '  'PLMKB-PMTVERSION'    qpmz-VERSPM.
      perform append_bdc using ' '  'BDC_OKCODE'          '=ENT1'.

     perform append_bdc using ' '  'PLMKB-QPMK_WERKS'    insp-plant_insp.
     perform append_bdc using ' '  'BDC_OKCODE'        '/00'.
     perform append_bdc using 'X'  'SAPLQPAA'          '0150'.
     perform append_bdc using ' '  'RQPAS-ENTRY_ACT'   position.
     perform append_bdc using ' '  'BDC_OKCODE'        '/00'.
    endloop.
    perform append_bdc using 'X'  'SAPLQPAA'          '0150'.
    perform append_bdc using ' '  'BDC_OKCODE'        '=QMBW'.
   endloop.
   perform append_bdc using 'X'  'SAPLCPDI'          '1400'.
   perform append_bdc using ' '  'BDC_OKCODE'        '=BU'.
   refresh msg.
   call transaction 'QP01' using bdcdata mode b_mode UPDATE 'S' messages into msg.
   total_bdc_total = total_bdc_total + 1 .

   if sy-subrc <> 0.
     total_bdc_error = total_bdc_error + 1 .
     perform get_error_message.
     loop at itab into err_itab where plant = header-plant
                                  and group = header-group
                                  and counter = header-counter.
       err_itab-err_msg = msgtext .
       append err_itab.  clear err_itab.
     endloop.
   else.
      total_bdc_ok = total_bdc_ok + 1 .
   endif.
  endloop.
  PERFORM write_error_to_screen .
  IF NOT err_itab[] IS INITIAL.
     gui_download p_ename err_itab.
  ENDIF.

*  if not err_itab[] is initial.
*    CALL FUNCTION 'WS_DOWNLOAD'
*      EXPORTING
*        FILENAME                      = P_ENAME
*        FILETYPE                      = 'DAT'
*      TABLES
*        DATA_TAB                      = err_itab.
*
*  endif.
ENDFORM.                    " process_data




FORM append_bdc using     P_SCREEN P_FIELD P_VALUE.
  clear bdcdata.
  if p_screen <> space.
    bdcdata-program = p_field.
    bdcdata-dynpro = p_value.
    bdcdata-dynbegin = 'X'.
  else.
    bdcdata-fnam = p_field.
    bdcdata-fval = p_value.
  endif.
  append bdcdata.

ENDFORM.                    " append_bdc
*&---------------------------------------------------------------------*
*&      Form  get_error_message
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_error_message.
*  loop at msg where MSGTYP <> 'S'.
   loop at msg.
    CALL FUNCTION 'RH_MESSAGE_GET'
         EXPORTING
              SPRSL             = SY-LANGU
              ARBGB             = msg-msgid
              MSGNR             = msg-msgnr
              MSGV1             = msg-msgv1
              MSGV2             = msg-msgv2
              MSGV3             = msg-msgv3
              MSGV4             = msg-msgv4
         IMPORTING
              MSGTEXT           = msgtext
         EXCEPTIONS
              MESSAGE_NOT_FOUND = 1
              OTHERS            = 2.
*  write:/ header-group , header-counter , op-opdesc, insp-insp, msgtext.
  endloop.
  refresh msg.

ENDFORM.                    " get_error_message
FORM get_filename.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      file_name = p_name.
ENDFORM.                    " get_filename
*&---------------------------------------------------------------------*
*&      Form  check_file
*&---------------------------------------------------------------------*
FORM check_file.
      IF p_name IS INITIAL.
        MESSAGE e000 WITH '請輸入上載路徑及檔案名稱!'.
      ENDIF.
*
      DATA: result TYPE i.
      CALL FUNCTION 'WS_QUERY'
        EXPORTING
          filename       = p_name
          query          = 'FE'
        IMPORTING
          return         = result
        EXCEPTIONS
          inv_query      = 1
          no_batch       = 2
          frontend_error = 3
          OTHERS         = 4.
      IF result = 0 OR sy-subrc <> 0.
        MESSAGE e000 WITH '上載檔案不存在!'.
      ENDIF.
ENDFORM.                    " check_file
FORM write_error_to_screen .
*  DATA : t_tmp LIKE t_error OCCURS 5 WITH HEADER LINE .
  DATA : INFO_msg(80)     TYPE c .
  DATA : rec_no LIKE    sy-tabix .
  WRITE AT /20 '輸入總筆數' .
  WRITE AT  40  total_input .
  WRITE AT /20 'BDC 有效筆數' .
  WRITE AT  40  total_bdc_total .
  WRITE AT /20 'BDC 成功筆數' .
  WRITE AT  40  total_bdc_ok .

  DESCRIBE TABLE err_itab LINES rec_no .
  IF rec_no GT 0 .
    WRITE AT /20 'BDC 錯誤筆數' .
    WRITE AT  40  total_bdc_error .
    SKIP 1 .
    WRITE AT /10 '檢查結果加執行錯誤清單' .
    ULINE / .
    WRITE AT  /70 '錯誤原因' .
    ULINE / .
    LOOP AT err_itab .
        WRITE AT  /10 err_itab-plant.
        WRITE AT  20 err_itab-group.
        WRITE AT  30 err_itab-counter.
        WRITE AT  35 err_itab-OP_no.
        WRITE AT  40 err_itab-insp.
        WRITE AT  50 err_itab-sample.
        WRITE AT  70  err_itab-err_msg.
    ENDLOOP .
    CONCATENATE '發現錯誤,失敗的記錄輸出至：' p_ename
                       INTO INFO_msg .
      MESSAGE i000 WITH INFO_msg .
  ELSE .
    SKIP 1 .
    WRITE 'BDC 完成！' .
  ENDIF .
ENDFORM.
