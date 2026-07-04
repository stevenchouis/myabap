*&---------------------------------------------------------------------*
*& Report  ZR_OO05_USE_GLOBAL
*& OOP 練習 5：使用全域類別（答案程式）
*&---------------------------------------------------------------------*
* 對照 op03：用法一模一樣，但類別定義不在程式裡——
*   ZCL_OO05_CARRIER_STATS 住在系統裡，任何程式都能直接用
*&---------------------------------------------------------------------*
REPORT zr_oo05_use_global.

START-OF-SELECTION.
  DATA(go_aa) = NEW zcl_oo05_carrier_stats( iv_carrid = 'AA' ).
  DATA(go_lh) = NEW zcl_oo05_carrier_stats( iv_carrid = 'LH' ).

  go_aa->add_flights( 5 ).
  go_aa->add_flights( -99 ).           " 一樣會被守門擋下
  go_lh->add_flights( 2 ).

  WRITE / '=== 全域類別：類別在系統裡，程式只剩使用 ==='.
  WRITE: / go_aa->mv_carrid, '航班數:', go_aa->get_flights( ).
  WRITE: / go_lh->mv_carrid, '航班數:', go_lh->get_flights( ).
