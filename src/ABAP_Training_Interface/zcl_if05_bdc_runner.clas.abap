CLASS zcl_if05_bdc_runner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      tt_bdcdata  TYPE STANDARD TABLE OF bdcdata WITH EMPTY KEY,
      tt_messages TYPE STANDARD TABLE OF bdcmsgcoll WITH EMPTY KEY,
      tt_text     TYPE STANDARD TABLE OF string WITH EMPTY KEY,

      BEGIN OF ty_transaction,
        tcode   TYPE sy-tcode,
        bdcdata TYPE tt_bdcdata,
      END OF ty_transaction,
      tt_transactions TYPE STANDARD TABLE OF ty_transaction WITH EMPTY KEY.

    CLASS-METHODS:
* Call Transaction Method：同步立即執行，呼叫完馬上知道成敗
      run_via_call_transaction
        IMPORTING
          iv_tcode    TYPE sy-tcode
          it_bdcdata  TYPE tt_bdcdata
          iv_mode     TYPE ctu_params-dismode DEFAULT 'N'
          iv_update   TYPE ctu_params-updmode DEFAULT 'S'
        EXPORTING
          et_messages TYPE tt_messages,

* Session Method：把多筆交易插入同一個 Batch Input Session，實際執行交給 SM35
      run_via_session
        IMPORTING
          iv_group_name   TYPE apqi-groupid
          it_transactions TYPE tt_transactions
        EXPORTING
          ev_success      TYPE abap_bool
          ev_message      TYPE string,

* 純邏輯：把 BDCMSGCOLL 轉成可讀文字，不碰資料庫／畫面，附 ABAP Unit 測試
      format_messages
        IMPORTING
          it_messages          TYPE tt_messages
        RETURNING VALUE(rt_text) TYPE tt_text.

ENDCLASS.


CLASS zcl_if05_bdc_runner IMPLEMENTATION.

  METHOD run_via_call_transaction.
    DATA lt_bdcdata TYPE TABLE OF bdcdata.

    lt_bdcdata = it_bdcdata.

    CALL TRANSACTION iv_tcode
      USING    lt_bdcdata
      MODE     iv_mode
      UPDATE   iv_update
      MESSAGES INTO et_messages.
  ENDMETHOD.

  METHOD run_via_session.
    DATA: lv_qid     TYPE apqi-qid,
          lt_bdcdata TYPE TABLE OF bdcdata.

    CLEAR: ev_success, ev_message.

    CALL FUNCTION 'BDC_OPEN_GROUP'
      EXPORTING
        client               = sy-mandt
        group                = iv_group_name
        user                 = sy-uname
        keep                 = abap_true
      IMPORTING
        qid                  = lv_qid
      EXCEPTIONS
        client_invalid       = 1
        destination_invalid  = 2
        group_invalid        = 3
        group_is_locked      = 4
        holddate_invalid     = 5
        internal_error       = 6
        queue_error          = 7
        running              = 8
        system_lock_error    = 9
        user_invalid         = 10
        OTHERS               = 11.

    IF sy-subrc <> 0.
      ev_success = abap_false.
      ev_message = |開啟 Session 失敗（sy-subrc = { sy-subrc }）|.
      RETURN.
    ENDIF.

    LOOP AT it_transactions INTO DATA(ls_transaction).
      lt_bdcdata = ls_transaction-bdcdata.

      CALL FUNCTION 'BDC_INSERT'
        EXPORTING
          tcode            = ls_transaction-tcode
        TABLES
          dynprotab        = lt_bdcdata
        EXCEPTIONS
          internal_error   = 1
          not_open         = 2
          queue_error      = 3
          tcode_invalid    = 4
          printing_invalid = 5
          posting_invalid  = 6
          OTHERS           = 7.

      IF sy-subrc <> 0.
        ev_success = abap_false.
        ev_message = |交易 { ls_transaction-tcode } 插入 Session 失敗（sy-subrc = { sy-subrc }）|.
* 就算某一筆插入失敗，仍要往下把 Session 正常關閉，不留下沒關閉的 Session
        EXIT.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'BDC_CLOSE_GROUP'
      EXCEPTIONS
        not_open    = 1
        queue_error = 2
        OTHERS      = 3.

    IF ev_message IS INITIAL.
      IF sy-subrc <> 0.
        ev_success = abap_false.
        ev_message = |關閉 Session 失敗（sy-subrc = { sy-subrc }）|.
      ELSE.
        ev_success = abap_true.
        ev_message = |Session { iv_group_name }（QID { lv_qid }）已建立，共 { lines( it_transactions ) } 筆交易，請至 SM35 處理|.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD format_messages.
    DATA lv_formatted TYPE string.

    LOOP AT it_messages INTO DATA(ls_message).
      DATA(lv_lang) = COND langu( WHEN ls_message-msgspra IS INITIAL
                                   THEN sy-langu
                                   ELSE ls_message-msgspra ).

      DATA(lv_text) = |({ ls_message-msgid } { ls_message-msgnr }) 訊息文字取不到|.
      CLEAR lv_formatted.

      CALL FUNCTION 'FORMAT_MESSAGE'
        EXPORTING
          id        = ls_message-msgid
          lang      = lv_lang
          no        = ls_message-msgnr
          v1        = ls_message-msgv1
          v2        = ls_message-msgv2
          v3        = ls_message-msgv3
          v4        = ls_message-msgv4
        IMPORTING
          msg       = lv_formatted
        EXCEPTIONS
          not_found = 1
          OTHERS    = 2.

* FORMAT_MESSAGE 找不到訊息時走 EXCEPTIONS 分支離開，MSG 這個 VALUE() 參數
* 仍然會把它內部尚未賦值的空白內容傳回來，蓋掉上面準備好的 fallback 文字，
* 所以這裡要靠 sy-subrc 明確判斷，不能只看 lv_formatted 是不是空的
      IF sy-subrc = 0.
        lv_text = lv_formatted.
      ENDIF.

      APPEND |[{ ls_message-msgtyp }] { lv_text }| TO rt_text.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
