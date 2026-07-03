*&---------------------------------------------------------------------*
*& Report  ZR_TR09_ALV
*& 練習 9：ALV 輸出——cl_salv_table（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr09_alv.

DATA gt_carriers TYPE STANDARD TABLE OF scarr.

START-OF-SELECTION.
  SELECT * FROM scarr
    INTO TABLE @gt_carriers.

  IF sy-subrc <> 0.
    WRITE / 'SCARR 沒有資料！請先執行報表 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.

*----------------------------------------------------------------------*
* cl_salv_table：最簡單的 ALV 作法——一個 factory 呼叫就把
* internal table 變成功能完整的表格畫面（排序/篩選/加總/匯出 Excel）
* 對比練習 6 用 WRITE 排版：ALV 讓「輸出」幾乎不花力氣
*----------------------------------------------------------------------*
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = DATA(go_alv)     " 內聯宣告：宣告兼接值
        CHANGING  t_table      = gt_carriers ).

      go_alv->get_functions( )->set_all( abap_true ).    " 開啟工具列全部功能
      go_alv->get_columns( )->set_optimize( abap_true ). " 欄寬自動最佳化

      go_alv->display( ).

    CATCH cx_salv_msg INTO DATA(go_err).
      " ALV 建立失敗時的例外處理（TRY/CATCH 之後課程會教）
      WRITE: / 'ALV 錯誤：', go_err->get_text( ).
  ENDTRY.
