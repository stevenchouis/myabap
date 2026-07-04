*&---------------------------------------------------------------------*
*& Report  ZR_OO08_POLY_DEMO
*& OOP 練習 8：多型與轉型（答案程式）
*&---------------------------------------------------------------------*
* 沿用 op06 的艙等家族 + op08 新增的 ZCL_OO08_FARE_GROUP（團體票）
* 重點：
*   1. 多型迴圈——同一行程式碼，跑的是「物件真實類別」的版本
*   2. IS INSTANCE OF + CAST——向下轉型才能用子類別專屬方法
*   3. CASE TYPE OF——依真實類別分流
*&---------------------------------------------------------------------*
REPORT zr_oo08_poly_demo.

START-OF-SELECTION.
  DATA(lv_base) = CONV s_price( '1000.00' ).

* 子類別參考時期：專屬方法 set_headcount 直接叫得到
  DATA(lo_group) = NEW zcl_oo08_fare_group( ).
  lo_group->set_headcount( 12 ).

* 多型：一個「父類別參考」的表格，裝進各種子類別物件（向上轉型，自動）
  DATA lt_fares TYPE TABLE OF REF TO zcl_oo06_fare.
  lt_fares = VALUE #( ( NEW zcl_oo06_fare_economy( ) )
                      ( NEW zcl_oo06_fare_business( ) )
                      ( NEW zcl_oo06_fare_first( ) )
                      ( lo_group ) ).

  LOOP AT lt_fares INTO DATA(lo_fare).
    WRITE / |{ lo_fare->get_cabin_name( ) }: { lo_fare->calc_fare( lv_base ) }|.
  ENDLOOP.
  ULINE.

* 向下轉型：父類別參考看不到 set_headcount，先確認真實類別再 CAST
  LOOP AT lt_fares INTO lo_fare.
    IF lo_fare IS INSTANCE OF zcl_oo08_fare_group.
      DATA(lo_grp) = CAST zcl_oo08_fare_group( lo_fare ).
      lo_grp->set_headcount( 20 ).
      WRITE / |{ lo_grp->get_cabin_name( ) } 改 20 人後: { lo_grp->calc_fare( lv_base ) }|.
    ENDIF.
  ENDLOOP.
  ULINE.

* CASE TYPE OF：多分支的型別判斷，比連環 IF IS INSTANCE OF 乾淨
  LOOP AT lt_fares INTO lo_fare.
    CASE TYPE OF lo_fare.
      WHEN TYPE zcl_oo08_fare_group INTO DATA(lo_g).
        WRITE / |{ lo_g->get_cabin_name( ) } → 團體票（有專屬方法）|.
      WHEN TYPE zcl_oo06_fare_first.
        WRITE / |頭等艙（FINAL 類別）|.
      WHEN OTHERS.
        WRITE / |{ lo_fare->get_cabin_name( ) } → 一般艙等|.
    ENDCASE.
  ENDLOOP.

* 實驗（打開註解看執行期錯誤 MOVE_CAST_ERROR）：
*   經濟艙物件硬轉團體票——編譯過（語法合法）、執行期當掉
*  DATA(lo_bad) = CAST zcl_oo08_fare_group( lt_fares[ 1 ] ).
