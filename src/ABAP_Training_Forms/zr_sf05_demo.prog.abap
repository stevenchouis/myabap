REPORT zr_sf05_demo.

*&---------------------------------------------------------------*
*& SF05 - Smartform 呼叫端示範（資料傳遞與動態內容）
*& 讀出 SCARR 航空公司主檔，傳進 ZSF_05_FLIGHTS 的
*& Form Interface Import 參數 IT_CARRIER，關閉對話框/預覽後呼叫。
*&---------------------------------------------------------------*

DATA: lt_carrier    TYPE STANDARD TABLE OF scarr,
      lv_fm_name    TYPE rs38l_fnam,
      ls_ctrl_param TYPE ssfctrlop,
      ls_output_opt TYPE ssfcompop.

WRITE: / 'SF05 - Smartform 呼叫端示範（資料傳遞/動態內容）', /.

SELECT * FROM scarr
  INTO TABLE lt_carrier
  UP TO 8 ROWS.

WRITE: / '從 SCARR 讀到筆數:', lines( lt_carrier ).

CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
  EXPORTING
    formname           = 'ZSF_05_FLIGHTS'
  IMPORTING
    fm_name             = lv_fm_name
  EXCEPTIONS
    no_form             = 1
    no_function_module  = 2
    OTHERS               = 3.

WRITE: / 'SSF_FUNCTION_MODULE_NAME sy-subrc:', sy-subrc.

IF sy-subrc <> 0.
  WRITE: / '找不到表單 ZSF_05_FLIGHTS 或尚未啟用，請先在 SMARTFORMS 建立並啟用。'.
  RETURN.
ENDIF.

WRITE: / '動態 Function Module 名稱:', lv_fm_name.

ls_ctrl_param-no_dialog = abap_true.
ls_ctrl_param-preview   = abap_false.

CALL FUNCTION lv_fm_name
  EXPORTING
    control_parameters = ls_ctrl_param
    output_options      = ls_output_opt
    it_carrier          = lt_carrier
  EXCEPTIONS
    formatting_error    = 1
    internal_error       = 2
    send_error           = 3
    user_canceled        = 4
    OTHERS                = 5.

WRITE: / '呼叫 Smartform sy-subrc:', sy-subrc.

IF sy-subrc <> 0.
  WRITE: / '呼叫失敗，請檢查表單內容、Form Interface 參數名稱與 Output Options 設定。'.
ELSE.
  WRITE: / '呼叫成功，請確認預覽畫面或 Spool 是否印出航空公司清單與頁碼。'.
ENDIF.
