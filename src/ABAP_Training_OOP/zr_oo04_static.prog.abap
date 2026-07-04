*&---------------------------------------------------------------------*
*& Report  ZR_OO04_STATIC
*& OOP 練習 4：靜態 vs 實例（答案程式）
*&---------------------------------------------------------------------*
* 實例成員：每個物件一份（op01–03 都是）
* 靜態成員（CLASS-DATA / CLASS-METHODS）：整個類別只有一份，
*   不用 NEW 就能用，呼叫符號是 =>（實例用 ->）
* 使用時機：
*   純計算、無狀態的工具 → 靜態（工具類）
*   每個物件要記自己的資料 → 實例
*&---------------------------------------------------------------------*
REPORT zr_oo04_static.

*----------------------------------------------------------------------*
* 工具類：全靜態，純輸入→輸出，不記任何狀態
*----------------------------------------------------------------------*
CLASS lcl_flight_util DEFINITION.
  PUBLIC SECTION.
    TYPES ty_rate TYPE p LENGTH 5 DECIMALS 1.
    CLASS-METHODS occupancy_rate
      IMPORTING iv_seatsmax    TYPE s_seatsmax
                iv_seatsocc    TYPE s_seatsocc
      RETURNING VALUE(rv_rate) TYPE ty_rate.
ENDCLASS.

CLASS lcl_flight_util IMPLEMENTATION.
  METHOD occupancy_rate.
*   守門：座位數 0 直接回 0，避免除零 dump
    IF iv_seatsmax > 0.
      rv_rate = iv_seatsocc * 100 / iv_seatsmax.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 有狀態的類別＋一個「全類別共用」的靜態計數器
*----------------------------------------------------------------------*
CLASS lcl_booking DEFINITION.
  PUBLIC SECTION.
*   CLASS-DATA：不管 NEW 幾個物件，這個變數只有一份
    CLASS-DATA gv_created TYPE i READ-ONLY.
    DATA mv_carrid TYPE s_carr_id READ-ONLY.
    METHODS constructor IMPORTING iv_carrid TYPE s_carr_id.
ENDCLASS.

CLASS lcl_booking IMPLEMENTATION.
  METHOD constructor.
    mv_carrid = iv_carrid.
*   實例方法可以讀寫靜態屬性（反過來不行——靜態方法碰不到 mv_）
    gv_created = gv_created + 1.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  WRITE / '=== 靜態方法：不用 NEW，用 => 直接呼叫 ==='.
  WRITE / |AA 0017 載客率: { lcl_flight_util=>occupancy_rate( iv_seatsmax = 340 iv_seatsocc = 290 ) } %|.

  DATA(go_b1) = NEW lcl_booking( 'AA' ).
  DATA(go_b2) = NEW lcl_booking( 'LH' ).
  DATA(go_b3) = NEW lcl_booking( 'SQ' ).

  WRITE / '=== CLASS-DATA：所有物件共用一份 ==='.
  WRITE / |已建立的訂位物件數: { lcl_booking=>gv_created }|.
  WRITE / |（go_b1 看到的也是同一份: { go_b1->gv_created }）|.
