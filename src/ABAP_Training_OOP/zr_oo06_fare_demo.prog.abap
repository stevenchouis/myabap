*&---------------------------------------------------------------------*
*& Report  ZR_OO06_FARE_DEMO
*& OOP 練習 6：繼承——艙等計價（答案程式）
*&---------------------------------------------------------------------*
* 類別家族：
*   ZCL_OO06_FARE（ABSTRACT 基底：原價）
*     ├─ ZCL_OO06_FARE_ECONOMY（沿用原價）
*     └─ ZCL_OO06_FARE_BUSINESS（×2.5）
*          └─ ZCL_OO06_FARE_FIRST（再 ×1.6，FINAL）
*&---------------------------------------------------------------------*
REPORT zr_oo06_fare_demo.

START-OF-SELECTION.
  DATA(lv_base) = CONV s_price( '1000.00' ).

  DATA(go_eco)   = NEW zcl_oo06_fare_economy( ).
  DATA(go_biz)   = NEW zcl_oo06_fare_business( ).
  DATA(go_first) = NEW zcl_oo06_fare_first( ).

  WRITE / |基本票價: { lv_base }|.
  WRITE / |{ go_eco->get_cabin_name( ) }: { go_eco->calc_fare( lv_base ) }|.
  WRITE / |{ go_biz->get_cabin_name( ) }: { go_biz->calc_fare( lv_base ) }|.
  WRITE / |{ go_first->get_cabin_name( ) }: { go_first->calc_fare( lv_base ) }|.

* 實驗（打開註解看編譯錯誤）：
*  DATA(go_x) = NEW zcl_oo06_fare( ).      " ABSTRACT：抽象類別不能實例化
