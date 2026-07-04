*&---------------------------------------------------------------------*
*& Report  ZR_OO07_DISCOUNT_DEMO
*& OOP 練習 7：介面——折扣規則（答案程式）
*&---------------------------------------------------------------------*
* ZIF_OO07_DISCOUNT（介面：get_name / apply）
*   ├─ ZCL_OO07_DISC_CHILD（兒童票 65 折）
*   └─ ZCL_OO07_DISC_SENIOR（敬老票 8 折）
* 重點：呼叫端只認識「介面」，不認識任何實作類別
*&---------------------------------------------------------------------*
REPORT zr_oo07_discount_demo.

START-OF-SELECTION.
  DATA(lv_base) = CONV s_price( '1000.00' ).

* 票價來源沿用 op06 的商務艙計價——繼承家族與介面家族可以組合
  DATA(lo_biz)  = NEW zcl_oo06_fare_business( ).
  DATA(lv_fare) = lo_biz->calc_fare( lv_base ).

  WRITE / |商務艙原價: { lv_fare }|.
  ULINE.

* 重點：表格型別宣告在「介面」，不是任何一個實作類別
  DATA lt_discounts TYPE TABLE OF REF TO zif_oo07_discount.
  lt_discounts = VALUE #( ( NEW zcl_oo07_disc_child( ) )
                          ( NEW zcl_oo07_disc_senior( ) ) ).

* 之後新增「早鳥票」只要多一個實作類別 + 這裡多一行，迴圈完全不用改
  LOOP AT lt_discounts INTO DATA(lo_disc).
    WRITE / |{ lo_disc->get_name( ) }: { lo_disc->apply( lv_fare ) }|.
  ENDLOOP.
