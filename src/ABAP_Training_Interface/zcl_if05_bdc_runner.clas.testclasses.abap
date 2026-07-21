CLASS ltc_format_messages DEFINITION FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      empty_input_returns_empty FOR TESTING,
      known_message_is_formatted FOR TESTING,
      unknown_message_falls_back FOR TESTING.

ENDCLASS.


CLASS ltc_format_messages IMPLEMENTATION.

  METHOD empty_input_returns_empty.
    DATA lt_messages TYPE zcl_if05_bdc_runner=>tt_messages.

    DATA(lt_result) = zcl_if05_bdc_runner=>format_messages( lt_messages ).

    cl_abap_unit_assert=>assert_initial( lt_result ).
  ENDMETHOD.

  METHOD known_message_is_formatted.
* 兩筆不同型別的訊息，驗證輸出筆數與順序都跟輸入一致，且型別標籤正確——
* 不去斷言 SAP 標準訊息的實際文字內容（那會綁死在特定系統/語言的 T100 資料上），
* 只驗證這支方法自己的轉換邏輯（順序、筆數、型別標籤）
    DATA(lt_messages) = VALUE zcl_if05_bdc_runner=>tt_messages(
      ( msgtyp = 'E' msgspra = 'E' msgid = '00' msgnr = '001' msgv1 = 'AAA' msgv2 = 'BBB' msgv3 = 'CCC' msgv4 = 'DDD' )
      ( msgtyp = 'W' msgspra = 'E' msgid = '00' msgnr = '001' msgv1 = 'EEE' msgv2 = 'FFF' msgv3 = 'GGG' msgv4 = 'HHH' ) ).

    DATA(lt_result) = zcl_if05_bdc_runner=>format_messages( lt_messages ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_result )
      exp = 2 ).
    cl_abap_unit_assert=>assert_char_cp(
      act = lt_result[ 1 ]
      exp = '[E]*' ).
    cl_abap_unit_assert=>assert_char_cp(
      act = lt_result[ 2 ]
      exp = '[W]*' ).
  ENDMETHOD.

  METHOD unknown_message_falls_back.
* 訊息類別 'ZZ' 經 T100 查證在這套系統完全不存在（SELECT COUNT 為 0），
* 用來確保觸發 FORMAT_MESSAGE 的 NOT_FOUND 例外路徑，
* 驗證 format_messages 自己準備的 fallback 文字有沒有正確保留下來
    DATA(lt_messages) = VALUE zcl_if05_bdc_runner=>tt_messages(
      ( msgtyp = 'E' msgspra = 'E' msgid = 'ZZ' msgnr = '001' ) ).

    DATA(lt_result) = zcl_if05_bdc_runner=>format_messages( lt_messages ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_result )
      exp = 1 ).
    cl_abap_unit_assert=>assert_char_cp(
      act = lt_result[ 1 ]
      exp = '*訊息文字取不到*' ).
  ENDMETHOD.

ENDCLASS.
