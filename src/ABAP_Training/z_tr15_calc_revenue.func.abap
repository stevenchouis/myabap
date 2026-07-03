FUNCTION z_tr15_calc_revenue
  IMPORTING
    VALUE(iv_price) TYPE s_price
    VALUE(iv_seatsocc) TYPE s_seatsocc
  EXPORTING
    VALUE(ev_revenue) TYPE s_price
  EXCEPTIONS
    invalid_input.



*----------------------------------------------------------------------
* 練習 15：計算航班營收
*   IMPORTING ：呼叫端「送進來」的值（票價、已售座位）
*   EXPORTING ：FM「送出去」的結果（營收）
*   EXCEPTIONS：錯誤情況丟給呼叫端決定怎麼處理
*----------------------------------------------------------------------

* 防呆：無效輸入丟例外，讓呼叫端的 sy-subrc <> 0
  IF iv_price < 0 OR iv_seatsocc < 0.
    RAISE invalid_input.
  ENDIF.

  ev_revenue = iv_price * iv_seatsocc.

ENDFUNCTION.