*&---------------------------------------------------------------------*
*& Report  ZR_TR25_DDIC
*& 練習 25：Data Dictionary 總覽與 Global Type（答案程式）
*& 前提：SE11 已建立並啟用 ZTR25_SURCHG（欄位規格見 ex25 第一部分，
*&       CARRID 重用標準 Data Element S_CARR_ID、Check Table 指向標準表 SCARR）、
*&       Table Type ZTR25_TT_SURCHG（Line Type = ZTR25_SURCHG，Standard Table）
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

DATA: gt_rev            TYPE STANDARD TABLE OF ty_rev,
      gv_carrid_global  TYPE s_carr_id,              " Global Type：引用標準 Data Element
      gv_carrid_hard    TYPE c LENGTH 3.             " 反面教材：寫死長度

START-OF-SELECTION.
  PERFORM demo_global_type.
  PERFORM demo_table_type.
  PERFORM get_data.
  PERFORM display_data.
  PERFORM demo_fk_bypass.
  COMMIT WORK.

*&---------------------------------------------------------------------*
*&      Form  demo_global_type
*&      對照兩種宣告方式：引用 Global Type vs 寫死長度
*&      現在看起來一樣，SAP 標準若調整 S_CARR_ID 的長度，
*&      gv_carrid_global 自動跟著變，gv_carrid_hard 不會（見講義 25 第 2.1 節）
*&---------------------------------------------------------------------*
FORM demo_global_type.
  gv_carrid_global = 'LH'.
  gv_carrid_hard   = 'LH'.

  WRITE / '=== Global Type 示範 ==='.
  WRITE: / 'lv_carrid_global（TYPE s_carr_id）：', gv_carrid_global.
  WRITE / '  → 型別／長度／標籤／F4 全部繼承自標準 Data Element，SAP 升級調整它，這裡自動跟著變'.
  WRITE: / 'lv_carrid_hard（TYPE c LENGTH 3）：', gv_carrid_hard.
  WRITE / '  → 看起來結果一樣，但長度是寫死的——S_CARR_ID 若改長，這裡不會自動變寬，是條隱藏地雷'.
  SKIP.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  demo_table_type
*&      DDIC Table Type：跟講義 4 的 Local Type 語法完全一樣，
*&      差別是 ZTR25_TT_SURCHG 定義在 SE11，任何程式/FM/方法都能重用同一份
*&---------------------------------------------------------------------*
FORM demo_table_type.
  DATA gt_surchg_raw TYPE ztr25_tt_surchg.

  PERFORM load_surchg_config CHANGING gt_surchg_raw.

  WRITE: / '讀到旺季加成設定：', lines( gt_surchg_raw ), '筆（DDIC Table Type ZTR25_TT_SURCHG）'.
  SKIP.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  load_surchg_config
*&      CHANGING 參數型別是 DDIC Table Type，不是本程式自己宣告的 Local Type——
*&      這個簽名可以原封不動被其他程式/FM 照抄使用
*&---------------------------------------------------------------------*
FORM load_surchg_config CHANGING ct_surchg TYPE ztr25_tt_surchg.
  SELECT * FROM ztr25_surchg
    INTO TABLE @ct_surchg.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  get_data
*&      LEFT OUTER JOIN：沒被財務設定過的航空公司也要出現在報表上
*&---------------------------------------------------------------------*
FORM get_data.
  SELECT f~carrid, c~carrname, f~connid, f~fldate, f~seatsocc, f~price,
         s~active, s~surcharge_pct
    FROM sflight AS f
    INNER JOIN scarr AS c ON c~carrid = f~carrid
    LEFT OUTER JOIN ztr25_surchg AS s ON s~carrid = f~carrid
    WHERE f~seatsocc > 0
    ORDER BY f~carrid, f~connid, f~fldate
    INTO CORRESPONDING FIELDS OF TABLE @gt_rev
    UP TO 100 ROWS.

  LOOP AT gt_rev ASSIGNING FIELD-SYMBOL(<ls_rev>).
    <ls_rev>-revenue = <ls_rev>-price * <ls_rev>-seatsocc.
    IF <ls_rev>-active = 'X'.
      <ls_rev>-revenue_adj = <ls_rev>-revenue * ( 1 + <ls_rev>-surcharge_pct / 100 ).
    ELSE.
      <ls_rev>-revenue_adj = <ls_rev>-revenue.
    ENDIF.
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

  WRITE / '=== 航班加成營收 ==='.
  LOOP AT gt_rev INTO DATA(gs_rev).
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
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  demo_fk_bypass
*&      驗證：Check Table 這次換成標準表 SCARR，結論依然不變——
*&      DDIC 外鍵只在畫面輸入生效，Open SQL 呼叫完全不受影響
*&---------------------------------------------------------------------*
FORM demo_fk_bypass.
  DATA gs_surchg TYPE ztr25_surchg.

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
ENDFORM.
