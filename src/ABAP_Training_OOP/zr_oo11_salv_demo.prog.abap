*&---------------------------------------------------------------------*
*& Report  ZR_OO11_SALV_DEMO
*& OOP 練習 11：cl_salv_table——ex09 Functional ALV 的 OO 版（答案程式）
*&---------------------------------------------------------------------*
* 對照 ex09（REUSE_ALV_GRID_DISPLAY）：
*   - 不用建 fieldcat：欄位資訊直接從 internal table 的型別推導
*   - 工具列/欄寬/標題都是「呼叫物件的方法」，不是塞一大包參數
*   - 錯誤處理是 op09 學的類別型例外（cx_salv_msg），不是 sy-subrc
*&---------------------------------------------------------------------*
REPORT zr_oo11_salv_demo.

START-OF-SELECTION.
  SELECT * FROM scarr INTO TABLE @DATA(gt_carriers).
  IF gt_carriers IS INITIAL.
    MESSAGE '查無資料！請確認 SCARR 有資料（SAPBC_DATA_GENERATOR）'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  TRY.
*     factory：把 internal table 交給它，回一個 ALV 物件——fieldcat 再見
      cl_salv_table=>factory(
        IMPORTING r_salv_table = DATA(go_alv)
        CHANGING  t_table      = gt_carriers ).

*     方法鏈：get_xxx( ) 拿到設定物件接著點下一個方法
      go_alv->get_functions( )->set_all( ).                " 工具列全開
      go_alv->get_columns( )->set_optimize( ).             " 欄寬自動
      go_alv->get_display_settings( )->set_striped_pattern( abap_true ).
      go_alv->get_display_settings( )->set_list_header(
        |航空公司清單（cl_salv_table 版，共 { lines( gt_carriers ) } 筆）| ).

*     單一欄位設定：鏈到底就是一個 cl_salv_column 物件
      go_alv->get_columns( )->get_column( 'URL' )->set_visible( abap_false ).

      go_alv->display( ).

*   op09 的例外處理實戰：SALV 的錯誤全是類別型例外
    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
    CATCH cx_salv_not_found INTO DATA(lx_not_found).       " get_column 找不到欄位
      MESSAGE lx_not_found->get_text( ) TYPE 'E'.
  ENDTRY.
