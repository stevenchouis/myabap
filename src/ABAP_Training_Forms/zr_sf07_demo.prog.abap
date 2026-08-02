REPORT zr_sf07_demo.

*&---------------------------------------------------------------*
*& SF07 - Smartform 呼叫端骨架示範（套表列印，中一刀連續紙）
*& 查出 ZSF_07_OVERLAY 動態產生的 Function Module 名稱，
*& 關閉對話框/預覽後動態呼叫，印出查詢與呼叫的結果供驗證。
*&---------------------------------------------------------------*

DATA: lv_fm_name    TYPE rs38l_fnam,
      ls_ctrl_param TYPE ssfctrlop,
      ls_output_opt TYPE ssfcompop.

WRITE: / 'SF07 - Smartform 呼叫端示範（套表列印）', /.

CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
  EXPORTING
    formname           = 'ZSF_07_OVERLAY'
  IMPORTING
    fm_name             = lv_fm_name
  EXCEPTIONS
    no_form             = 1
    no_function_module  = 2
    OTHERS               = 3.

WRITE: / 'SSF_FUNCTION_MODULE_NAME sy-subrc:', sy-subrc.

IF sy-subrc <> 0.
  WRITE: / '找不到表單 ZSF_07_OVERLAY 或尚未啟用，請先在 SMARTFORMS 建立並啟用。'.
  RETURN.
ENDIF.

WRITE: / '動態 Function Module 名稱:', lv_fm_name.

ls_ctrl_param-no_dialog = abap_true.
ls_ctrl_param-preview   = abap_false.

CALL FUNCTION lv_fm_name
  EXPORTING
    control_parameters = ls_ctrl_param
    output_options      = ls_output_opt
  EXCEPTIONS
    formatting_error    = 1
    internal_error       = 2
    send_error           = 3
    user_canceled        = 4
    OTHERS                = 5.

WRITE: / '呼叫 Smartform sy-subrc:', sy-subrc.

IF sy-subrc <> 0.
  WRITE: / '呼叫失敗，請檢查表單內容、Page Format 與 Output Options 設定。'.
ELSE.
  WRITE: / '呼叫成功，請列印或 Print Preview 後對照中一刀模擬紙本確認套版對齊。'.
ENDIF.
