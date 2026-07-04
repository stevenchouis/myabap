*&---------------------------------------------------------------------*
*& Report  ZR_OO02_METHOD_PARAMS
*& OOP 練習 2：方法與參數（答案程式）
*&---------------------------------------------------------------------*
* 同一段「營收計算」邏輯的三種包法對照：
*   1) FM Z_TR15_CALC_REVENUE（練習 15：跨程式共用、SE37 可單測）
*   2) Method EXPORTING 版（跟 FM 一樣要先宣告變數接結果）
*   3) Method RETURNING 版（呼叫本身就是值——團隊首選）
*&---------------------------------------------------------------------*
REPORT zr_oo02_method_params.

CLASS lcl_revenue DEFINITION.
  PUBLIC SECTION.
    METHODS:
*     RETURNING 一個方法只能有一個，且必須 VALUE(...)（傳值）
      calc IMPORTING iv_price          TYPE s_price
                     iv_seatsocc       TYPE s_seatsocc
           RETURNING VALUE(rv_revenue) TYPE s_price,

*     EXPORTING 版：行為同 FM，純粹當對照組
      calc_exp IMPORTING iv_price    TYPE s_price
                         iv_seatsocc TYPE s_seatsocc
               EXPORTING ev_revenue  TYPE s_price,

*     CHANGING：拿呼叫端的變數來「就地修改」
      apply_discount IMPORTING iv_percent TYPE i
                     CHANGING  cv_price   TYPE s_price.
ENDCLASS.

CLASS lcl_revenue IMPLEMENTATION.
  METHOD calc.
    rv_revenue = iv_price * iv_seatsocc.
  ENDMETHOD.

  METHOD calc_exp.
    ev_revenue = iv_price * iv_seatsocc.
  ENDMETHOD.

  METHOD apply_discount.
    cv_price = cv_price * ( 100 - iv_percent ) / 100.
  ENDMETHOD.
ENDCLASS.

DATA: go_calc    TYPE REF TO lcl_revenue,
      gv_revenue TYPE s_price.

START-OF-SELECTION.
  go_calc = NEW #( ).

*----------------------------------------------------------------------*
* 1) 練習 15 的 FM 寫法（對照組）——注意方向反轉：
*    FM 定義的 IMPORTING，呼叫端要寫在 EXPORTING 底下
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_CALC_REVENUE'
    EXPORTING
      iv_price      = '1500.00'
      iv_seatsocc   = 200
    IMPORTING
      ev_revenue    = gv_revenue
    EXCEPTIONS
      invalid_input = 1
      OTHERS        = 2.
  IF sy-subrc = 0.
    WRITE: / 'FM 版        :', gv_revenue.
  ENDIF.

*----------------------------------------------------------------------*
* 2) Method EXPORTING 版：完整呼叫式，一樣要先有變數接結果
*----------------------------------------------------------------------*
  go_calc->calc_exp( EXPORTING iv_price    = '1500.00'
                               iv_seatsocc = 200
                     IMPORTING ev_revenue  = gv_revenue ).
  WRITE: / 'EXPORTING 版 :', gv_revenue.

*----------------------------------------------------------------------*
* 3) Method RETURNING 版：functional 呼叫，DATA(...) 一行接住
*----------------------------------------------------------------------*
  DATA(lv_revenue) = go_calc->calc( iv_price    = '1500.00'
                                    iv_seatsocc = 200 ).
  WRITE: / 'RETURNING 版 :', lv_revenue.

* 呼叫本身就是「值」，甚至能直接塞進 string template
  WRITE: / |一句話版本：營收 = { go_calc->calc( iv_price = '2000.00' iv_seatsocc = 150 ) }|.

*----------------------------------------------------------------------*
* 4) CHANGING：打 85 折，直接改呼叫端的變數
*----------------------------------------------------------------------*
  DATA(lv_price) = CONV s_price( '1000.00' ).
  go_calc->apply_discount( EXPORTING iv_percent = 15
                           CHANGING  cv_price   = lv_price ).
  WRITE: / '1000 打 85 折 =', lv_price.
