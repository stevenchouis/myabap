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
    " EN06 補課：新建工單存檔當下（AT_SAVE），工單號碼還是暫時號碼（如 %00000000001），
    " 每次新建工單都會重新從這個暫時號碼起算，所以稽核表裡會看到不同真實工單
    " 卻共用同一個 AUFNR 的怪現象。SAP 標準機制是等真正的號碼確定後另外呼叫
    " NUMBER_SWITCH 告知「暫時號碼 -> 真實號碼」的對應，這裡把 AT_SAVE 當下
    " 寫入的暫時號碼記錄，回填成真正的工單號碼。
    " 用 werks+auart 縮小範圍，避免動到不相關的既有記錄；Client 由編譯器自動處理，
    " Open SQL 不可在 WHERE 明寫 MANDT。
    IF i_aufnr_old IS NOT INITIAL AND i_aufnr_new IS NOT INITIAL AND i_aufnr_old <> i_aufnr_new.
      UPDATE zen06_atsave_log
        SET aufnr = i_aufnr_new
        WHERE aufnr = i_aufnr_old
          AND werks = '1011'
          AND auart = 'PP71'.
    ENDIF.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~REORG_STATUS_ACTIVATE.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~REORG_STATUS_ACT_CHECK.
  endmethod.

  method IF_EX_WORKORDER_UPDATE~REORG_STATUS_REVOKE.
  endmethod.

ENDCLASS.