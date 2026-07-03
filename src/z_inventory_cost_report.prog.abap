REPORT z_inventory_cost_report NO STANDARD PAGE HEADING
                               LINE-SIZE 100
                               LINE-COUNT 65.

TABLES: mard, makt, mbew, mara, t001.

*----------------------------------------------------------------------*
* Data Definition
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_data,
         matnr TYPE mard-matnr,
         maktx TYPE makt-maktx,
         werks TYPE mard-werks,
         lgort TYPE mard-lgort,
         labst TYPE mard-labst,
         meins TYPE mara-meins,  " 數量單位參考
         stprs TYPE mbew-stprs,
         waers TYPE t001-waers,  " 幣別參考
         peinh TYPE mbew-peinh,
         total TYPE p DECIMALS 2,
       END OF ty_data.

DATA: gt_list TYPE TABLE OF ty_data,
      gs_list TYPE ty_data.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:  p_werks TYPE werks_d OBLIGATORY.
  SELECT-OPTIONS:
                  s_lgort FOR mard-lgort,
                  s_matnr FOR mard-matnr.
  SELECTION-SCREEN ULINE.
  SELECTION-SCREEN SKIP 2.
  PARAMETERS: p_zero AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.

* 選擇畫面示範元件（按鈕/核取方塊/radio 排版練習）已移至 ZR_SELSCREEN_DEMO

*----------------------------------------------------------------------*
* Main Process
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display_data.

END-OF-SELECTION.
  PERFORM update_total_pages.

* 重點: 所有的WRITE(例如在TOP-OF-PAGE及START-OF-SELECTION中) 均是先放到List Buffer 中,
* 一旦執行完END-OF-SELECTION才會由Buffer輪出到畫面

*----------------------------------------------------------------------*
* TOP-OF-PAGE (座標精確對齊至位置 100)
*----------------------------------------------------------------------*
TOP-OF-PAGE.
  WRITE: /1  '程式名稱：', (15) sy-repid,
          31 'XXXX 股份有限公司',
          72 '列印日期：', sy-datum.

  WRITE: /1  '使用者  ：', (15) sy-uname,
          32 '物料庫存成本表',
          72 '頁次    ：', sy-pagno NO-GAP, ' / ', '###'.

  WRITE: /72 '列印時間：', sy-uzeit.

  " 繪製表頭橫線 (總長度 100)
  ULINE AT /1(100).
  WRITE: /1  '|', 2(12)  '料號'     CENTERED,
          14 '|', 15(20) '說明'     CENTERED,
          36 '|', 37(11) '廠 / 倉'  CENTERED,
          48 '|', 49(16) '庫存數'   CENTERED, " 加寬以容納單位
          65 '|', 66(12) '單價'     CENTERED,
          79 '|', 80(12) '總價'     CENTERED,
          93 '|', 94(5)  '幣別', 100 '|'.
  ULINE AT /1(100).

*----------------------------------------------------------------------*
* Form GET_DATA
*----------------------------------------------------------------------*
FORM get_data.
" 修正 JOIN 邏輯：T001W 的公司代碼欄位通常關聯至 T001
SELECT a~matnr, b~maktx, a~werks, a~lgort, a~labst, d~meins, c~stprs, c~peinh, e~waers
    INTO CORRESPONDING FIELDS OF TABLE @gt_list
    FROM mard AS a
    INNER JOIN mara AS d ON a~matnr = d~matnr
    INNER JOIN t001k AS k ON a~werks = k~bwkey      " 1. 透過估價控制表 (T001K) 橋接
    LEFT JOIN makt AS b ON a~matnr = b~matnr AND b~spras = @sy-langu
    LEFT JOIN mbew AS c ON a~matnr = c~matnr AND a~werks = c~bwkey
    LEFT JOIN t001 AS e ON k~bukrs = e~bukrs         " 2. 透過公司代碼取得幣別
    WHERE a~matnr IN @s_matnr
      AND a~werks = @p_werks   " 單值參數
      AND a~lgort IN @s_lgort.

  IF p_zero = 'X'.
    DELETE gt_list WHERE labst = 0.
  ENDIF.

  LOOP AT gt_list INTO gs_list.
    IF gs_list-peinh > 0.
      gs_list-total = ( gs_list-labst / gs_list-peinh ) * gs_list-stprs.
      MODIFY gt_list FROM gs_list.
    ENDIF.
  ENDLOOP.
ENDFORM.

*----------------------------------------------------------------------*
* Form DISPLAY_DATA
*----------------------------------------------------------------------*
FORM display_data.
  IF gt_list IS INITIAL.
    WRITE: / '查無資料'. RETURN.
  ENDIF.

  LOOP AT gt_list INTO gs_list.
    " 1:料號 | 14:說明 | 36:廠/倉 | 48:庫存 | 65:單價 | 79:總價 | 93:幣別
    WRITE: /1  '|', 2(12)  gs_list-matnr,
            14 '|', 15(20) gs_list-maktx,
            " 核心修正：將廠與倉的分隔拉開，確保各 4 碼完整顯示
            36 '|', 37(4)  gs_list-werks, 42 '/', 44(4) gs_list-lgort,
            48 '|', 49(12) gs_list-labst UNIT gs_list-meins RIGHT-JUSTIFIED,
            62(3)  gs_list-meins,
            65 '|', 66(12) gs_list-stprs CURRENCY gs_list-waers RIGHT-JUSTIFIED,
            79 '|', 80(12) gs_list-total CURRENCY gs_list-waers RIGHT-JUSTIFIED,
            93 '|', 94(5)  gs_list-waers,
            100 '|'.
  ENDLOOP.
  ULINE AT /1(100).
  WRITE: / '列印單位：財務部', AT 70 '主管簽核：__________'.
ENDFORM.

*----------------------------------------------------------------------*
* Form UPDATE_TOTAL_PAGES
*----------------------------------------------------------------------*
FORM update_total_pages.
  DATA: lv_total(3) TYPE c.
* 因一旦完全印到List Buffer, 最後的頁碼即為總頁數
  lv_total = sy-pagno.

  DO sy-pagno TIMES.
*讀出來的line 內容, 會放在系統變數sy-lisel中
    READ LINE 2 OF PAGE sy-index.
    IF sy-subrc = 0.
      REPLACE '###' WITH lv_total INTO sy-lisel.
* 改了總頁數後, 再由sy-lisel 中, Modify List Buffer 的資料
      MODIFY LINE 2 OF PAGE sy-index.
    ENDIF.
  ENDDO.
ENDFORM.
