*&---------------------------------------------------------------------*
*& Report  ZR_TR09_ALV
*& 練習 9：Functional ALV 與 MACRO（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr09_alv.

DATA: gt_carriers TYPE STANDARD TABLE OF scarr,
      gt_fieldcat TYPE slis_t_fieldcat_alv,    " 欄位目錄（fieldcat）
      gs_fieldcat TYPE slis_fieldcat_alv.

*----------------------------------------------------------------------*
* MACRO：DEFINE ... END-OF-DEFINITION
* &1 &2 &3 是佔位參數，呼叫時依順序代入
* 用途：把「加一筆 fieldcat」這種重複程式碼縮成一行
* 注意：MACRO 無法下中斷點除錯，新程式碼用 FORM/Method 取代；
*       但舊程式常見（本專案 ZDQM0001F01 的 gui_download 就是 MACRO），
*       必須看得懂
*----------------------------------------------------------------------*
DEFINE mc_add_field.
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = &1.     " 欄位名（internal table 的欄位）
  gs_fieldcat-seltext_l = &2.     " 欄位標題
  gs_fieldcat-outputlen = &3.     " 顯示寬度
  APPEND gs_fieldcat TO gt_fieldcat.
END-OF-DEFINITION.

START-OF-SELECTION.
  SELECT * FROM scarr
    INTO TABLE gt_carriers.

  IF sy-subrc <> 0.
    WRITE / 'SCARR 沒有資料！請先執行報表 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.

* 用 MACRO 建欄位目錄：告訴 ALV 顯示哪些欄位、標題、寬度
  mc_add_field 'CARRID'   '航空公司代碼' 12.
  mc_add_field 'CARRNAME' '航空公司名稱' 24.
  mc_add_field 'CURRCODE' '幣別'         6.
  mc_add_field 'URL'      '網址'         40.

*----------------------------------------------------------------------*
* Functional ALV：呼叫標準 Function Module 顯示
* （另有 OO 寫法 cl_salv_table，留待 OOP 課程）
*----------------------------------------------------------------------*
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid       " 回呼程式：本程式自己
      it_fieldcat        = gt_fieldcat
    TABLES
      t_outtab           = gt_carriers
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
    WRITE / 'ALV 顯示失敗'.
  ENDIF.
