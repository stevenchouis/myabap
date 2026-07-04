*&---------------------------------------------------------------------*
*& Report  ZR_OO03_ENCAPSULATION
*& OOP 練習 3：建構子與封裝（答案程式）
*&---------------------------------------------------------------------*
* op01 的問題：屬性全 PUBLIC，任何人都能 go_aa->mv_flights = 999
* 封裝的解法：
*   屬性藏進 PRIVATE SECTION，只開放「守得住規則」的公開方法
*   constructor 保證物件一出生就是有效狀態（必要資料非給不可）
*&---------------------------------------------------------------------*
REPORT zr_oo03_encapsulation.

CLASS lcl_carrier_stats DEFINITION.
  PUBLIC SECTION.
*   READ-ONLY：外面可以讀 go->mv_carrid，但只有類別自己能改
    DATA mv_carrid TYPE s_carr_id READ-ONLY.

    METHODS:
*     constructor：NEW 的當下自動執行，強迫呼叫端交出必要資料
      constructor IMPORTING iv_carrid TYPE s_carr_id,
      add_flights IMPORTING iv_count TYPE i,
      get_flights RETURNING VALUE(rv_flights) TYPE i.

*   class_constructor：整個程式第一次用到本類別前執行，只跑一次
*   （它是靜態方法——CLASS-METHODS 的完整介紹在 op04）
    CLASS-METHODS class_constructor.

  PRIVATE SECTION.
*   私有屬性：外部看不到，想改只能走公開方法
    DATA mv_flights TYPE i.
ENDCLASS.

CLASS lcl_carrier_stats IMPLEMENTATION.
  METHOD class_constructor.
    WRITE / '>>> class_constructor：整個程式只執行這一次'.
  ENDMETHOD.

  METHOD constructor.
    mv_carrid = iv_carrid.
    WRITE: / '>>> constructor：建立', iv_carrid, '的統計物件'.
  ENDMETHOD.

  METHOD add_flights.
*   守門：不合理的輸入直接擋掉（正式做法是丟例外——op09 再教）
    IF iv_count > 0.
      mv_flights = mv_flights + iv_count.
    ENDIF.
  ENDMETHOD.

  METHOD get_flights.
    rv_flights = mv_flights.
  ENDMETHOD.
ENDCLASS.

DATA: go_aa TYPE REF TO lcl_carrier_stats,
      go_lh TYPE REF TO lcl_carrier_stats.

START-OF-SELECTION.
  go_aa = NEW #( iv_carrid = 'AA' ).   " 括號裡就是 constructor 的參數
  go_lh = NEW #( iv_carrid = 'LH' ).

  go_aa->add_flights( 5 ).
  go_aa->add_flights( -99 ).           " 負數會被守門擋下
  go_lh->add_flights( 2 ).

  WRITE / '=== 封裝後的物件 ==='.
  WRITE: / go_aa->mv_carrid, '航班數:', go_aa->get_flights( ).
  WRITE: / go_lh->mv_carrid, '航班數:', go_lh->get_flights( ).

* 下面兩行打開註解會直接「編譯錯誤」——這就是封裝的價值：
* 錯誤在上線前就被語法檢查抓到，而不是等資料被改壞才發現
*  go_aa->mv_flights = 999.   " PRIVATE：外部不可存取
*  go_aa->mv_carrid  = 'XX'.  " READ-ONLY：外部只能讀
