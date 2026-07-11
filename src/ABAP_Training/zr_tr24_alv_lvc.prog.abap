*&---------------------------------------------------------------------*
*& Report  ZR_TR24_ALV_LVC
*& 練習 24：可編輯 ALV——REUSE_ALV_GRID_DISPLAY_LVC（答案程式）
*&---------------------------------------------------------------------*
*& 前提（GUI 手動）：本程式需有 GUI Status 'STANDARD'——
*&   從 SAPLKKBL 複製 STANDARD_FULLSCREEN，加 Fcode ZCONF「確認」按鈕
*& 三個教學重點：
*&   1) IS_LAYOUT_LVC-STYLEFNAME + LVC_T_STYL：
*&      Fcode ZCONF 處理後，把已確認列的 checkbox/備註反灰鎖定
*&   2) I_GRID_SETTINGS-EDT_CLL_CB = 'X'：
*&      離開已編輯儲存格當下就觸發 DATA_CHANGED（不用按 Enter）
*&   3) IT_EVENTS 掛 SLIS_EV_DATA_CHANGED → FORM DATA_CHANGED：
*&      Functional ALV 的事件回呼一律是「事件表 + FORM」，
*&      不需要（也不該）拿底層 grid 物件、不用 class/SET HANDLER
*&      （那是 cl_gui_alv_grid 的 OO 用法，留待 OOP 課）
*&---------------------------------------------------------------------*
REPORT zr_tr24_alv_lvc.

TYPES: BEGIN OF ty_row,
         sel      TYPE c LENGTH 1,          " 選取 checkbox
         carrid   TYPE scarr-carrid,
         carrname TYPE scarr-carrname,
         remark   TYPE c LENGTH 20,         " 可編輯備註
         status   TYPE c LENGTH 10,
         celltab  TYPE lvc_t_styl,          " 這一列的欄位樣式表（STYLEFNAME）
       END OF ty_row.

DATA: gt_data     TYPE STANDARD TABLE OF ty_row,
      gs_data     TYPE ty_row,
      gt_fieldcat TYPE lvc_t_fcat,
      gs_fieldcat TYPE lvc_s_fcat,
      gt_events   TYPE slis_t_event,
      gs_layout   TYPE lvc_s_layo,
      gs_glay     TYPE lvc_s_glay.

*----------------------------------------------------------------------*
* MACRO：加一欄 LVC fieldcat（對照 ex09——標題欄位是 coltext 不是 seltext_l）
*----------------------------------------------------------------------*
DEFINE mc_add_field.
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = &1.
  gs_fieldcat-coltext   = &2.
  gs_fieldcat-outputlen = &3.
  gs_fieldcat-edit      = &4.     " 'X' = 可編輯
  gs_fieldcat-checkbox  = &5.     " 'X' = 顯示成 checkbox
  APPEND gs_fieldcat TO gt_fieldcat.
END-OF-DEFINITION.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM build_alv.
  PERFORM display_alv.

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
FORM get_data.
  SELECT carrid carrname FROM scarr
    INTO CORRESPONDING FIELDS OF TABLE gt_data.
  IF sy-subrc <> 0.
    WRITE / 'SCARR 沒有資料！請先執行 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.
  gs_data-status = '未確認'.
  MODIFY gt_data FROM gs_data TRANSPORTING status WHERE status = space.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  build_alv
*&---------------------------------------------------------------------*
FORM build_alv.
* CELLTAB（樣式欄位）不放進 fieldcat——它是給 ALV 看的
  mc_add_field 'SEL'      '選'       4  'X' 'X'.
  mc_add_field 'CARRID'   '代碼'     8  ''  ''.
  mc_add_field 'CARRNAME' '公司名稱' 24 ''  ''.
  mc_add_field 'REMARK'   '備註'     20 'X' ''.
  mc_add_field 'STATUS'   '狀態'     10 ''  ''.

  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-stylefname = 'CELLTAB'.   " ★ 列級樣式：反灰控制的開關

  gs_glay-edt_cll_cb   = 'X'.         " ★ 離開已編輯儲存格 → 觸發 DATA_CHANGED

* 事件表：告訴 ALV「DATA_CHANGED 事件發生時，回呼哪個 FORM」
  APPEND VALUE #( name = slis_ev_data_changed form = 'DATA_CHANGED' )
    TO gt_events.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  display_alv
*&---------------------------------------------------------------------*
FORM display_alv.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
      i_grid_settings          = gs_glay
      is_layout_lvc            = gs_layout
      it_fieldcat_lvc          = gt_fieldcat
      it_events                = gt_events
    TABLES
      t_outtab                 = gt_data
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
    WRITE / 'ALV 顯示失敗'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  set_pf_status
*&      掛自訂工具列（含 ZCONF）
*&---------------------------------------------------------------------*
FORM set_pf_status USING pt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD' EXCLUDING pt_extab.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  data_changed
*&      IT_EVENTS 掛的回呼：離開已編輯儲存格（EDT_CLL_CB = 'X'）就觸發
*&      介面固定，第一參數是 cl_alv_changed_data_protocol 物件
*&---------------------------------------------------------------------*
FORM data_changed USING pr_data_changed TYPE REF TO cl_alv_changed_data_protocol.
  DATA ls_cell TYPE lvc_s_modi.

* mt_good_cells：這次異動的格子清單（列號 row_id／欄名 fieldname／新值 value）
  LOOP AT pr_data_changed->mt_good_cells INTO ls_cell.
    IF ls_cell-fieldname = 'REMARK' AND ls_cell-value CS '!'.
      CALL METHOD pr_data_changed->add_protocol_entry
        EXPORTING
          i_msgid     = '0K'
          i_msgty     = 'E'
          i_msgno     = '000'
          i_msgv1     = '備註不可含驚嘆號'
          i_fieldname = ls_cell-fieldname
          i_row_id    = ls_cell-row_id.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
FORM user_command USING pv_ucomm    TYPE sy-ucomm
                        ps_selfield TYPE slis_selfield.
  CASE pv_ucomm.
    WHEN 'ZCONF'.
      PERFORM confirm_selected.
      ps_selfield-refresh    = 'X'.   " 重讀內表（樣式變更才會生效）
      ps_selfield-col_stable = 'X'.
      ps_selfield-row_stable = 'X'.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  confirm_selected
*&      Fcode ZCONF：已確認列 → 狀態變更＋checkbox/備註反灰鎖定
*&---------------------------------------------------------------------*
FORM confirm_selected.
  DATA: ls_style TYPE lvc_s_styl,
        lv_count TYPE i,
        lv_msg   TYPE string.

  LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<ls_row>) WHERE sel = 'X'.
    <ls_row>-status = '已確認'.
    lv_count = lv_count + 1.

*   STYLEFNAME 的核心：往這一列的樣式表塞「欄位＋disabled」→ 反灰
    CLEAR <ls_row>-celltab.
    ls_style-fieldname = 'SEL'.
    ls_style-style     = cl_gui_alv_grid=>mc_style_disabled.
    INSERT ls_style INTO TABLE <ls_row>-celltab.
    ls_style-fieldname = 'REMARK'.
    ls_style-style     = cl_gui_alv_grid=>mc_style_disabled.
    INSERT ls_style INTO TABLE <ls_row>-celltab.
  ENDLOOP.

  IF lv_count > 0.
    lv_msg = |已確認 { lv_count } 筆，該列選取框與備註已鎖定|.
    MESSAGE lv_msg TYPE 'S'.
  ELSE.
    MESSAGE '請先勾選要確認的資料列' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
