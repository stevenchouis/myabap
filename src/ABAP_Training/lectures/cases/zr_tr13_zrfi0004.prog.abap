*&---------------------------------------------------------------------*
*& Report ZR_TR13_ZRFI0004
*&---------------------------------------------------------------------*
*& 傳票清單範例程式（講義 13 第 6.2 節）
*& 用第一階段各講的寫法，完成實務程式 ZRFI0004 同樣的功能。
*& 已與 ZRFI0004 實際比對：輸出逐行相同（唯一差異見講義 6.2 的驗證結果）。
*&
*& 需求來源 ZRFI0004 的歷次需求：
*&   2008/08 DEVK928193    "A" 類資產科目，資產號碼放在對象代號名稱欄位
*&   2010/01 SNBK900170    內文改為兩行顯示
*&   2023/08 SAP-PIC-ADD-20230724  增印會計主管、覆核的姓名及日期
*&   2023/10~12            頁尾改在輸出明細時印、每張傳票各自計算頁碼
*&   2025/09 SAP_PIC-FI_20250224   離職員工的簽核姓名改查供應商主檔
*&---------------------------------------------------------------------*
REPORT zr_tr13_zrfi0004 NO STANDARD PAGE HEADING
                        LINE-SIZE 203
                        LINE-COUNT 65(0).     " 頁尾自己印，不保留（講義 13 §6.1）

TABLES sscrfields.                            " 選擇畫面功能鍵（講義 28）
TYPE-POOLS icon.

*----------------------------------------------------------------------*
* 型別
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_dochd,                     " 傳票表頭
         bukrs    TYPE bkpf-bukrs,
         belnr    TYPE bkpf-belnr,
         gjahr    TYPE bkpf-gjahr,
         blart    TYPE bkpf-blart,
         bldat    TYPE bkpf-bldat,
         budat    TYPE bkpf-budat,
         usnam    TYPE bkpf-usnam,            " 過帳者（覆核）
         ppnam    TYPE bkpf-ppnam,            " 暫存者（製票員）
         xblnr    TYPE bkpf-xblnr,
         bktxt    TYPE bkpf-bktxt,
         waers    TYPE bkpf-waers,
         kursf    TYPE bkpf-kursf,
         bstat    TYPE bkpf-bstat,
         hwaer    TYPE bkpf-hwaer,
         tcode    TYPE bkpf-tcode,
         cpudt    TYPE bkpf-cpudt,
         xref2_hd TYPE bkpf-xref2_hd,         " 暫存文件建立日
         acctname TYPE zfi0037-acctname,      " 會計主管姓名
       END OF ty_dochd,

       BEGIN OF ty_docit,                     " 傳票明細
         bukrs TYPE bseg-bukrs,
         belnr TYPE bseg-belnr,
         gjahr TYPE bseg-gjahr,
         buzei TYPE bseg-buzei,
         bschl TYPE bseg-bschl,
         koart TYPE bseg-koart,
         shkzg TYPE bseg-shkzg,
         mwskz TYPE bseg-mwskz,
         dmbtr TYPE bseg-dmbtr,
         wrbtr TYPE bseg-wrbtr,
         zuonr TYPE bseg-zuonr,
         sgtxt TYPE bseg-sgtxt,
         xref1 TYPE bseg-xref1,
         xref2 TYPE bseg-xref2,
         xref3 TYPE bseg-xref3,
         kokrs TYPE bseg-kokrs,
         kostl TYPE bseg-kostl,
         prctr TYPE bseg-prctr,
         hkont TYPE bseg-hkont,
         kunnr TYPE bseg-kunnr,
         lifnr TYPE bseg-lifnr,
         anln1 TYPE bseg-anln1,
         matnr TYPE bseg-matnr,
         aufnr TYPE bseg-aufnr,
         txt50 TYPE skat-txt50,               " 科目名稱
         ltext TYPE cskt-ltext,               " 成本中心名稱
         ptext TYPE cepct-ltext,              " 利潤中心名稱
       END OF ty_docit,
       ty_t_docit TYPE STANDARD TABLE OF ty_docit WITH DEFAULT KEY,

       BEGIN OF ty_acct,                     " 會計主管（依生效日）
         bukrs        TYPE zfi0037-bukrs,
         inauguration TYPE zfi0037-inauguration,
         acctname     TYPE zfi0037-acctname,
       END OF ty_acct,

       BEGIN OF ty_username,                  " 使用者姓名（查過就記下來）
         bname TYPE usr21-bname,
         name  TYPE c LENGTH 10,
       END OF ty_username,

       BEGIN OF ty_docpage,                   " 每張傳票的起訖頁（講義 13 §3.1）
         first_page TYPE i,
         last_page  TYPE i,
       END OF ty_docpage.

CONSTANTS gc_page_mark TYPE c LENGTH 6 VALUE '#PAGE#'.   " 頁碼佔位符

*----------------------------------------------------------------------*
* 資料
*----------------------------------------------------------------------*
DATA: gt_dochd       TYPE STANDARD TABLE OF ty_dochd,
      gs_dochd       TYPE ty_dochd,           " 目前輸出中的傳票（TOP-OF-PAGE 也讀它）
      gt_docit       TYPE STANDARD TABLE OF ty_docit,
      gt_domval      TYPE STANDARD TABLE OF dd07v,     " 文件狀態 Domain 固定值
      gv_status_text TYPE dd07v-ddtext,       " 目前傳票的文件狀態說明
      gt_username    TYPE STANDARD TABLE OF ty_username,
      gt_docpage     TYPE STANDARD TABLE OF ty_docpage,
      gv_butxt       TYPE t001-butxt,
      gv_ktopl       TYPE t001-ktopl,
      gv_kokrs       TYPE tka01-kokrs,
      gv_item_mode   TYPE c LENGTH 1,         " 'X'＝本頁印明細，頁首要印欄位標題
      gv_page_line   TYPE i,                  " 頁尾「頁碼」所在的行號
      gs_functxt     TYPE smp_dyntxt.

* 欄位座標表：每個欄位的輸出寬度（講義 12）
DATA: BEGIN OF gs_width,
        hkont TYPE i VALUE 30,
        xref1 TYPE i VALUE 12,
        kostl TYPE i VALUE 10,
        prctr TYPE i VALUE 10,
        aufnr TYPE i VALUE 12,
        zuonr TYPE i VALUE 18,
        xref3 TYPE i VALUE 20,
        dbamt TYPE i VALUE 16,
        cdamt TYPE i VALUE 16,
        sgtxt TYPE i VALUE 50,
      END OF gs_width.

* 選擇畫面的參考欄位（取代 TABLES bkpf，講義 7 §3.0）
DATA: gv_belnr TYPE bkpf-belnr,
      gv_gjahr TYPE bkpf-gjahr,
      gv_blart TYPE bkpf-blart,
      gv_budat TYPE bkpf-budat,
      gv_bldat TYPE bkpf-bldat,
      gv_cpudt TYPE bkpf-cpudt,
      gv_usnam TYPE bkpf-usnam,
      gv_ppnam TYPE bkpf-ppnam,
      gv_bstat TYPE bkpf-bstat.

*----------------------------------------------------------------------*
* 選擇畫面
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
PARAMETERS p_bukrs TYPE bkpf-bukrs OBLIGATORY DEFAULT '1000'.
SELECT-OPTIONS: s_belnr FOR gv_belnr,
                s_gjahr FOR gv_gjahr DEFAULT sy-datum,
                s_blart FOR gv_blart,
                s_budat FOR gv_budat,
                s_bldat FOR gv_bldat,         " 注意：原程式沒有用到這個條件（見講義 13 §6.2）
                s_cpudt FOR gv_cpudt,
                s_usnam FOR gv_usnam MATCHCODE OBJECT user_addr,
                s_ppnam FOR gv_ppnam MATCHCODE OBJECT user_addr,
                s_bstat FOR gv_bstat NO-DISPLAY.   " 由下面三個勾選框組出來

SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE text-t02.
PARAMETERS: p_post AS CHECKBOX DEFAULT 'X',   " 過帳文件
            p_park AS CHECKBOX,               " 暫存文件
            p_pdel AS CHECKBOX.               " 被刪除的暫存文件
SELECTION-SCREEN END OF BLOCK blk2.
SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN FUNCTION KEY 1.              " 維護會計主管
SELECTION-SCREEN FUNCTION KEY 2.              " 查詢會計主管

*----------------------------------------------------------------------*
* 事件
*----------------------------------------------------------------------*
INITIALIZATION.
  PERFORM set_function_keys.

AT SELECTION-SCREEN.
  PERFORM check_company_code.
  PERFORM check_authority.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      CALL TRANSACTION 'ZFI0037'.
    WHEN 'FC02'.
      CALL TRANSACTION 'ZFI0037Q'.
  ENDCASE.

START-OF-SELECTION.
  PERFORM build_status_range.
  PERFORM get_header_data.
  PERFORM get_item_data.
  PERFORM get_text_data.

END-OF-SELECTION.
  PERFORM write_report.
  PERFORM fill_page_numbers.

TOP-OF-PAGE.
  PERFORM write_header.
  PERFORM write_column_title.

*&---------------------------------------------------------------------*
*& 選擇畫面上的兩顆工具按鈕
*&---------------------------------------------------------------------*
FORM set_function_keys.
  gs_functxt-icon_id   = icon_tools.
  gs_functxt-icon_text = text-t03.
  sscrfields-functxt_01 = gs_functxt.

  CLEAR gs_functxt.
  gs_functxt-icon_id   = icon_tools.
  gs_functxt-icon_text = text-t04.
  sscrfields-functxt_02 = gs_functxt.
ENDFORM.

*&---------------------------------------------------------------------*
*& 檢查公司代碼，順便取得科目表與成本控制範圍
*&---------------------------------------------------------------------*
FORM check_company_code.
  CLEAR: gv_butxt, gv_ktopl, gv_kokrs.
  SELECT SINGLE butxt ktopl INTO (gv_butxt, gv_ktopl)
    FROM t001
    WHERE bukrs = p_bukrs.
  IF sy-subrc <> 0.
    MESSAGE e014(fipos) WITH p_bukrs.
  ENDIF.

  SELECT SINGLE kokrs INTO gv_kokrs
    FROM tka01
    WHERE ktopl = gv_ktopl.
ENDFORM.

*&---------------------------------------------------------------------*
*& 權限：公司代碼有新增、修改、顯示任一權限即可
*&---------------------------------------------------------------------*
FORM check_authority.
  AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
    ID 'BUKRS' FIELD p_bukrs
    ID 'ACTVT' FIELD '01'.
  IF sy-subrc <> 0.
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
      ID 'BUKRS' FIELD p_bukrs
      ID 'ACTVT' FIELD '02'.
  ENDIF.
  IF sy-subrc <> 0.
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
      ID 'BUKRS' FIELD p_bukrs
      ID 'ACTVT' FIELD '03'.
  ENDIF.
  IF sy-subrc <> 0.
    MESSAGE e460(f5) WITH p_bukrs.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& 把三個勾選框轉成文件狀態的 range 表 s_bstat
*&---------------------------------------------------------------------*
FORM build_status_range.
  DATA: ls_domval TYPE dd07v,
        ls_bstat  LIKE LINE OF s_bstat.

  CALL FUNCTION 'GET_DOMAIN_VALUES'
    EXPORTING
      domname         = 'BSTAT'
      text            = 'X'
    TABLES
      values_tab      = gt_domval
    EXCEPTIONS
      no_values_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CLEAR s_bstat[].
  ls_bstat-sign   = 'I'.
  ls_bstat-option = 'EQ'.
  LOOP AT gt_domval INTO ls_domval.
*   V＝暫存文件、W＝更改過文件識別的暫存文件、Z＝被刪除的暫存文件，其餘為過帳文件
    IF ( p_post = 'X' AND ls_domval-domvalue_l <> 'V'
                      AND ls_domval-domvalue_l <> 'W'
                      AND ls_domval-domvalue_l <> 'Z' )
    OR ( p_park = 'X' AND ( ls_domval-domvalue_l = 'V' OR ls_domval-domvalue_l = 'W' ) )
    OR ( p_pdel = 'X' AND ls_domval-domvalue_l = 'Z' ).
      ls_bstat-low = ls_domval-domvalue_l.
      APPEND ls_bstat TO s_bstat.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& 讀傳票表頭，並找出每張傳票適用的會計主管
*&---------------------------------------------------------------------*
FORM get_header_data.
  DATA: lt_acct TYPE STANDARD TABLE OF ty_acct,
        ls_acct TYPE ty_acct,
        lv_date TYPE d.
  FIELD-SYMBOLS <ls_dochd> TYPE ty_dochd.

  SELECT bukrs belnr gjahr blart bldat budat usnam ppnam xblnr bktxt
         waers kursf bstat hwaer tcode cpudt xref2_hd
    INTO CORRESPONDING FIELDS OF TABLE gt_dochd
    FROM bkpf
    WHERE bukrs = p_bukrs
      AND belnr IN s_belnr
      AND gjahr IN s_gjahr
      AND blart IN s_blart
      AND budat IN s_budat
      AND cpudt IN s_cpudt
      AND usnam IN s_usnam
      AND bstat IN s_bstat
      AND ppnam IN s_ppnam.
  IF gt_dochd IS INITIAL.
    MESSAGE i001(fot_b2a).
    STOP.                                     " 仍會觸發 END-OF-SELECTION（講義 10）
  ENDIF.
  SORT gt_dochd BY bukrs belnr gjahr.

* 會計主管一次讀完，依生效日由新到舊排，迴圈裡不再查資料庫
  SELECT bukrs inauguration acctname
    INTO TABLE lt_acct
    FROM zfi0037
    WHERE bukrs = p_bukrs.
  SORT lt_acct BY inauguration DESCENDING.

  LOOP AT gt_dochd ASSIGNING <ls_dochd>.
*   用哪一天找會計主管：沖銷類交易用輸入日，其餘有暫存建立日就用暫存建立日
    IF <ls_dochd>-tcode = 'FB08' OR <ls_dochd>-tcode = 'F.80' OR <ls_dochd>-tcode = 'MR8M'
       OR <ls_dochd>-xref2_hd IS INITIAL.
      lv_date = <ls_dochd>-cpudt.
    ELSE.
      lv_date = <ls_dochd>-xref2_hd.
    ENDIF.

*   排在最前面、生效日不晚於該日的，就是當時的會計主管
    LOOP AT lt_acct INTO ls_acct WHERE inauguration <= lv_date.
      <ls_dochd>-acctname = ls_acct-acctname.
      EXIT.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& 讀傳票明細：過帳文件讀 BSEG，暫存文件讀四張 VBSEG* 後合併
*&---------------------------------------------------------------------*
FORM get_item_data.
  DATA lt_park TYPE ty_t_docit.

  IF p_post = 'X'.
    SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_docit
      FROM bseg
      FOR ALL ENTRIES IN gt_dochd              " gt_dochd 不會是空的：前面查無資料已 STOP
      WHERE bukrs = gt_dochd-bukrs
        AND belnr = gt_dochd-belnr
        AND gjahr = gt_dochd-gjahr.
  ENDIF.

  IF p_park = 'X' OR p_pdel = 'X'.
*   資產科目
    SELECT bukrs belnr gjahr buzei bschl shkzg mwskz dmbtr wrbtr zuonr sgtxt
           kostl hkont anln1 matnr aufnr
      INTO CORRESPONDING FIELDS OF TABLE lt_park
      FROM vbsega
      FOR ALL ENTRIES IN gt_dochd
      WHERE ausbk = gt_dochd-bukrs
        AND belnr = gt_dochd-belnr
        AND gjahr = gt_dochd-gjahr.
    PERFORM append_parked_items USING lt_park 'A'.

*   總帳科目（這張表的科目欄叫 SAKNR，用 AS 對上 HKONT）
    SELECT bukrs belnr gjahr buzei bschl koart shkzg mwskz dmbtr wrbtr zuonr sgtxt
           xref1 xref2 xref3 kokrs kostl prctr saknr AS hkont anln1 matnr aufnr
      INTO CORRESPONDING FIELDS OF TABLE lt_park
      FROM vbsegs
      FOR ALL ENTRIES IN gt_dochd
      WHERE ausbk = gt_dochd-bukrs
        AND belnr = gt_dochd-belnr
        AND gjahr = gt_dochd-gjahr.
    PERFORM append_parked_items USING lt_park space.

*   客戶
    SELECT bukrs belnr gjahr buzei bschl shkzg mwskz dmbtr wrbtr zuonr sgtxt
           xref1 xref2 xref3 hkont kunnr
      INTO CORRESPONDING FIELDS OF TABLE lt_park
      FROM vbsegd
      FOR ALL ENTRIES IN gt_dochd
      WHERE ausbk = gt_dochd-bukrs
        AND belnr = gt_dochd-belnr
        AND gjahr = gt_dochd-gjahr.
    PERFORM append_parked_items USING lt_park 'D'.

*   供應商
    SELECT bukrs belnr gjahr buzei bschl shkzg mwskz dmbtr wrbtr zuonr sgtxt
           xref1 xref2 xref3 hkont lifnr
      INTO CORRESPONDING FIELDS OF TABLE lt_park
      FROM vbsegk
      FOR ALL ENTRIES IN gt_dochd
      WHERE ausbk = gt_dochd-bukrs
        AND belnr = gt_dochd-belnr
        AND gjahr = gt_dochd-gjahr.
    PERFORM append_parked_items USING lt_park 'K'.
  ENDIF.

  SORT gt_docit BY bukrs belnr gjahr buzei.
ENDFORM.

*&---------------------------------------------------------------------*
*& 暫存明細補上科目類型後併入 gt_docit（p_koart 空白＝沿用讀到的值）
*&---------------------------------------------------------------------*
FORM append_parked_items USING pt_park  TYPE ty_t_docit
                               p_koart  TYPE bseg-koart.
  DATA ls_docit TYPE ty_docit.

  LOOP AT pt_park INTO ls_docit.
    IF p_koart IS NOT INITIAL.
      ls_docit-koart = p_koart.
    ENDIF.
    APPEND ls_docit TO gt_docit.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& 補上名稱類欄位：先整批讀進內表，迴圈裡只查內表（講義 11 §6）
*&---------------------------------------------------------------------*
FORM get_text_data.
  TYPES: BEGIN OF lty_skat,
           saknr TYPE skat-saknr,
           txt50 TYPE skat-txt50,
         END OF lty_skat,
         BEGIN OF lty_partner,                " 客戶或供應商的地址號碼
           partner TYPE kna1-kunnr,
           adrnr   TYPE kna1-adrnr,
         END OF lty_partner,
         BEGIN OF lty_adrc,
           addrnumber TYPE adrc-addrnumber,
           sort1      TYPE adrc-sort1,
         END OF lty_adrc,
         BEGIN OF lty_cskt,
           kostl TYPE cskt-kostl,
           datbi TYPE cskt-datbi,
           ktext TYPE cskt-ktext,
         END OF lty_cskt,
         BEGIN OF lty_cepct,
           prctr TYPE cepct-prctr,
           datbi TYPE cepct-datbi,
           ktext TYPE cepct-ktext,
         END OF lty_cepct.

  DATA: lt_skat    TYPE STANDARD TABLE OF lty_skat,
        ls_skat    TYPE lty_skat,
        lt_kna1    TYPE STANDARD TABLE OF lty_partner,
        lt_lfa1    TYPE STANDARD TABLE OF lty_partner,
        lt_address TYPE STANDARD TABLE OF lty_partner,
        ls_partner TYPE lty_partner,
        lt_adrc    TYPE STANDARD TABLE OF lty_adrc,
        ls_adrc    TYPE lty_adrc,
        lt_cskt    TYPE STANDARD TABLE OF lty_cskt,
        ls_cskt    TYPE lty_cskt,
        lt_cepct   TYPE STANDARD TABLE OF lty_cepct,
        ls_cepct   TYPE lty_cepct,
        lv_partner TYPE kna1-kunnr.
  FIELD-SYMBOLS <ls_docit> TYPE ty_docit.

  CHECK gt_docit IS NOT INITIAL.              " FOR ALL ENTRIES 的空表防呆

* 1. 整批讀取
  SELECT saknr txt50 INTO TABLE lt_skat
    FROM skat
    FOR ALL ENTRIES IN gt_docit
    WHERE spras = sy-langu
      AND ktopl = gv_ktopl
      AND saknr = gt_docit-hkont.

  SELECT kunnr adrnr INTO TABLE lt_kna1
    FROM kna1
    FOR ALL ENTRIES IN gt_docit
    WHERE kunnr = gt_docit-kunnr.

  SELECT lifnr adrnr INTO TABLE lt_lfa1
    FROM lfa1
    FOR ALL ENTRIES IN gt_docit
    WHERE lifnr = gt_docit-lifnr.

  APPEND LINES OF lt_kna1 TO lt_address.
  APPEND LINES OF lt_lfa1 TO lt_address.
  IF lt_address IS NOT INITIAL.
    SELECT addrnumber sort1 INTO TABLE lt_adrc
      FROM adrc
      FOR ALL ENTRIES IN lt_address
      WHERE addrnumber = lt_address-adrnr
        AND date_from <= sy-datum
        AND nation    = space
        AND date_to   >= sy-datum.
  ENDIF.

  SELECT kostl datbi ktext INTO TABLE lt_cskt
    FROM cskt
    FOR ALL ENTRIES IN gt_docit
    WHERE spras = sy-langu
      AND kokrs = gv_kokrs
      AND kostl = gt_docit-kostl
      AND datbi >= sy-datum.
  SORT lt_cskt BY kostl datbi.                " 同一成本中心取最早到期的有效資料

  SELECT prctr datbi ktext INTO TABLE lt_cepct
    FROM cepct
    FOR ALL ENTRIES IN gt_docit
    WHERE spras = sy-langu
      AND prctr = gt_docit-prctr
      AND datbi >= sy-datum
      AND kokrs = gv_kokrs.
  SORT lt_cepct BY prctr datbi.

* 2. 逐筆補欄位，只查內表
  LOOP AT gt_docit ASSIGNING <ls_docit>.
    READ TABLE lt_skat INTO ls_skat WITH KEY saknr = <ls_docit>-hkont.
    IF sy-subrc = 0.
      <ls_docit>-txt50 = ls_skat-txt50.
    ENDIF.

*   對象代號名稱：資產放資產號碼，客戶／供應商放搜尋名稱與代號
    CASE <ls_docit>-koart.
      WHEN 'A'.
        <ls_docit>-xref2 = <ls_docit>-anln1.
      WHEN 'D' OR 'K'.
        CLEAR: ls_partner, ls_adrc.
        IF <ls_docit>-koart = 'D'.
          lv_partner = <ls_docit>-kunnr.
          READ TABLE lt_kna1 INTO ls_partner WITH KEY partner = lv_partner.
        ELSE.
          lv_partner = <ls_docit>-lifnr.
          READ TABLE lt_lfa1 INTO ls_partner WITH KEY partner = lv_partner.
        ENDIF.
        IF lv_partner IS NOT INITIAL.          " 有客戶／供應商代號才覆寫這兩欄
          IF ls_partner-adrnr IS NOT INITIAL.
            READ TABLE lt_adrc INTO ls_adrc WITH KEY addrnumber = ls_partner-adrnr.
          ENDIF.
          <ls_docit>-xref1 = ls_adrc-sort1.     " 搜尋名稱
          <ls_docit>-xref2 = lv_partner.        " 代號
        ENDIF.
    ENDCASE.

    IF <ls_docit>-kostl IS NOT INITIAL.
      READ TABLE lt_cskt INTO ls_cskt WITH KEY kostl = <ls_docit>-kostl.
      IF sy-subrc = 0.
        <ls_docit>-ltext = ls_cskt-ktext.
      ENDIF.
    ENDIF.

    IF <ls_docit>-prctr IS NOT INITIAL.
      READ TABLE lt_cepct INTO ls_cepct WITH KEY prctr = <ls_docit>-prctr.
      IF sy-subrc = 0.
        <ls_docit>-ptext = ls_cepct-ktext.
      ENDIF.
    ENDIF.

*   進項／銷項稅額科目：內文改放稅碼
    IF <ls_docit>-hkont = '0000128200' OR <ls_docit>-hkont = '0000229200'.
      <ls_docit>-sgtxt = <ls_docit>-mwskz.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& 輸出：一張傳票一份（每頁 10 筆明細，底部固定印簽核欄與頁尾）
*&---------------------------------------------------------------------*
FORM write_report.
  DATA: ls_docit       TYPE ty_docit,
        ls_domval      TYPE dd07v,
        ls_docpage     TYPE ty_docpage,
        lv_item_doc    TYPE c LENGTH 1,        " 'X'＝這張要印明細（過帳或暫存，且未刪除）
        lv_item_cnt    TYPE i,
        lv_idx         TYPE i,
        lv_page_debit  TYPE bseg-wrbtr,        " 本頁合計
        lv_page_credit TYPE bseg-wrbtr,
        lv_doc_debit   TYPE bseg-wrbtr,        " 累頁合計
        lv_doc_credit  TYPE bseg-wrbtr,
        lv_bname       TYPE usr21-bname,
        lv_ppnam       TYPE c LENGTH 10,       " 製票員姓名
        lv_usnam       TYPE c LENGTH 10.       " 覆核者姓名

  LOOP AT gt_dochd INTO gs_dochd.
    NEW-PAGE.                                   " 每張傳票從新的一頁開始
    CLEAR: ls_docpage, lv_page_debit, lv_page_credit, lv_doc_debit, lv_doc_credit.

    IF gs_dochd-kursf IS INITIAL.
      gs_dochd-kursf = 1.
    ENDIF.

    CLEAR gv_status_text.
    READ TABLE gt_domval INTO ls_domval WITH KEY domvalue_l = gs_dochd-bstat.
    IF sy-subrc = 0.
      gv_status_text = ls_domval-ddtext.
    ENDIF.

*   製票員：暫存者空白時以過帳者代替；覆核：過帳者
    IF gs_dochd-ppnam IS INITIAL.
      lv_bname = gs_dochd-usnam.
    ELSE.
      lv_bname = gs_dochd-ppnam.
    ENDIF.
    PERFORM get_user_name USING lv_bname CHANGING lv_ppnam.
    PERFORM get_user_name USING gs_dochd-usnam CHANGING lv_usnam.

    CLEAR lv_item_doc.
    IF ( p_post = 'X' OR p_park = 'X' ) AND gs_dochd-bstat <> 'Z'.
      lv_item_doc = 'X'.
    ENDIF.

    lv_item_cnt = 0.
    LOOP AT gt_docit INTO ls_docit WHERE bukrs = gs_dochd-bukrs
                                     AND belnr = gs_dochd-belnr
                                     AND gjahr = gs_dochd-gjahr.
      lv_item_cnt = lv_item_cnt + 1.
    ENDLOOP.

    IF lv_item_doc = 'X' AND lv_item_cnt > 0.
*     有明細：每 10 筆一頁，每頁底部印簽核欄與頁尾
      gv_item_mode = 'X'.
      lv_idx = 0.
      LOOP AT gt_docit INTO ls_docit WHERE bukrs = gs_dochd-bukrs
                                       AND belnr = gs_dochd-belnr
                                       AND gjahr = gs_dochd-gjahr.
        lv_idx = lv_idx + 1.
        PERFORM write_item USING    ls_docit
                           CHANGING lv_page_debit lv_page_credit
                                    lv_doc_debit  lv_doc_credit.
        IF ls_docpage-first_page = 0.
          ls_docpage-first_page = sy-pagno.     " 第一筆寫出後，就是這張的第一頁
        ENDIF.

        IF lv_idx MOD 10 = 0 OR lv_idx = lv_item_cnt.
          PERFORM write_sign_block USING lv_ppnam lv_usnam
                                         lv_page_debit lv_page_credit
                                         lv_doc_debit  lv_doc_credit.
          CLEAR: lv_page_debit, lv_page_credit.
        ENDIF.
      ENDLOOP.

    ELSEIF lv_item_doc = 'X' OR ( p_pdel = 'X' AND gs_dochd-bstat = 'Z' ).
*     沒有明細、或被刪除的暫存文件：只印表頭資訊與簽核欄
      CLEAR gv_item_mode.
      PERFORM write_doc_info.
      ls_docpage-first_page = sy-pagno.
      ULINE.
      PERFORM write_sign_block USING lv_ppnam lv_usnam
                                     lv_page_debit lv_page_credit
                                     lv_doc_debit  lv_doc_credit.
    ELSE.
      CONTINUE.
    ENDIF.

    ls_docpage-last_page = sy-pagno.            " 簽核欄印完，就是這張的最後一頁
    APPEND ls_docpage TO gt_docpage.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& 一筆明細：三行（兩行內容＋一條虛線）
*&---------------------------------------------------------------------*
FORM write_item USING    ps_docit       TYPE ty_docit
                CHANGING pv_page_debit  TYPE bseg-wrbtr
                         pv_page_credit TYPE bseg-wrbtr
                         pv_doc_debit   TYPE bseg-wrbtr
                         pv_doc_credit  TYPE bseg-wrbtr.
  DATA: lv_sgtxt1 TYPE c LENGTH 50,            " 內文第一行
        lv_sgtxt2 TYPE c LENGTH 50,            " 內文第二行
        lv_xref1  TYPE c LENGTH 50,
        lv_ltext  TYPE c LENGTH 50,
        lv_ptext  TYPE c LENGTH 50,
        lv_rest   TYPE c LENGTH 50.            " 超出寬度的部分，不印

* 依實際顯示寬度切字，中文字不會被從中間切斷（講義 12 §2.1）
  PERFORM split_by_width USING ps_docit-sgtxt 50 100 CHANGING lv_sgtxt1 lv_sgtxt2.
  PERFORM split_by_width USING ps_docit-xref1 12 0   CHANGING lv_xref1 lv_rest.
  PERFORM split_by_width USING ps_docit-ltext 10 0   CHANGING lv_ltext lv_rest.
  PERFORM split_by_width USING ps_docit-ptext 10 0   CHANGING lv_ptext lv_rest.

* 第一行：科目、對象代號、成本中心……金額、內文
  WRITE: AT /01(gs_width-hkont) ps_docit-hkont,
         AT    (gs_width-xref1) ps_docit-xref2,
         AT    (gs_width-kostl) ps_docit-kostl,
         AT    (gs_width-prctr) ps_docit-prctr,
         AT    (gs_width-aufnr) ps_docit-aufnr,
         AT    (gs_width-zuonr) ps_docit-zuonr,
         AT    (gs_width-xref3) ps_docit-xref3.
  CASE ps_docit-shkzg.
    WHEN 'S'.                                   " 借方
      WRITE: AT (gs_width-dbamt) ps_docit-wrbtr CURRENCY gs_dochd-waers,
             AT (gs_width-cdamt) ''.
      pv_page_debit = pv_page_debit + ps_docit-wrbtr.
      pv_doc_debit  = pv_doc_debit  + ps_docit-wrbtr.
    WHEN 'H'.                                   " 貸方
      WRITE: AT (gs_width-dbamt) '',
             AT (gs_width-cdamt) ps_docit-wrbtr CURRENCY gs_dochd-waers.
      pv_page_credit = pv_page_credit + ps_docit-wrbtr.
      pv_doc_credit  = pv_doc_credit  + ps_docit-wrbtr.
  ENDCASE.
  WRITE AT (gs_width-sgtxt) lv_sgtxt1.
  SKIP.                                         " 兩行內容之間空一行

* 第二行：科目名稱、對象名稱、成本中心名稱、利潤中心名稱、內文第二行
  WRITE: AT /01(gs_width-hkont) ps_docit-txt50,
         AT    (gs_width-xref1) lv_xref1,
         AT    (gs_width-kostl) lv_ltext,
         AT    (gs_width-prctr) lv_ptext,
         AT    (gs_width-aufnr) space,
         AT    (gs_width-zuonr) space,
         AT    (gs_width-xref3) space,
         AT    (gs_width-dbamt) space,
         AT    (gs_width-cdamt) space,
         AT    (gs_width-sgtxt) lv_sgtxt2.

* 第三行：虛線
  WRITE: AT /01(gs_width-hkont) '------------------------------',
         AT    (gs_width-xref1) '------------',
         AT    (gs_width-kostl) '----------',
         AT    (gs_width-prctr) '----------',
         AT    (gs_width-aufnr) '------------',
         AT    (gs_width-zuonr) '------------------',
         AT    (gs_width-xref3) '-------------------',
         AT    (gs_width-dbamt) '----------------',
         AT    (gs_width-cdamt) '----------------',
         AT    (gs_width-sgtxt) '--------------------------------------------------'.
ENDFORM.

*&---------------------------------------------------------------------*
*& 簽核欄（第 55 行起）＋頁尾：三種情況合併成一個 FORM
*&---------------------------------------------------------------------*
FORM write_sign_block USING pv_ppnam       TYPE c
                            pv_usnam       TYPE c
                            pv_page_debit  TYPE bseg-wrbtr
                            pv_page_credit TYPE bseg-wrbtr
                            pv_doc_debit   TYPE bseg-wrbtr
                            pv_doc_credit  TYPE bseg-wrbtr.
  DATA: lv_mgr_name   TYPE zfi0037-acctname,   " 會計主管
        lv_mgr_date   TYPE d,
        lv_rev_name   TYPE c LENGTH 10,        " 覆核
        lv_rev_date   TYPE d,
        lv_maker_name TYPE c LENGTH 10,        " 製票員
        lv_maker_date TYPE d.

* 決定三個簽核位置要印誰、印哪一天
  IF gs_dochd-acctname IS INITIAL.             " 沒有設定會計主管：只印製票員
    lv_maker_name = pv_ppnam.
  ELSEIF gs_dochd-bstat = 'V'.                 " 暫存文件：主管＋製票員（過帳者）＋建立日
    lv_mgr_name   = gs_dochd-acctname.
    lv_maker_name = pv_usnam.
    lv_maker_date = gs_dochd-cpudt.
  ELSE.                                        " 已過帳：主管、覆核、製票員都印，並印日期
    lv_mgr_name   = gs_dochd-acctname.
    lv_mgr_date   = gs_dochd-cpudt.
    lv_rev_name   = pv_usnam.
    lv_rev_date   = gs_dochd-cpudt.
    lv_maker_name = pv_ppnam.
    IF gs_dochd-xref2_hd IS NOT INITIAL
       AND gs_dochd-tcode <> 'FB08' AND gs_dochd-tcode <> 'F.80' AND gs_dochd-tcode <> 'MR8M'.
      lv_maker_date = gs_dochd-xref2_hd.       " 暫存文件建立日
    ELSE.
      lv_maker_date = gs_dochd-cpudt.
    ENDIF.
  ENDIF.

  SKIP TO LINE 55.
  ULINE.
  WRITE: AT /01(10) '會計主管：',
         AT  11(10) lv_mgr_name,
         AT  35(06) '覆核：',
         AT  41(10) lv_rev_name,
         AT  65(08) '製票員：',
         AT  73(10) lv_maker_name,
         AT  98(01) '|',
         AT  99(gs_width-xref3) '本頁合計：',
         AT    (gs_width-dbamt) pv_page_debit  CURRENCY gs_dochd-waers,
         AT    (gs_width-cdamt) pv_page_credit CURRENCY gs_dochd-waers.
  WRITE AT /98(01) '|'.
  WRITE: AT /98(01) '|',
         AT  99(gs_width-xref3) '累頁合計：',
         AT    (gs_width-dbamt) pv_doc_debit  CURRENCY gs_dochd-waers,
         AT    (gs_width-cdamt) pv_doc_credit CURRENCY gs_dochd-waers.
  IF lv_mgr_date IS NOT INITIAL.
    WRITE AT 11(10) lv_mgr_date.
  ENDIF.
  IF lv_rev_date IS NOT INITIAL.
    WRITE AT 41(10) lv_rev_date.
  ENDIF.
  IF lv_maker_date IS NOT INITIAL.
    WRITE AT 73(10) lv_maker_date.
  ENDIF.
  ULINE.

  PERFORM write_footer.
ENDFORM.

*&---------------------------------------------------------------------*
*& 頁尾：過帳日期、會計文件、頁碼（頁碼先印佔位符，最後回填）
*&---------------------------------------------------------------------*
FORM write_footer.
  WRITE: AT /153(01) '|',
         AT  154 '過帳日期：',
         AT  164 gs_dochd-budat.
  WRITE AT /153(01) '|'.
  WRITE: AT /153(01) '|',
         AT  154 '會計文件：',
         AT  164 gs_dochd-blart,
         AT  167 gs_dochd-belnr.
  WRITE AT /153(01) '|'.
  WRITE: AT /153(01) '|',
         AT  154 '頁    碼：',
         AT  164(20) gc_page_mark.
  gv_page_line = sy-linno.                     " 記下頁碼在第幾行，回填時用
  WRITE: AT /153(01) '|',
         AT  154 '--------------------------------------------------'.
ENDFORM.

*&---------------------------------------------------------------------*
*& 每頁頁首：公司名稱、年度＋報表標題（中文依實際寬度置中）
*&---------------------------------------------------------------------*
FORM write_header.
  DATA: lv_title TYPE sy-title,
        lv_width TYPE i,
        lv_pos   TYPE i.

  CONCATENATE gs_dochd-gjahr(4) '年' sy-title INTO lv_title.

  SKIP TO LINE 7.
  lv_width = cl_abap_list_utilities=>dynamic_output_length( gv_butxt ).
  lv_pos   = ( sy-linsz - lv_width ) / 2.
  WRITE AT /lv_pos gv_butxt.
  SKIP.
  lv_width = cl_abap_list_utilities=>dynamic_output_length( lv_title ).
  lv_pos   = ( sy-linsz - lv_width ) / 2.
  WRITE AT /lv_pos lv_title.
  ULINE.
ENDFORM.

*&---------------------------------------------------------------------*
*& 每頁頁首（續）：傳票資訊與欄位標題，只有印明細的頁才印
*&---------------------------------------------------------------------*
FORM write_column_title.
  CHECK gv_item_mode = 'X'.

  PERFORM write_doc_info.
  PERFORM write_double_line.
  WRITE: AT /01(gs_width-hkont) '會計科目'     CENTERED,
         AT    (gs_width-xref1) '對象代號名稱' CENTERED,
         AT    (gs_width-kostl) '成本中心'     CENTERED,
         AT    (gs_width-prctr) '利潤中心'     CENTERED,
         AT    (gs_width-aufnr) '內部訂單'     CENTERED,
         AT    (gs_width-zuonr) '指派'         CENTERED,
         AT    (gs_width-xref3) '參考碼三'     CENTERED,
         AT    (gs_width-dbamt) '原幣借方金額' CENTERED,
         AT    (gs_width-cdamt) '原幣貸方金額' CENTERED,
         AT    (gs_width-sgtxt) '內文摘要'     CENTERED.
  PERFORM write_double_line.
ENDFORM.

*&---------------------------------------------------------------------*
*& 傳票資訊一行：文件日期、參考、內文、幣別、匯率、狀態
*&---------------------------------------------------------------------*
FORM write_doc_info.
  WRITE: AT /001(010) '文件日期：',
             011(010) gs_dochd-bldat,
             022(003) ' / ',
             026(010) '表頭參考：',
             036(016) gs_dochd-xblnr,
             053(003) ' / ',
             057(010) '表頭內文：',
             067(025) gs_dochd-bktxt,
             093(003) ' / ',
             097(010) '文件幣別：',
             107(005) gs_dochd-waers,
             113(003) ' / ',
             117(010) '本國幣別：',
             128(005) gs_dochd-hwaer,
             134(003) ' / ',
             138(006) '匯率：',
             144(012) gs_dochd-kursf,
             157(003) ' / ',
             161(010) '文件狀態：',
             171(030) gv_status_text.
ENDFORM.

*&---------------------------------------------------------------------*
*& 欄位標題上下的雙線
*&---------------------------------------------------------------------*
FORM write_double_line.
  WRITE: AT /01(gs_width-hkont) '==============================',
         AT    (gs_width-xref1) '============',
         AT    (gs_width-kostl) '==========',
         AT    (gs_width-prctr) '==========',
         AT    (gs_width-aufnr) '============',
         AT    (gs_width-zuonr) '==================',
         AT    (gs_width-xref3) '====================',
         AT    (gs_width-dbamt) '================',
         AT    (gs_width-cdamt) '================',
         AT    (gs_width-sgtxt) '=================================================='.
ENDFORM.

*&---------------------------------------------------------------------*
*& 回填每張傳票的「頁碼 n/總頁數」（講義 13 §3.1）
*&---------------------------------------------------------------------*
FORM fill_page_numbers.
  DATA: ls_docpage TYPE ty_docpage,
        lv_page    TYPE i,
        lv_n       TYPE i,
        lv_total   TYPE i,
        lv_nc      TYPE c LENGTH 5,
        lv_tc      TYPE c LENGTH 5,
        lv_text    TYPE c LENGTH 20.

  LOOP AT gt_docpage INTO ls_docpage.
    lv_total = ls_docpage-last_page - ls_docpage-first_page + 1.
    lv_page  = ls_docpage-first_page.
    WHILE lv_page <= ls_docpage-last_page.
      lv_n = lv_page - ls_docpage-first_page + 1.
      WRITE lv_n     TO lv_nc LEFT-JUSTIFIED.
      WRITE lv_total TO lv_tc LEFT-JUSTIFIED.
      CONCATENATE lv_nc '/' lv_tc INTO lv_text.
      READ LINE gv_page_line OF PAGE lv_page.
      IF sy-subrc = 0.
        REPLACE gc_page_mark WITH lv_text INTO sy-lisel.
        MODIFY LINE gv_page_line OF PAGE lv_page.
      ENDIF.
      lv_page = lv_page + 1.
    ENDWHILE.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& 由 SAP 帳號取得姓名（查過的帳號記在 gt_username，不重複查資料庫）
*& 找不到帳號時，改查供應商主檔 A+帳號（離職員工）
*&---------------------------------------------------------------------*
FORM get_user_name USING    pv_bname TYPE usr21-bname
                   CHANGING pv_name  TYPE c.
  DATA: ls_user       TYPE ty_username,
        lv_persnumber TYPE usr21-persnumber,
        lv_last       TYPE adrp-name_last,
        lv_first      TYPE adrp-name_first,
        lv_lifnr      TYPE lfa1-lifnr.

  CLEAR pv_name.
  READ TABLE gt_username INTO ls_user WITH KEY bname = pv_bname.
  IF sy-subrc = 0.
    pv_name = ls_user-name.
  ELSE.
    SELECT SINGLE persnumber INTO lv_persnumber
      FROM usr21
      WHERE bname = pv_bname.
    IF sy-subrc = 0.
      SELECT SINGLE name_last name_first INTO (lv_last, lv_first)
        FROM adrp
        WHERE persnumber = lv_persnumber.
      IF sy-subrc = 0.
        CONCATENATE lv_last lv_first INTO pv_name SEPARATED BY ' '.
      ENDIF.
    ELSE.
      CONCATENATE 'A' pv_bname INTO lv_lifnr.
      SELECT SINGLE name1 INTO pv_name
        FROM lfa1
        WHERE lifnr = lv_lifnr.
    ENDIF.

    ls_user-bname = pv_bname.
    ls_user-name  = pv_name.
    APPEND ls_user TO gt_username.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& 依實際顯示寬度把文字切成兩行（中文字佔兩格，講義 12 §2.1）
*& 累計寬度不超過 pv_max1 放第一行，不超過 pv_max2 放第二行，其餘捨去
*&---------------------------------------------------------------------*
FORM split_by_width USING    pv_text  TYPE csequence
                             pv_max1  TYPE i
                             pv_max2  TYPE i
                    CHANGING pv_line1 TYPE c
                             pv_line2 TYPE c.
  DATA: lv_text TYPE c LENGTH 500,
        lv_len  TYPE i,
        lv_pos  TYPE i,
        lv_cols TYPE i,
        lv_w    TYPE i,
        lv_pos1 TYPE i,
        lv_pos2 TYPE i.

  CLEAR: pv_line1, pv_line2.
  lv_text = pv_text.
  lv_len  = strlen( lv_text ).

  DO lv_len TIMES.
    IF lv_text+lv_pos(1) = space.
      lv_w = 1.
    ELSE.
      lv_w = cl_abap_list_utilities=>dynamic_output_length( lv_text+lv_pos(1) ).
    ENDIF.
    lv_cols = lv_cols + lv_w.

    IF lv_cols <= pv_max1.
      pv_line1+lv_pos1(1) = lv_text+lv_pos(1).
      lv_pos1 = lv_pos1 + 1.
    ELSEIF lv_cols <= pv_max2.
      pv_line2+lv_pos2(1) = lv_text+lv_pos(1).
      lv_pos2 = lv_pos2 + 1.
    ELSE.
      EXIT.
    ENDIF.
    lv_pos = lv_pos + 1.
  ENDDO.
ENDFORM.
