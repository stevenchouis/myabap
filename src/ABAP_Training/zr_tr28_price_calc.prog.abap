REPORT zr_tr28_price_calc.

* 示範 ZTR28_CDISC（航空公司折扣主檔）真正被拿去用在業務計算的樣子：
* 輸入航空公司＋航班代碼，JOIN 標準示範表 SPFLI（航線）/SFLIGHT（航班），
* 套用該航空公司維護的折扣百分比，算出每個航班的最終票價。

TABLES: sscrfields.

PARAMETERS: p_carrid TYPE spfli-carrid DEFAULT 'LH' OBLIGATORY,
            p_connid TYPE spfli-connid DEFAULT '0400' OBLIGATORY.

SELECTION-SCREEN FUNCTION KEY 1.

TYPES: BEGIN OF ty_result,
         carrid       TYPE sflight-carrid,
         connid       TYPE sflight-connid,
         cityfrom     TYPE spfli-cityfrom,
         cityto       TYPE spfli-cityto,
         fldate       TYPE sflight-fldate,
         price        TYPE sflight-price,
         currency     TYPE sflight-currency,
         discount_pct TYPE ztr28_cdisc-discount_pct,
         final_price  TYPE sflight-price,
       END OF ty_result.

DATA: gt_result   TYPE STANDARD TABLE OF ty_result,
      gs_result   TYPE ty_result,
      gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_fieldcat TYPE slis_fieldcat_alv.

DEFINE mc_add_field.
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = &1.
  gs_fieldcat-seltext_l = &2.
  gs_fieldcat-outputlen = &3.
  APPEND gs_fieldcat TO gt_fieldcat.
END-OF-DEFINITION.

INITIALIZATION.
  sscrfields-functxt_01 = '維護主檔(SM30)'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      " 跟 ZR_TR28_PARAM_LIST 同一顆按鈕邏輯：直接呼叫 ZTR28_SM30（SE93 Parameter
      " Transaction 包 SM30），方便從計算報表的選取畫面直接跳去改折扣，改完馬上
      " 重新執行本報表就能看到 final_price 連動——這是驗證 Wrapper／DDIC 有沒有
      " 接對的最快方式。這顆按鈕一樣不經過 ZR_TR28_PARAM_MAINT 那個 Wrapper。
      CALL TRANSACTION 'ZTR28_SM30'.
  ENDCASE.

START-OF-SELECTION.
* ---- 1. 航線是否存在（SPFLI 主鍵 CARRID+CONNID）----
  SELECT SINGLE cityfrom, cityto
    FROM spfli
    WHERE carrid = @p_carrid
      AND connid = @p_connid
    INTO (@DATA(lv_cityfrom), @DATA(lv_cityto)).

  IF sy-subrc <> 0.
    WRITE: / '找不到航線', p_carrid, p_connid, '（SPFLI 沒有這筆資料）'.
    RETURN.
  ENDIF.

* ---- 2. 這條航線目前有哪些航班（SFLIGHT，可能好幾個航班日期）----
  SELECT carrid, connid, fldate, price, currency
    FROM sflight
    WHERE carrid = @p_carrid
      AND connid = @p_connid
    ORDER BY fldate
    INTO TABLE @DATA(lt_sflight).

  IF sy-subrc <> 0.
    WRITE: / '航線', p_carrid, p_connid, '目前沒有任何航班資料（SFLIGHT）'.
    RETURN.
  ENDIF.

* ---- 3. 這家航空公司的折扣（ZTR28_CDISC，由 ZR_TR28_PARAM_MAINT 維護）----
* 折扣是選配：沒有維護就當作 0（不打折），不擋報表執行。
  SELECT SINGLE discount_pct
    FROM ztr28_cdisc
    WHERE carrid = @p_carrid
    INTO @DATA(lv_discount_pct).

  IF sy-subrc <> 0.
    lv_discount_pct = 0.
    WRITE: / '（', p_carrid, '尚未維護折扣，本次以 0% 計算）'.
  ELSE.
    WRITE: / '（', p_carrid, '目前折扣', lv_discount_pct, '%）'.
  ENDIF.

* ---- 4. 逐航班套用折扣算最終票價 ----
  LOOP AT lt_sflight INTO DATA(ls_sflight).
    CLEAR gs_result.
    gs_result-carrid       = ls_sflight-carrid.
    gs_result-connid       = ls_sflight-connid.
    gs_result-cityfrom     = lv_cityfrom.
    gs_result-cityto       = lv_cityto.
    gs_result-fldate       = ls_sflight-fldate.
    gs_result-price        = ls_sflight-price.
    gs_result-currency     = ls_sflight-currency.
    gs_result-discount_pct = lv_discount_pct.
    gs_result-final_price  = ls_sflight-price * ( 1 - lv_discount_pct / 100 ).
    APPEND gs_result TO gt_result.
  ENDLOOP.

  mc_add_field 'CARRID'       '航空公司'   10.
  mc_add_field 'CONNID'       '航班代碼'   10.
  mc_add_field 'CITYFROM'     '起飛城市'   20.
  mc_add_field 'CITYTO'       '抵達城市'   20.
  mc_add_field 'FLDATE'       '航班日期'   10.
  mc_add_field 'PRICE'        '原價'       12.
  mc_add_field 'CURRENCY'     '幣別'       6.
  mc_add_field 'DISCOUNT_PCT' '折扣百分比' 12.
  mc_add_field 'FINAL_PRICE'  '最終票價'   12.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      it_fieldcat        = gt_fieldcat
    TABLES
      t_outtab           = gt_result
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
    WRITE: / 'ALV 顯示失敗'.
  ENDIF.
