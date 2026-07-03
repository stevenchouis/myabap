*&---------------------------------------------------------------------*
*& Report  ZR_TR13_CAPSTONE
*& 練習 13：期末綜合實作——航班營收報表（答案程式）
*& 仿 Z_INVENTORY_COST_REPORT 的結構：
*& 選擇畫面 → JOIN 取數 → 分頁排版 → 頁首頁尾 → 總頁數回填
*&---------------------------------------------------------------------*
REPORT zr_tr13_capstone NO STANDARD PAGE HEADING
                        LINE-SIZE 132
                        LINE-COUNT 65(3).

TABLES sflight.

TYPES: BEGIN OF ty_rev,
         carrid   TYPE sflight-carrid,     " 航空公司
         carrname TYPE scarr-carrname,     " 公司名稱
         connid   TYPE sflight-connid,     " 航線
         fldate   TYPE sflight-fldate,     " 航班日期
         seatsocc TYPE sflight-seatsocc,   " 已售座位
         price    TYPE sflight-price,      " 票價
         currency TYPE sflight-currency,   " 幣別
         revenue  TYPE p LENGTH 12 DECIMALS 2,   " 營收 = 票價 × 已售座位
       END OF ty_rev.

DATA: gt_rev   TYPE STANDARD TABLE OF ty_rev,
      gs_rev   TYPE ty_rev,
      gv_count TYPE i.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
  SELECT-OPTIONS: s_carrid FOR sflight-carrid,
                  s_fldate FOR sflight-fldate.
  PARAMETERS p_zero AS CHECKBOX DEFAULT 'X'.    " 排除沒賣出座位的航班
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  t_b1 = '查詢條件'.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display_data.

END-OF-SELECTION.
  PERFORM update_total_pages.

*----------------------------------------------------------------------*
* TOP-OF-PAGE：頁首（第 2 行的 ### 之後由 update_total_pages 回填）
*----------------------------------------------------------------------*
TOP-OF-PAGE.
  WRITE: /1   '程式名稱：', (20) sy-repid,
          52(20) '航班營收報表' CENTERED,
          105 '列印日期：', sy-datum.
  WRITE: /1   '使用者　：', (20) sy-uname,
          105 '頁次　　：', (3) sy-pagno NO-GAP, '/', '###'.
  WRITE: /105 '列印時間：', sy-uzeit.
  ULINE AT /1(106).
  WRITE: /1  '|', 2(4)   '公司' CENTERED,
          7  '|', 8(20)  '公司名稱' CENTERED,
          29 '|', 30(4)  '航線' CENTERED,
          35 '|', 36(10) '航班日期' CENTERED,
          47 '|', 48(10) '已售座位' CENTERED,
          59 '|', 60(16) '票價' CENTERED,
          77 '|', 78(20) '營收' CENTERED,
          99 '|', 100(5) '幣別',
          106 '|'.
  ULINE AT /1(106).

*----------------------------------------------------------------------*
* END-OF-PAGE：頁尾（LINE-COUNT 65(3) 保留的 3 行）
*----------------------------------------------------------------------*
END-OF-PAGE.
  ULINE AT /1(106).
  WRITE: /1 '製表：財務部', 80 '主管簽核：____________'.

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
FORM get_data.
  SELECT f~carrid, c~carrname, f~connid, f~fldate,
         f~seatsocc, f~price, f~currency
    INTO CORRESPONDING FIELDS OF TABLE @gt_rev
    FROM sflight AS f
    INNER JOIN scarr AS c ON f~carrid = c~carrid
    WHERE f~carrid IN @s_carrid
      AND f~fldate IN @s_fldate.

  IF p_zero = 'X'.
    DELETE gt_rev WHERE seatsocc = 0.
  ENDIF.

  LOOP AT gt_rev INTO gs_rev.
    gs_rev-revenue = gs_rev-price * gs_rev-seatsocc.
    MODIFY gt_rev FROM gs_rev.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  display_data
*&---------------------------------------------------------------------*
FORM display_data.
  IF gt_rev IS INITIAL.
    WRITE / '查無資料！請確認 SFLIGHT 有資料（SAPBC_DATA_GENERATOR）'.
    RETURN.
  ENDIF.

  gv_count = 0.
  LOOP AT gt_rev INTO gs_rev.
    gv_count = gv_count + 1.
    WRITE: /1  '|', 2(4)   gs_rev-carrid,
            7  '|', 8(20)  gs_rev-carrname,
            29 '|', 30(4)  gs_rev-connid,
            35 '|', 36(10) gs_rev-fldate,
            47 '|', 48(10) gs_rev-seatsocc,
            59 '|', 60(16) gs_rev-price   CURRENCY gs_rev-currency,
            77 '|', 78(20) gs_rev-revenue CURRENCY gs_rev-currency,
            99 '|', 100(5) gs_rev-currency,
            106 '|'.
  ENDLOOP.
  ULINE AT /1(106).
  WRITE: / '合計筆數：', gv_count.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  update_total_pages
*&      總頁數回填：所有 WRITE 先進 List Buffer，
*&      END-OF-SELECTION 時全部頁面已知，最後的 sy-pagno 即總頁數；
*&      READ LINE 讀回 Buffer 內容（放 sy-lisel）→ 改字 → MODIFY LINE 寫回
*&---------------------------------------------------------------------*
FORM update_total_pages.
  DATA lv_total TYPE c LENGTH 3.
  lv_total = sy-pagno.

  DO sy-pagno TIMES.
    READ LINE 2 OF PAGE sy-index.     " 頁首第 2 行（含 ### 那行）
    IF sy-subrc = 0.
      REPLACE '###' WITH lv_total INTO sy-lisel.
      MODIFY LINE 2 OF PAGE sy-index.
    ENDIF.
  ENDDO.
ENDFORM.