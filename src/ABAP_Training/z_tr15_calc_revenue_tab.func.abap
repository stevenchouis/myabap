FUNCTION z_tr15_calc_revenue_tab
  CHANGING
    VALUE(ct_flights) TYPE ztr15_tt_flight_rev.



* 練習 15 Part 4：CHANGING + Table Type，取代舊式的 TABLES 參數
*   CT_FLIGHTS 是「一整張表」，逐列補上 REVENUE 欄位、直接改回原表
*   跟 TABLES 的差別：可以用 ASSIGNING 直接改原表列，型別也不受
*   「flat line type」限制（見講義 15 第 3.1 節）

  LOOP AT ct_flights ASSIGNING FIELD-SYMBOL(<fs_flight>).
    <fs_flight>-revenue = <fs_flight>-price * <fs_flight>-seatsocc.
  ENDLOOP.

ENDFUNCTION.
