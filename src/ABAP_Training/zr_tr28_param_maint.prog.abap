REPORT zr_tr28_param_maint.

PARAMETERS: p_werks TYPE ztr28_wparm-werks DEFAULT '1011' OBLIGATORY,
            p_disp  AS CHECKBOX DEFAULT ' '.  " 勾選：只要顯示，不維護

DATA: lv_actvt TYPE activ_auth.

IF p_disp = 'X'.
  lv_actvt = '03'.
ELSE.
  lv_actvt = '02'.
ENDIF.

* ---- 1. 權限檢查：這個工廠的維護/顯示權限 ----
AUTHORITY-CHECK OBJECT 'ZTR28_WERK'
  ID 'ACTVT' FIELD lv_actvt
  ID 'WERKS' FIELD p_werks.

DATA(lv_mode_text) = COND string( WHEN lv_actvt = '02' THEN '維護' ELSE '顯示' ).

IF sy-subrc <> 0.
  WRITE: / '權限不足：無法對工廠', p_werks, '執行', lv_mode_text, '（sy-subrc =', sy-subrc, '）'.
  RETURN.
ENDIF.

WRITE: / '權限檢查通過：工廠', p_werks, lv_mode_text, '模式'.

* ---- 2. 維護模式才需要上鎖（顯示不用搶鎖，允許多人同時看）----
IF lv_actvt = '02'.
  CALL FUNCTION 'ENQUEUE_EZTR28_WERKS'
    EXPORTING
      mandt          = sy-mandt
      werks          = p_werks
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  IF sy-subrc <> 0.
    WRITE: / '工廠', p_werks, '目前正被其他人維護中，請稍後再試（sy-subrc =', sy-subrc, '）'.
    RETURN.
  ENDIF.

  WRITE: / '鎖定成功，進入維護畫面（VIEW_MAINTENANCE_CALL，需 SAP GUI 互動，programrun 無法無頭驗證這一段）'.
ENDIF.

* ---- 3. 呼叫標準 Table Maintenance（SM30 底層機制），不是直接 CALL TRANSACTION 'SM30' ----
* 用 dba_sellist 帶入「WERKS = p_werks」的篩選條件，讓維護畫面只顯示這個工廠的資料，
* 不會讓通過權限檢查的使用者順便看到/改到其他工廠的列——這是跟 ZR_TR28_PARAM_LIST
* 那顆「直接 CALL TRANSACTION 'SM30'」按鈕最大的差異：那顆按鈕沒有任何篩選。
DATA: lt_sellist TYPE STANDARD TABLE OF vimsellist,
      ls_sellist TYPE vimsellist.

CLEAR ls_sellist.
ls_sellist-viewfield = 'WERKS'.
ls_sellist-operator  = 'EQ'.
ls_sellist-value     = p_werks.
ls_sellist-tabix     = 1.
APPEND ls_sellist TO lt_sellist.

CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
  EXPORTING
    action    = COND #( WHEN lv_actvt = '03' THEN 'S' ELSE 'U' )
    view_name = 'ZTR28_WPARM'
  TABLES
    dba_sellist = lt_sellist
  EXCEPTIONS
    client_reference          = 1
    foreign_lock               = 2
    invalid_action              = 3
    no_clientindependent_auth   = 4
    system_failure               = 5
    OTHERS                      = 6.

IF sy-subrc <> 0.
  WRITE: / 'VIEW_MAINTENANCE_CALL 失敗，sy-subrc =', sy-subrc.
ENDIF.

* ---- 4. 維護模式才需要解鎖 ----
IF lv_actvt = '02'.
  CALL FUNCTION 'DEQUEUE_EZTR28_WERKS'
    EXPORTING
      mandt = sy-mandt
      werks = p_werks.
  WRITE: / '已解鎖工廠', p_werks.
ENDIF.
