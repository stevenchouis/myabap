*&---------------------------------------------------------------------*
*& Report  ZR_OO09_EXCEPTION_DEMO
*& OOP 練習 9：例外類別——TRY/CATCH/CLEANUP（答案程式）
*&---------------------------------------------------------------------*
* ZCX_OO09_NO_FLIGHT（繼承 CX_STATIC_CHECK）+ ZCL_OO09_FLIGHT_READER
* 執行：p_carrid 給 AA 看正常路徑、給 XX 看例外路徑
*&---------------------------------------------------------------------*
REPORT zr_oo09_exception_demo.

PARAMETERS p_carrid TYPE s_carr_id DEFAULT 'XX'.

START-OF-SELECTION.
  DATA(lo_reader) = NEW zcl_oo09_flight_reader( ).

* 基本款：TRY 包住會丟例外的呼叫，CATCH 接住處理
  TRY.
      DATA(lt_flights) = lo_reader->get_flights( p_carrid ).
      WRITE / |{ p_carrid } 共 { lines( lt_flights ) } 筆航班|.

      LOOP AT lt_flights INTO DATA(ls_flight) FROM 1 TO 5.
        WRITE / |{ ls_flight-connid } { ls_flight-fldate DATE = USER } 價格 { ls_flight-price }|.
      ENDLOOP.

    CATCH zcx_oo09_no_flight INTO DATA(lx_no_flight).
      WRITE / |錯誤: { lx_no_flight->get_text( ) }|.
*     例外物件帶著現場資料，不是只有一個錯誤碼
      WRITE / |（例外物件屬性 mv_carrid = { lx_no_flight->mv_carrid }）|.
  ENDTRY.
  ULINE.

* CLEANUP 示範：例外「穿過」內層 TRY 往外找 CATCH 時，內層 CLEANUP 先執行
*   用途：釋放資源、回復狀態——不是用來「處理」例外
  TRY.
      TRY.
          lo_reader->get_flights( 'ZZ' ).
        CLEANUP.
          WRITE / 'CLEANUP: 內層善後（例外正要往外傳）'.
      ENDTRY.
    CATCH zcx_oo09_no_flight INTO DATA(lx_outer).
      WRITE / |外層接住: { lx_outer->get_text( ) }|.
  ENDTRY.
