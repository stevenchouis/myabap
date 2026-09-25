*&---------------------------------------------------------------------*
*& Report  ZR_TR25_DDIC
*& 練習 25：Data Dictionary 總覽與 Global Type（答案程式）
*& 前提：SE11 已建立並啟用 ZTR25_SURCHG（欄位規格見 ex25 第一部分，
*&       CARRID 重用標準 Data Element S_CARR_ID、Check Table 指向標準表 SCARR）、
*&       Table Type ZTR25_TT_SURCHG（Line Type = ZTR25_SURCHG，Standard Table）
*& 授課順序：接在講義 7 之後，還沒學 FORM（講義 8）與 JOIN（講義 11），
*&           所以本程式全部寫在 START-OF-SELECTION，用註解分段
*&---------------------------------------------------------------------*
REPORT zr_tr25_ddic.

TYPES: BEGIN OF ty_rev,
         carrid        TYPE s_carr_id,              " 直接引用標準 Data Element
         carrname      TYPE scarr-carrname,
         connid        TYPE sflight-connid,
         fldate        TYPE sflight-fldate,
         seatsocc      TYPE sflight-seatsocc,
         price         TYPE sflight-price,
         active        TYPE ztr25_surchg-active,
         surcharge_pct TYPE ztr25_surchg-surcharge_pct,
         revenue       TYPE p LENGTH 12 DECIMALS 2,
         revenue_adj   TYPE p LENGTH 12 DECIMALS 2,
       END OF ty_rev.

DATA: gt_rev           TYPE STANDARD TABLE OF ty_rev,
      gs_rev           TYPE ty_rev,
      gv_carrid_global TYPE s_carr_id,              " Global Type：引用標準 Data Element
      gv_carrid_hard   TYPE c LENGTH 3,             " 反面教材：寫死長度
      gt_surchg        TYPE ztr25_tt_surchg,        " DDIC Table Type（全域表格型別）
      gs_surchg        TYPE ztr25_surchg,           " 整列：Global Type（表格本身）
      gt_flight        TYPE STANDARD TABLE OF sflight,
      gs_flight        TYPE sflight,
      gt_scarr         TYPE STANDARD TABLE OF scarr,
      gs_scarr         TYPE scarr,
      gv_lines         TYPE i.

START-OF-SELECTION.

*----------------------------------------------------------------------*
* 1) Global Type 示範：引用 Global Type vs 寫死長度
*    現在看起來一樣，SAP 標準若調整 S_CARR_ID 的長度，
*    gv_carrid_global 自動跟著變，gv_carrid_hard 不會（見講義 25 第 2.1 節）
*----------------------------------------------------------------------*
  gv_carrid_global = 'LH'.
  gv_carrid_hard   = 'LH'.

  WRITE / '=== Global Type 示範 ==='.
  WRITE: / 'gv_carrid_global（TYPE s_carr_id）：', gv_carrid_global.
  WRITE / '  → 型別／長度／標籤／F4 全部繼承自標準 Data Element，SAP 升級調整它，這裡自動跟著變'.
  WRITE: / 'gv_carrid_hard（TYPE c LENGTH 3）：', gv_carrid_hard.
  WRITE / '  → 看起來結果一樣，但長度是寫死的——S_CARR_ID 若改長，這裡不會自動變寬，是條隱藏地雷'.
  SKIP.

*----------------------------------------------------------------------*
* 2) DDIC Table Type：跟講義 4 的 Local Type 語法完全一樣，
*    差別是 ZTR25_TT_SURCHG 定義在 SE11，任何程式都能重用同一份
*    （之後講義 8 的 FORM、講義 15 的 FM 參數也會直接用它）
*----------------------------------------------------------------------*
  SELECT * FROM ztr25_surchg
    INTO TABLE gt_surchg.

  DESCRIBE TABLE gt_surchg LINES gv_lines.
  WRITE: / '讀到旺季加成設定：', gv_lines, '筆（DDIC Table Type ZTR25_TT_SURCHG）'.
  SKIP.

*----------------------------------------------------------------------*
* 3) 取數：三張表各自讀進內表，再用 READ TABLE 對照（講義 4／5 學過）
*    沒被財務設定過的航空公司，READ TABLE 找不到（sy-subrc <> 0），
*    active／surcharge_pct 維持初始值，照樣出現在報表上。
*    學完講義 11 後，這種「對照另一張表、找不到也要保留」的讀法
*    可以用一句 LEFT OUTER JOIN 完成。
*----------------------------------------------------------------------*
  SELECT * FROM sflight
    INTO TABLE gt_flight UP TO 100 ROWS
    WHERE seatsocc > 0
    ORDER BY carrid connid fldate.

  SELECT * FROM scarr
    INTO TABLE gt_scarr.

  LOOP AT gt_flight INTO gs_flight.
    CLEAR gs_rev.
    gs_rev-carrid   = gs_flight-carrid.
    gs_rev-connid   = gs_flight-connid.
    gs_rev-fldate   = gs_flight-fldate.
    gs_rev-seatsocc = gs_flight-seatsocc.
    gs_rev-price    = gs_flight-price.

    READ TABLE gt_scarr INTO gs_scarr WITH KEY carrid = gs_flight-carrid.
    IF sy-subrc = 0.
      gs_rev-carrname = gs_scarr-carrname.
    ENDIF.

    READ TABLE gt_surchg INTO gs_surchg WITH KEY carrid = gs_flight-carrid.
    IF sy-subrc = 0.
      gs_rev-active        = gs_surchg-active.
      gs_rev-surcharge_pct = gs_surchg-surcharge_pct.
    ENDIF.                                          " 找不到＝沒設定，維持初始值

    gs_rev-revenue = gs_rev-price * gs_rev-seatsocc.
    IF gs_rev-active = 'X'.
      gs_rev-revenue_adj = gs_rev-revenue * ( 1 + gs_rev-surcharge_pct / 100 ).
    ELSE.
      gs_rev-revenue_adj = gs_rev-revenue.
    ENDIF.
    APPEND gs_rev TO gt_rev.
  ENDLOOP.

*----------------------------------------------------------------------*
* 4) 輸出
*----------------------------------------------------------------------*
  IF gt_rev IS INITIAL.
    WRITE / '查無資料！請確認 SFLIGHT 有資料（SAPBC_DATA_GENERATOR）'.
  ELSE.
    WRITE / '=== 航班加成營收 ==='.
    LOOP AT gt_rev INTO gs_rev.
      WRITE: / gs_rev-carrid, gs_rev-carrname, gs_rev-connid, gs_rev-fldate,
               '原始營收', gs_rev-revenue CURRENCY 'USD',
               '加成後', gs_rev-revenue_adj CURRENCY 'USD'.
      IF gs_rev-active = 'X'.
        WRITE: '（已加成', gs_rev-surcharge_pct, '%）'.
      ELSE.
        WRITE '（未設定，維持原價）'.
      ENDIF.
    ENDLOOP.
    SKIP.
  ENDIF.

*----------------------------------------------------------------------*
* 5) 驗證：Check Table 換成標準表 SCARR，結論依然不變——
*    DDIC 外鍵只在畫面輸入生效，Open SQL 呼叫完全不受影響
*    （INSERT／DELETE 這類寫入語法，講義 21 會正式教）
*----------------------------------------------------------------------*
  DELETE FROM ztr25_surchg WHERE carrid = 'ZZ'.     " 防呆：清掉可能殘留的測試資料

  CLEAR gs_surchg.
  gs_surchg-carrid        = 'ZZ'.                   " SCARR 沒有這家航空公司
  gs_surchg-active        = 'X'.
  gs_surchg-surcharge_pct = '20.00'.
  gs_surchg-upduser       = sy-uname.
  gs_surchg-upddate       = sy-datum.
  INSERT ztr25_surchg FROM gs_surchg.

  WRITE / '=== 驗證：Check Table 換成標準表，Open SQL 依然不受外鍵約束 ==='.
  WRITE: / 'INSERT CARRID=ZZ（SCARR 沒有這家航空公司）：sy-subrc =', sy-subrc.
  WRITE / '  → 結論不變：外鍵只在畫面輸入生效，Open SQL 呼叫不受影響'.

  DELETE FROM ztr25_surchg WHERE carrid = 'ZZ'.     " 清掉測試資料，不污染正式設定
  COMMIT WORK.
