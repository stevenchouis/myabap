class ZCL_EN06_WORKORDER_ATSAVE definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_WORKORDER_UPDATE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_EN06_WORKORDER_ATSAVE IMPLEMENTATION.

  method IF_EX_WORKORDER_UPDATE~AT_SAVE.
    " EN06 教學案例：只有廠別/製令類型是 1011/PP71（教學專用組合）才寫稽核記錄，
    " 其餘情況一律不做任何事，不影響真實 PM/PP/PS/PI 工單存檔
    " ⚠️ 絕對不能在這裡下 COMMIT WORK：這是別人（訂單存檔框架）的 LUW，
    "    自行 COMMIT WORK 會打斷尚未完成的交易，SAP 標準框架會主動偵測並 dump（MESSAGE_TYPE_X）
    DATA lv_logno TYPE zen06_atsave_log-logno.

    IF is_header_dialog-werks = '1011' AND is_header_dialog-auart = 'PP71'.
      SELECT SINGLE MAX( logno ) FROM zen06_atsave_log INTO @DATA(lv_max).
      lv_logno = lv_max + 1.

      INSERT zen06_atsave_log FROM @( VALUE #(
        mandt   = sy-mandt
        logno   = lv_logno
        werks   = is_header_dialog-werks
        auart   = is_header_dialog-auart
        aufnr   = is_header_dialog-aufnr
        logdate = sy-datum
        logtime = sy-uzeit ) ).
    ENDIF.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~ARCHIVE_OBJECTS.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~AT_DELETION_FROM_DATABASE.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~AT_RELEASE.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~BEFORE_UPDATE.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~CMTS_CHECK.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~INITIALIZE.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~IN_UPDATE.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~NUMBER_SWITCH.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~REORG_STATUS_ACTIVATE.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~REORG_STATUS_ACT_CHECK.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~REORG_STATUS_REVOKE.
  endmethod.

ENDCLASS.