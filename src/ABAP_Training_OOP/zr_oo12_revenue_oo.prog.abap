*&---------------------------------------------------------------------*
*& Report  ZR_OO12_REVENUE_OO
*& OOP 練習 12：期末重構——ex13 航班營收報表 OO 化（答案程式）
*&---------------------------------------------------------------------*
* 商業邏輯在 ZCL_OO12_FLIGHT_REVENUE（附 ABAP Unit 測試），
* 本程式只剩 UI 薄層：選擇畫面 → 呼叫類別 → cl_salv_table 輸出
*&---------------------------------------------------------------------*
REPORT zr_oo12_revenue_oo.

TABLES sflight.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
  SELECT-OPTIONS: s_carrid FOR sflight-carrid,
                  s_fldate FOR sflight-fldate.
  PARAMETERS p_zero AS CHECKBOX DEFAULT 'X'.    " 排除沒賣出座位的航班
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  t_b1 = '查詢條件'.

START-OF-SELECTION.
  TRY.
      DATA(gt_revenues) = NEW zcl_oo12_flight_revenue( )->get_revenues(
        ir_carrid      = s_carrid[]
        ir_fldate      = s_fldate[]
        iv_skip_unsold = xsdbool( p_zero = 'X' ) ).

      cl_salv_table=>factory( IMPORTING r_salv_table = DATA(go_alv)
                              CHANGING  t_table      = gt_revenues ).
      go_alv->get_functions( )->set_all( ).
      go_alv->get_columns( )->set_optimize( ).
      go_alv->get_display_settings( )->set_list_header(
        |航班營收報表（共 { lines( gt_revenues ) } 筆）| ).
      go_alv->display( ).

    CATCH zcx_oo12_no_data INTO DATA(lx_no_data).
      MESSAGE lx_no_data->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
  ENDTRY.
