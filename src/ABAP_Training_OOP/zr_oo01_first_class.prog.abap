*&---------------------------------------------------------------------*
*& Report  ZR_OO01_FIRST_CLASS
*& OOP 練習 1：為什麼要 OOP——第一個類別（答案程式）
*&---------------------------------------------------------------------*
* FORM 時代的痛點（練習 8）：
*   狀態放全域變數，任何 FORM 都能改；想要「第二份狀態」只能再宣告一組
* 類別把「資料（屬性）＋操作（方法）」包在一起，
*   同一個類別可以 NEW 出很多物件，每個物件各自擁有自己的屬性
*&---------------------------------------------------------------------*
REPORT zr_oo01_first_class.

*----------------------------------------------------------------------*
* 類別定義：宣告有哪些屬性與方法（只有長相，沒有內容）
*----------------------------------------------------------------------*
CLASS lcl_carrier_counter DEFINITION.
  PUBLIC SECTION.
    DATA: mv_carrid  TYPE s_carr_id,   " 航空公司代碼（m = member，實例屬性）
          mv_flights TYPE i.           " 累計航班數
    METHODS: add_flight,
             print.
ENDCLASS.

*----------------------------------------------------------------------*
* 類別實作：方法的程式碼寫在這裡
*----------------------------------------------------------------------*
CLASS lcl_carrier_counter IMPLEMENTATION.
  METHOD add_flight.
*   方法裡直接寫屬性名，就是「這個物件自己的」屬性（me-> 可省略）
    mv_flights = mv_flights + 1.
  ENDMETHOD.

  METHOD print.
    WRITE: / mv_carrid, '累計航班數:', mv_flights.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 主程式：NEW 出兩個物件，各自計數、互不干擾
*----------------------------------------------------------------------*
DATA: go_aa TYPE REF TO lcl_carrier_counter,   " 物件參考變數
      go_lh TYPE REF TO lcl_carrier_counter.

START-OF-SELECTION.
  go_aa = NEW #( ).           " NEW 建立物件（# = 依左邊變數的型別推斷類別）
  go_aa->mv_carrid = 'AA'.    " -> 存取物件的屬性
  go_lh = NEW #( ).
  go_lh->mv_carrid = 'LH'.

  go_aa->add_flight( ).       " -> 呼叫物件的方法
  go_aa->add_flight( ).
  go_aa->add_flight( ).
  go_lh->add_flight( ).

  WRITE / '=== 兩個物件，各自的狀態 ==='.
  go_aa->print( ).
  go_lh->print( ).
