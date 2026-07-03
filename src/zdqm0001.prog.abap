*&---------------------------------------------------------------------*
*& Report  ZDQM0001
*& 檢驗特性資料轉檔程式.(BDC)
*&---------------------------------------------------------------------*
REPORT ZDQM0001 message-id ZQMM01 LINE-SIZE 200.

*tables: qpmz,PLKO.
tables: QPMK.
INCLUDE ZDQM0001F01.


data: bdcdata like bdcdata  occurs 0 with header line.
data: msg like bdcmsgcoll occurs 0 with header line.
data: msgtext(120) type c.
DATA : t_code(06) TYPE c VALUE 'QS21' .

data: begin of itab occurs 0,
        plant  like QPMK-WERKS,
        insp_Char like QPMK-MKMNR,
        text   like VSKT-KURZTEXT,
        ins_type(2) type C,          " 定性 或 定量
        Search_term like QPMK-SORTFELD,
        internal_desc like QPMK-CHARACT_ID1,   " Internal description
        Char_weight like QPMK-MERKGEW,   " 特性權重
        S_proc(1) type C,    " smapling Procedure
        SPC_flag(1)  type C,    " SPC Flag
        defect_rec(1) type C,    " Defect Record Flag
        record_type(1) type C,      "記錄方式, 1-單一結果記錄, 2-簡要記錄
        Inp_control(1) type C,       "若Req char,則RQMST-RZWANG4='X',若Option char,則RZWANG1='X'
        Insp_scope(1) type C,        "PUMFKZ1 ='X'=>可多抽少抽, PUMFKZ4 ='X'=>Fixed,PUMFKZ2=>可少抽,PUMFKZ3=>多抽
        Long_Term(1) type C,         "若為長期檢驗特性,則放X,否則空白
        Qn_UNIT(6)   type C,         "定量單位
        Qn_Decno(3)  type C,         "定量小數位數
        Qn_UPP_IND(1)   type C,      "規格上限indicator
        Qn_LOWER_IND(1) type C,      "規格下限indicator
        Qn_Target_IND(1) type C,     "目標值indicator
        Qn_UPP(10)       type C,     "規格上限
        Qn_LOWER(10)     type C,     "規格下限
        Qn_TARGET(10)    type C,     "目標值
        err_msg(128)   TYPE c ,      "FOR keep error message
      end of itab.

data: err_itab like itab occurs 0 with header line.

DATA: W_FILENAME   LIKE RLGRAP-FILENAME.
DATA : total_input       LIKE sy-tabix .
DATA : total_bdc_ok      LIKE sy-tabix .
DATA : total_bdc_error   LIKE sy-tabix .
DATA : total_bdc_total   LIKE sy-tabix .



PARAMETERS: P_NAME like W_FILENAME obligatory lower case
                        default 'c:\temp\insp_char.txt'.
PARAMETERS: P_ENAME like W_FILENAME obligatory lower case
                        default 'c:\temp\inspchar_err.txt'.
parameterS: p_date LIKE sy-datum DEFAULT '20250101'.
parameterS: b_mode OBLIGATORY default 'N',
           chk_chg        AS CHECKBOX DEFAULT 'X' .  "只建立不修改

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
  refresh itab. clear itab.
  CALL FUNCTION 'WS_UPLOAD'
    EXPORTING
      CODEPAGE                      = '8300'
      FILENAME                      = p_name
      FILETYPE                      = 'DAT'
    TABLES
      DATA_TAB                      = itab
    EXCEPTIONS
      CONVERSION_ERROR              = 1
      FILE_OPEN_ERROR               = 2
      FILE_READ_ERROR               = 3
      INVALID_TYPE                  = 4
      NO_BATCH                      = 5
      UNKNOWN_ERROR                 = 6
      INVALID_TABLE_WIDTH           = 7
      GUI_REFUSE_FILETRANSFER       = 8
      CUSTOMER_ERROR                = 9
      OTHERS                        = 10.
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
data: position(3) type c.
  refresh err_itab.
  loop at itab.
   total_input = total_input + 1 .
   t_code = 'QS21' .
   SELECT SINGLE *  FROM QPMK WHERE ZAEHLER = itab-plant
                                AND MKMNR = itab-insp_Char.

   IF sy-subrc = 0.  "CHANGE
        IF chk_chg <> 'X' .
           t_code = 'QS23' .
        ENDIF.
    ENDIF.

   refresh bdcdata.
   perform append_bdc using 'X'  'SAPMQSDA'       '0100'.
   perform append_bdc using ' '  'QPMK-WERKS'    itab-plant.
   perform append_bdc using ' '  'QPMK-MKMNR'    itab-insp_Char.
   IF t_code <> 'QS23' .
      perform append_bdc using ' '  'QPMK-GUELTIGAB'    p_date.
   ENDIF.
   perform append_bdc using ' '  'BDC_OKCODE'     '/00'.
   perform append_bdc using 'X'  'SAPMQSDA'          '0101'.
   IF itab-ins_type = 'Ql'.      " 定性
      perform append_bdc using ' '  'RMQSD-QUALITAET'    'X'.
   ELSEIF itab-ins_type = 'Qn'.  "定量
      perform append_bdc using ' '  'RMQSD-QUANTITAET'    'X'.
   ENDIF.
   perform append_bdc using ' '  'QPMK-LOEKZ'         '2'.   " 檢驗特性狀態
   perform append_bdc using ' '  'VSKT-KURZTEXT'     itab-text.  " 短文
   perform append_bdc using ' '  'QPMK-SORTFELD'     itab-Search_term. "Search Term
   perform append_bdc using ' '  'QPMK-CHARACT_ID1'  itab-internal_desc. " internal description
   perform append_bdc using ' '  'QPMK-MERKGEW'      itab-Char_weight. "特性加權
*   perform append_bdc using ' '  'QPMK-KONSISTENT'   '1'.    " 固定放模型複製完全
   perform append_bdc using ' '  'QPMK-KONSISTENT'   ''.    " 改incomplete copy model
   perform append_bdc using ' '  'BDC_OKCODE'        '=MART'.

   perform append_bdc using 'X'  'SAPLQSS0'          '0100'.
   IF itab-ins_type = 'Qn'.  "定量
      IF itab-Qn_LOWER_IND = 'X'.
         perform append_bdc using ' '  'RQMST-TOLERUNTEN'    'X'.
      ENDIF.
      IF itab-Qn_UPP_IND = 'X'.
         perform append_bdc using ' '  'RQMST-TOLEROBEN'    'X'.
      ENDIF.
      IF itab-Qn_Target_IND = 'X'.
         perform append_bdc using ' '  'RQMST-SOLLPRUEF'    'X'.
      ENDIF.
   ENDIF.
   if itab-S_proc = 'V'.
      perform append_bdc using ' '  'RQMST-STICHPR'    'X'.   " 固定勾抽樣程序
   endif.
   if itab-SPC_flag = 'V'.
      perform append_bdc using ' '  'RQMST-QSPCMK'    'X'.   " 固定勾抽樣程序
   endif.
   if itab-defect_rec = 'V'.
      perform append_bdc using ' '  'RQMST-BEWFHLZHL'    'X'.   " 固定勾抽樣程序
   endif.
   IF itab-record_type = '1'.
      perform append_bdc using ' '  'RQMST-ESTUKZ3'    'X'.   " 單一結果記錄
   ELSEIF itab-record_type = '2'.
      perform append_bdc using ' '  'RQMST-ESTUKZ5'    'X'.   " 簡要記錄
   ENDIF.
   If itab-Inp_control = 'X'. " 必要或選擇特性
      perform append_bdc using ' '  'RQMST-RZWANG1'    'X'.
   else.
      perform append_bdc using ' '  'RQMST-RZWANG4'    'X'.
   endif.
   perform append_bdc using ' '  'BDC_OKCODE'        '=ENT1'.

   perform append_bdc using 'X'  'SAPLQSS0'          '0101'.
   perform append_bdc using ' '  'RQMST-DOKUKZ1'    'X'.   "無記錄文件
   Case itab-Insp_scope. "檢驗範圍(多抽少抽)
     When '1'.
        perform append_bdc using ' '  'RQMST-PUMFKZ1'    'X'.
     When '2'.
        perform append_bdc using ' '  'RQMST-PUMFKZ2'    'X'.
     When '3'.
        perform append_bdc using ' '  'RQMST-PUMFKZ3'    'X'.
     When others.
        perform append_bdc using ' '  'RQMST-PUMFKZ4'    'X'.
   Endcase.
   If itab-Long_Term = 'X'. " 長期檢驗
        perform append_bdc using ' '  'RQMST-LZEITKZ'    'X'.
   ENDIF.
   IF itab-ins_type = 'Qn'.  "定量
      perform append_bdc using ' '  'RQMST-MESSWERTE'  'X'.  "必須記錄測量值
   ENDIF.
   perform append_bdc using ' '  'RQMST-DRUCK1'    'X'.   "列印檢驗特性
   perform append_bdc using ' '  'BDC_OKCODE'        '=ENT1'.
   IF itab-ins_type = 'Qn' .  "定量
     IF t_code = 'QS21'.
      if itab-Qn_UPP_IND = 'X' OR itab-Qn_LOWER_IND = 'X'.
         perform append_bdc using 'X'  'SAPMQSDA'          '0110'.
         perform append_bdc using ' '  'BDC_OKCODE'        '=WEIT'.
      endif.
      perform append_bdc using 'X'  'SAPMQSDA'          '0108'.
      perform append_bdc using ' '  'RMQSD-MASSEINHSW'     itab-Qn_UNIT.  " 單位
      perform append_bdc using ' '  'QPMK-STELLEN'         itab-Qn_Decno.  " 小數位數
      IF itab-Qn_LOWER_IND = 'X'.
        perform append_bdc using ' '  'QFLTP-TOLERANZUN'     itab-Qn_LOWER.  " 規格下限
      ENDIF.
      IF itab-Qn_UPP_IND = 'X'.
        perform append_bdc using ' '  'QFLTP-TOLERANZOB'     itab-Qn_UPP.  " 規格上限
      ENDIF.
      IF itab-Qn_Target_IND = 'X'.
        perform append_bdc using ' '  'QFLTP-SOLLWERT'     itab-Qn_TARGET.  " 目標值
      ENDIF.
      perform append_bdc using ' '  'BDC_OKCODE'        '=WEIT'.
     ELSE.
      perform append_bdc using 'X'  'SAPMQSDA'          '0101'.
      perform append_bdc using ' '  'BDC_OKCODE'        '=QD'.
      perform append_bdc using 'X'  'SAPMQSDA'          '0108'.
      perform append_bdc using ' '  'RMQSD-MASSEINHSW'     itab-Qn_UNIT.  " 單位
      perform append_bdc using ' '  'QPMK-STELLEN'         itab-Qn_Decno.  " 小數位數
      IF itab-Qn_LOWER_IND = 'X'.
        perform append_bdc using ' '  'QFLTP-TOLERANZUN'     itab-Qn_LOWER.  " 規格下限
      ENDIF.
      IF itab-Qn_UPP_IND = 'X'.
        perform append_bdc using ' '  'QFLTP-TOLERANZOB'     itab-Qn_UPP.  " 規格上限
      ENDIF.
      IF itab-Qn_Target_IND = 'X'.
        perform append_bdc using ' '  'QFLTP-SOLLWERT'     itab-Qn_TARGET.  " 目標值
      ENDIF.
      perform append_bdc using ' '  'BDC_OKCODE'        '=WEIT'.



     ENDIF.
   ENDIF.
   perform append_bdc using 'X'  'SAPMQSDA'          '0101'.
   perform append_bdc using ' '  'BDC_OKCODE'        '=BU'.

   refresh msg.
   call transaction t_code using bdcdata mode b_mode UPDATE 'S' messages into msg.
   total_bdc_total = total_bdc_total + 1 .

    IF sy-subrc <> 0.
      total_bdc_error = total_bdc_error + 1 .
      PERFORM get_error_message.
      MOVE-CORRESPONDING itab TO err_itab.
*      LOOP AT itab INTO err_itab .
        err_itab-err_msg = msgtext .
        APPEND err_itab.  CLEAR err_itab.
*      ENDLOOP.
      REFRESH msg.
    else.
      total_bdc_ok = total_bdc_ok + 1 .
    ENDIF.

*   if sy-subrc <> 0.
*     perform get_error_message.
*     loop at itab into err_itab .
*       append err_itab.  clear err_itab.
*     endloop.
*   endif.
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
   LOOP AT msg.
    CALL FUNCTION 'RH_MESSAGE_GET'
      EXPORTING
        sprsl             = sy-langu
        arbgb             = msg-msgid
        msgnr             = msg-msgnr
        msgv1             = msg-msgv1
        msgv2             = msg-msgv2
        msgv3             = msg-msgv3
        msgv4             = msg-msgv4
      IMPORTING
        msgtext           = msgtext
      EXCEPTIONS
        message_not_found = 1
        OTHERS            = 2.
  ENDLOOP.
  REFRESH msg.

ENDFORM.                    " get_error_message
FORM get_filename.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      file_name = p_name.
ENDFORM.                    " get_filename
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
        WRITE AT  35 err_itab-insp_Char.
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
