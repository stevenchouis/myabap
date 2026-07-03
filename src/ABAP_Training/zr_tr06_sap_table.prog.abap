*&---------------------------------------------------------------------*
*& Report  ZR_TR06_SAP_TABLE
*& 練習 6：橋接 SAP Table——SCARR 航班訓練模型（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr06_sap_table.

*----------------------------------------------------------------------*
* SCARR 是 SAP 內建「航班訓練模型」的航空公司主檔：
*   SE11 可看表定義、SE16 可瀏覽資料
* 參照 DDIC 宣告變數：
*   TYPE scarr         → 整列（結構同表的一列）
*   TYPE scarr-carrid  → 單一欄位的型別
* （舊程式常見 LIKE scarr-carrid，效果相同——看得懂即可，新程式用 TYPE）
*----------------------------------------------------------------------*
DATA: gt_carriers TYPE STANDARD TABLE OF scarr,   " 多列
      gs_carrier  TYPE scarr,                     " 一列
      gv_carrid   TYPE scarr-carrid,              " 單一欄位
      gv_lines    TYPE i.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 第一個 SELECT：把資料庫的資料讀進 internal table
* UP TO n ROWS：最多讀 n 筆（練習時避免撈全表的好習慣）
*----------------------------------------------------------------------*
  SELECT * FROM scarr
    INTO TABLE @gt_carriers
    UP TO 10 ROWS.

  IF sy-subrc <> 0.
    WRITE / 'SCARR 沒有資料！請先執行報表 SAPBC_DATA_GENERATOR 產生訓練資料'.
    RETURN.
  ENDIF.

  gv_lines = lines( gt_carriers ).
  WRITE: / '讀到筆數：', gv_lines.

  WRITE / '=== 航空公司清單（代碼 / 名稱 / 幣別）==='.
  LOOP AT gt_carriers INTO gs_carrier.
    WRITE: / gs_carrier-carrid, gs_carrier-carrname, gs_carrier-currcode.
  ENDLOOP.

*----------------------------------------------------------------------*
* SELECT SINGLE：只讀一筆、指定欄位
* 跟 READ TABLE 一樣，讀完要檢查 sy-subrc
*----------------------------------------------------------------------*
  SELECT SINGLE carrid FROM scarr INTO @gv_carrid WHERE carrid = 'AA'.
  IF sy-subrc = 0.
    WRITE: / 'SELECT SINGLE 找到航空公司：', gv_carrid.
  ELSE.
    WRITE / '查無代碼 AA 的航空公司'.
  ENDIF.
