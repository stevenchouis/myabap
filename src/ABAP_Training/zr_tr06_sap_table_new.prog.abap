*&---------------------------------------------------------------------*
*& Report  ZR_TR06_SAP_TABLE_NEW
*& 練習 6：讀 SAP Table（答案程式，新式寫法版）
*& 對照 ZR_TR06_SAP_TABLE：輸出相同；New Open SQL：宿主變數加 @、
*& INTO 放句尾、@DATA( ) 行內宣告接收結果
*&---------------------------------------------------------------------*
REPORT zr_tr06_sap_table_new.

START-OF-SELECTION.
* INTO TABLE @DATA(gt_carriers)：內表在這裡才宣告，型別由 SELECT 清單推導（這裡是整列 SCARR）
* 新式寫法 INTO 放在最後，UP TO n ROWS 接在 INTO 之後
  SELECT * FROM scarr
    INTO TABLE @DATA(gt_carriers)
    UP TO 10 ROWS.

  IF sy-subrc <> 0.
    WRITE / 'SCARR 沒有資料！請先執行報表 SAPBC_DATA_GENERATOR 產生訓練資料'.
    RETURN.
  ENDIF.

  DATA(gv_lines) = lines( gt_carriers ).
  WRITE: / '讀到筆數：', gv_lines.

  WRITE / '=== 航空公司清單（代碼 / 名稱 / 幣別）==='.
  LOOP AT gt_carriers INTO DATA(gs_carrier).
    WRITE: / gs_carrier-carrid, gs_carrier-carrname, gs_carrier-currcode.
  ENDLOOP.

* SELECT SINGLE：WHERE 在前、INTO 在最後；@DATA(gv_carrid) 的型別是 SCARR-CARRID
  SELECT SINGLE carrid FROM scarr
    WHERE carrid = 'AA'
    INTO @DATA(gv_carrid).
  IF sy-subrc = 0.
    WRITE: / 'SELECT SINGLE 找到航空公司：', gv_carrid.
  ELSE.
    WRITE / '查無代碼 AA 的航空公司'.
  ENDIF.
