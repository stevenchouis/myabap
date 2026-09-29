*&---------------------------------------------------------------------*
*&  Program     : ZRFI0004
*&  Description : 傳票清單
*&  Date        : 2006.11.27
*&---------------------------------------------------------------------*
*& 2008/08 - DEVK928193/DJ - "A" 類的資產科目, 將資產號碼
*&                           放置於對象代號名稱欄位
*&---------------------------------------------------------------------*
*& 2010/01 - SNBK900170/GAPE - 內文改為兩行顯示
*& 2023/08 - SAP-PIC-ADD-20230724 - PIC 要求增印會計主管、覆核的姓名及日期
*&---------------------------------------------------------------------*
*& 【教材說明】講義 13 第 6 節「實戰閱讀」的案例程式（真實客戶程式，
*&  依授課需要原樣保留，含歷次修改註記與被註解掉的舊程式碼）。
*&  依賴客戶自建表 ZFI0037、T-code ZFI0037/ZFI0037Q，課堂系統無法執行，只供閱讀。
*&---------------------------------------------------------------------*


REPORT zrfi0004 NO STANDARD PAGE HEADING
                LINE-SIZE 203
*Modified by JasonLian on 2023/10/19
*                LINE-COUNT 65(6).
                LINE-COUNT 65(0).
*End of JasonLian's modification on 2023/10/19

TABLES: bkpf, bseg, usr21, adrp, rbkp.
*Added by JasonLian on 2023/08/07 (SAP-PIC-ADD-20230724)
TABLES:
  zfi0037, sscrfields.
TYPE-POOLS: icon.
DATA:
  functxt TYPE smp_dyntxt.
*End of JasonLian's modification on 2023/08/07 (SAP-PIC-ADD-20230724)

DATA: t_header        LIKE textpool OCCURS 20 WITH HEADER LINE,
      l_bkpf          LIKE bkpf     OCCURS 0  WITH HEADER LINE.
*      l_zmm0027       LIKE zmm0027  OCCURS 0  WITH HEADER LINE.
*      l_zmmliv02      LIKE zmmliv02 OCCURS 0  WITH HEADER LINE.

DATA: BEGIN OF t_dochd OCCURS 0,
        bukrs         LIKE bkpf-bukrs,  " 公司代碼
        belnr         LIKE bkpf-belnr,  " 會計文件號碼
        gjahr         LIKE bkpf-gjahr,  " 會計年度
        blart         LIKE bkpf-blart,  " 文件類型
        bldat         LIKE bkpf-bldat,  " 文件中的文件日期
        budat         LIKE bkpf-budat,  " 文件中的過帳日期
        usnam         LIKE bkpf-usnam,  " 覆核者
        ppnam         LIKE bkpf-ppnam,  " 暫存者
        xblnr         LIKE bkpf-xblnr,  " 參考文件號碼
        bktxt         LIKE bkpf-bktxt,  " 文件表頭內文
        waers         LIKE bkpf-waers,  " 幣別碼
        kursf         LIKE bkpf-kursf,  " 匯率
        bstat         LIKE bkpf-bstat,  " 文件狀態
        hwaer         LIKE bkpf-hwaer,  " 本國貨幣
        ltext         LIKE t003t-ltext, " 文件類型說明

        awtyp         LIKE bkpf-awtyp,  " 參考程序
        awkey         LIKE bkpf-awkey,  " 物件碼

* Added by JasonLian on 2023/08/07 (SAP-PIC-ADD-20230724)
        tcode         LIKE bkpf-tcode,      "交易代碼
        cpudt         LIKE bkpf-cpudt,      "會計文件輸入的日期
        xref2_hd      LIKE bkpf-xref2_hd,   "文件表頭的參考碼 2 內部
        acctname      LIKE zfi0037-acctname, "會計主管姓名
* End of JasonLian's modification on 2023/08/07  (SAP-PIC-ADD-20230724)
      END   OF t_dochd.

DATA: BEGIN OF t_docit OCCURS 0,
        bukrs         LIKE bseg-bukrs,  " 公司代碼
        belnr         LIKE bseg-belnr,  " 會計文件號碼
        gjahr         LIKE bseg-gjahr,  " 會計年度
        buzei         LIKE bseg-buzei,  " 會計文件中的明細項目號碼
        bschl         LIKE bseg-bschl,  " 過帳碼
        koart         LIKE bseg-koart,  " 科目類型
        shkzg         LIKE bseg-shkzg,  " 借/貸方指示碼
        mwskz         LIKE bseg-mwskz,  " 營業稅代碼
        dmbtr         LIKE bseg-dmbtr,  " 本國貨幣金額
        wrbtr         LIKE bseg-wrbtr,  " 文件貨幣金額
        zuonr         LIKE bseg-zuonr,  " 指派號碼
        sgtxt         LIKE bseg-sgtxt,  " 項目內文
        xref1         LIKE bseg-xref1,  " 業務夥伴參考碼
        xref2         LIKE bseg-xref2,  " 業務夥伴參考碼
        xref3         LIKE bseg-xref3,  " 明細項目參考碼
        kokrs         LIKE bseg-kokrs,  " 成本控制範圍
        kostl         LIKE bseg-kostl,  " 成本中心
        prctr         LIKE bseg-prctr,  " 利潤中心
        hkont         LIKE bseg-hkont,  " 總帳科目
        kunnr         LIKE bseg-kunnr,                      " 客戶編號 1
        lifnr         LIKE bseg-lifnr,  " 供應商或貸方的帳號
        anln1         LIKE bseg-anln1,  " 主要資產號碼
        matnr         LIKE bseg-matnr,  " 物料號碼
        aufnr         LIKE bseg-aufnr,  " 訂單號碼
        txt50         LIKE skat-txt50,  " 總帳科目長文
        attxt         LIKE skat-txt50,  " 總帳科目長文
        ltext         LIKE cskt-ltext,  " 成本中心說明
        ptext         LIKE cepct-ltext, " 利潤中心長文
      END   OF t_docit.

DATA: t_docpa         LIKE t_docit OCCURS 0 WITH HEADER LINE,
      t_docps         LIKE t_docit OCCURS 0 WITH HEADER LINE,
      t_docpd         LIKE t_docit OCCURS 0 WITH HEADER LINE,
      t_docpk         LIKE t_docit OCCURS 0 WITH HEADER LINE.

DATA: values_tab      LIKE dd07v OCCURS 0 WITH HEADER LINE.

DATA: g_butxt       LIKE t001-butxt,  " Company Code Text
      g_title       LIKE sy-title,    " 畫面，標題內文
      g_ktopl       LIKE t001-ktopl,  " Chart of Accounts
      g_kokrs       LIKE tka01-kokrs. " Controlling Area

DATA: g_tabix       LIKE sy-tabix              .

DATA: l_ltext       LIKE t003t-ltext  VALUE space,
      l_bldat       TYPE char10       VALUE space,
      l_budat       TYPE char10       VALUE space.

DATA: w_adrnr       LIKE lfa1-adrnr,
      w_sort1       LIKE adrc-sort1.

DATA: BEGIN OF t_optfm,
        hkont         TYPE i VALUE 30          ,
        xref1         TYPE i VALUE 12          ,
        kostl         TYPE i VALUE 10          ,
        prctr         TYPE i VALUE 10          ,
        aufnr         TYPE i VALUE 12          ,
        zuonr         TYPE i VALUE 18          ,
        xref3         TYPE i VALUE 20          ,
        dbamt         TYPE i VALUE 16          ,
        cdamt         TYPE i VALUE 16          ,
        sgtxt         TYPE i VALUE 50          ,
      END   OF t_optfm.

DATA: w_subrc       LIKE sy-subrc.

DATA: w_endfg       TYPE char1.

DATA: w_pagno(20).
DATA: w_cpagno      LIKE sy-pagno.
DATA: w_tpagno(20).

DEFINE cls.
  clear   &1.
  refresh &1.
END-OF-DEFINITION.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
PARAMETERS:     p_bukrs   LIKE bkpf-bukrs OBLIGATORY DEFAULT '1000'.
*------------------------------T001 (Check Table)
*---------------公司代碼
SELECT-OPTIONS: s_belnr   FOR  bkpf-belnr                            ,
*---------------會計文件號碼
                s_gjahr   FOR  bkpf-gjahr         DEFAULT sy-datum  ,
*---------------會計年度
                s_blart   FOR  bkpf-blart                            ,
*---------------文件類型
                s_budat   FOR  bkpf-budat                            ,
*---------------過帳日期
                s_bldat   FOR  bkpf-bldat                            ,
*---------------文件日期
                s_cpudt   FOR  bkpf-cpudt                            ,
*---------------輸入日期
                s_usnam   FOR  bkpf-usnam          MATCHCODE OBJECT
                                                   user_addr         ,
*---------------過帳者
                s_ppnam   FOR  bkpf-ppnam          MATCHCODE OBJECT
                                                   user_addr         ,
*---------------暫存者
                s_bstat   FOR  bkpf-bstat          NO-DISPLAY        ,
*---------------文件狀態

* DEVK927878 - new liv selection >>>
*                s_belnr2  FOR  rbkp-belnr,
*                s_liv     FOR  rbkp-belnr         NO-DISPLAY         ,
*--------------- liv doc no.
                s_awtyp   FOR  bkpf-awtyp         DEFAULT 'RMRP'
                                                  NO-DISPLAY,
*--------------- 參考程序
                s_awkey   FOR  bkpf-awkey         NO-DISPLAY.
*--------------- 物件碼
* DEVK927878 <<<

SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE text-t02.
PARAMETERS:     c_rfb01   AS CHECKBOX   DEFAULT 'X'                  ,
*---------------過帳文件
                c_rfbv1   AS CHECKBOX                                ,
*---------------暫存文件
                c_rdfbv1  AS CHECKBOX                                .
*---------------被刪除的暫存文件

*               C_MM AS CHECKBOX                                     .
*---------------被刪除的暫存文件

SELECTION-SCREEN END   OF BLOCK blk2.
SELECTION-SCREEN END   OF BLOCK blk1.

*Added by JasonLian on 2023/08/25 (SAP-PIC-ADD-20230724)
**************************************************************************
INITIALIZATION.
**************************************************************************

*&**********************************************************************
*& SELECTION-SCREEN
*&**********************************************************************
  SELECTION-SCREEN: FUNCTION KEY 1,
                                           FUNCTION KEY 2.
  functxt-icon_id = icon_tools.
  functxt-icon_text = text-t03.
  sscrfields-functxt_01 = functxt.

  CLEAR functxt.
  functxt-icon_id = icon_tools.
  functxt-icon_text = text-t04.
  sscrfields-functxt_02 = functxt.
*End of JasonLian's modification on 2023/08/25 (SAP-PIC-ADD-20230724)

*&**********************************************************************
*& TOP-OF-PAGE
*&**********************************************************************
TOP-OF-PAGE.
  PERFORM write_header.
  PERFORM report_title.
*&**********************************************************************
*& END-OF-PAGE
*&**********************************************************************
END-OF-PAGE.
* Marked by JasonLian on 2023/10/19
* 把 footer 移到 FORM write_report 裡面印
*  PERFORM report_footer.
* End of JasonLian's modification on 2023/10/19
*

*&**********************************************************************
*&AT SELECTION SCREEN
*&**********************************************************************
AT SELECTION-SCREEN.
  PERFORM check_company_code.
  PERFORM check_auth_object.
*Added by JasonLian on 2023/08/25 (SAP-PIC-ADD-20230724)
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
*      PERFORM authority_check.
      CALL TRANSACTION 'ZFI0037'.
    WHEN 'FC02'.
*        PERFORM authority_check.
      CALL TRANSACTION 'ZFI0037Q'.

  ENDCASE.
*End of JasonLian's modification on 2023/08/25 (SAP-PIC-ADD-20230724)

*&**********************************************************************
*& START-OF-SELECTION
*&**********************************************************************
START-OF-SELECTION.
  PERFORM initial_document_status_range.
*  PERFORM set_liv_doc.                     " DEVK927878-LIV
  PERFORM extract_acct_doc_header_data.
  PERFORM extract_acct_doc_item_data.
*  PERFORM get_liv_simulate_data.           " DEVK927878-LIV
  PERFORM extract_acct_text_data.
*&**********************************************************************
*& END-OF-SELECTION
*&**********************************************************************
END-OF-SELECTION.
  PERFORM write_report.
*&---------------------------------------------------------------------*
*&      Form  write_header
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM write_header .
  DATA: l_composi   TYPE i                                     ,
        l_datposi   TYPE i                                     ,
        l_titposi   TYPE i                                     ,
        l_pagposi   TYPE i                                     ,
        l_linsz     LIKE sy-linsz                              .
*---start of modify  bill 20090907
  DATA:   l_len TYPE i,
          l_len1 TYPE i.
  PERFORM convert_string_to_xstring USING g_butxt l_len.
  CONCATENATE t_dochd-gjahr(4) '年' sy-title INTO g_title.
  PERFORM convert_string_to_xstring USING g_title l_len1.
*---end of modify bill 20090907

  SKIP TO LINE 7.
  l_linsz = sy-linsz.
*  l_composi = ( l_linsz - STRLEN( g_butxt ) ) / 2 .
  l_composi = ( l_linsz - l_len ) / 2.
*  CONCATENATE t_dochd-gjahr(4) '年' sy-title INTO g_title.
  l_datposi = l_linsz - 22.
  l_titposi = ( l_linsz - l_len1 ) / 2.
*  l_titposi = ( l_linsz - STRLEN( g_title ) ) / 2.

*  format color col_heading.
*  write:/ '程式名稱:'                  ,
*          SY-CPROG                     ,
*          at L_COMPOSI G_BUTXT         ,
*          at L_DATPOSI '頁碼    :'     ,
*          (13) SY-PAGNO right-justified.
*  write:/ '交易代碼:'                  ,
*          SY-TCODE                     ,
*          at L_TITPOSI SY-TITLE        ,
*          at L_DATPOSI '使用者  :'     ,
*          (13) SY-UNAME right-justified,
*        / '列印日期:'                  ,
*          SY-DATUM                     ,
*          at L_DATPOSI '列印時間:'     ,
*          (13) SY-UZEIT right-justified.
*  format color off.
*  read textpool SY-CPROG into T_HEADER language SY-LANGU.
*  format color col_heading intensified off.
*  loop at T_HEADER where ID eq 'H'.
*    write: T_HEADER-ENTRY.
*  endloop.
  WRITE AT /l_composi g_butxt         .
  SKIP.
  WRITE AT /l_titposi g_title         .
  ULINE.
ENDFORM.                    " write_header
*&---------------------------------------------------------------------*
*&      Form  report_title
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM report_title .
  CHECK w_subrc IS INITIAL.

  IF t_dochd-kursf IS INITIAL.
    t_dochd-kursf = 1.
  ENDIF.

  IF ( ( c_rfb01 = 'X' OR c_rfbv1 = 'X' ) AND t_dochd-bstat <> 'Z' ).
*    FORMAT COLOR OFF.
*    WRITE: AT /001(010) '公司代碼：'                                   ,
*               011(004) T_DOCHD-BUKRS                                  ,
*               016(003) ' / '                                          ,
*               020(010) '會計文件：'                                   ,
*               030(010) T_DOCHD-BELNR                                  ,
*               040(003) ' / '                                          ,
*               043(010) '會計年度：'                                   ,
*               053(004) T_DOCHD-GJAHR                                  ,
*               057(003) ' / '                                          ,
*               060(010) '文件類型：'                                   ,
*               070(004) T_DOCHD-BLART                                  ,
*               074(015) L_LTEXT                                        ,
*               089(003) ' / '                                          ,
*               092(010) '文件日期：'                                   ,
*               102(010) T_DOCHD-BLDAT                                  ,
*               112(003) ' / '                                          ,
*               115(010) '過帳日期：'                                   ,
*               125(010) T_DOCHD-BUDAT                                  ,
*               135(003) ' / '                                          ,
*               138(010) '文件幣別：'                                   ,
*               148(005) T_DOCHD-WAERS                                  ,
*               153(003) ' / '                                          ,
*               156(006) '匯率：'                                       ,
*               162(012) T_DOCHD-KURSF                                  ,
*               174(003) ' / '                                          ,
*               177(010) '本國幣別：'                                   ,
*               187(005) T_DOCHD-HWAER                                  .
*    WRITE: AT /001(010) '文件狀態：'                                   ,
*               011(060) VALUES_TAB-DDTEXT                              ,
*               071(003) ' / '                                          ,
*               074(010) '表頭參考：'                                   ,
*               084(016) T_DOCHD-XBLNR                                  ,
*               100(003) ' / '                                          ,
*               103(010) '表頭內文：'                                   ,
*               113(025) T_DOCHD-BKTXT                                  .
    WRITE: AT /001(010) '文件日期：'                                   ,
               011(010) t_dochd-bldat                                  ,
               022(003) ' / '                                          ,
               026(010) '表頭參考：'                                   ,
               036(016) t_dochd-xblnr                                  ,
               053(003) ' / '                                          ,
               057(010) '表頭內文：'                                   ,
               067(025) t_dochd-bktxt                                  ,
               093(003) ' / '                                          ,
               097(010) '文件幣別：'                                   ,
               107(005) t_dochd-waers                                  ,
               113(003) ' / '                                          ,
               117(010) '本國幣別：'                                   ,
               128(005) t_dochd-hwaer                                  ,
               134(003) ' / '                                          ,
               138(006) '匯率：'                                       ,
               144(012) t_dochd-kursf                                  ,
               157(003) ' / '                                          ,
               161(010) '文件狀態：'                                   ,
               171(030) values_tab-ddtext                              .
    WRITE: AT /01(t_optfm-hkont) '=============================='      ,
           AT    (t_optfm-xref1) '============'                        ,
           AT    (t_optfm-kostl) '=========='                          ,
           AT    (t_optfm-prctr) '=========='                          ,
           AT    (t_optfm-aufnr) '============'                        ,
           AT    (t_optfm-zuonr) '=================='                  ,
           AT    (t_optfm-xref3) '===================='                ,
           AT    (t_optfm-dbamt) '================'                    ,
           AT    (t_optfm-cdamt) '================'                    ,
           AT    (t_optfm-sgtxt)
                   '=================================================='.
    WRITE: AT /01(t_optfm-hkont) '會計科目'                    CENTERED,
           AT    (t_optfm-xref1) '對象代號名稱'                CENTERED,
           AT    (t_optfm-kostl) '成本中心'                    CENTERED,
           AT    (t_optfm-prctr) '利潤中心'                    CENTERED,
           AT    (t_optfm-aufnr) '內部訂單'                    CENTERED,
           AT    (t_optfm-zuonr) '指派'                        CENTERED,
           AT    (t_optfm-xref3) '參考碼三'                    CENTERED,
           AT    (t_optfm-dbamt) '原幣借方金額'                CENTERED,
           AT    (t_optfm-cdamt) '原幣貸方金額'                CENTERED,
           AT    (t_optfm-sgtxt) '內文摘要'                    CENTERED.
    WRITE: AT /01(t_optfm-hkont) '=============================='      ,
           AT    (t_optfm-xref1) '============'                        ,
           AT    (t_optfm-kostl) '=========='                          ,
           AT    (t_optfm-prctr) '=========='                          ,
           AT    (t_optfm-aufnr) '============'                        ,
           AT    (t_optfm-zuonr) '=================='                  ,
           AT    (t_optfm-xref3) '===================='                ,
           AT    (t_optfm-dbamt) '================'                    ,
           AT    (t_optfm-cdamt) '================'                    ,
           AT    (t_optfm-sgtxt)
                   '=================================================='.
  ENDIF.
ENDFORM.                    " report_title
*&---------------------------------------------------------------------*
*&      Form  check_company_code
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_company_code .
  CLEAR: g_butxt, g_ktopl, g_kokrs.
  SELECT SINGLE butxt ktopl
          INTO (g_butxt, g_ktopl)
          FROM t001 WHERE bukrs EQ p_bukrs.
  IF sy-subrc NE 0.
    MESSAGE e014(fipos) WITH p_bukrs.
  ELSE.
    SELECT SINGLE kokrs INTO g_kokrs FROM tka01
                                    WHERE ktopl EQ g_ktopl.
  ENDIF.
ENDFORM.                    " check_company_code
*&---------------------------------------------------------------------*
*&      Form  initial_document_status_range
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initial_document_status_range .
  cls: values_tab.

  CALL FUNCTION 'GET_DOMAIN_VALUES'
    EXPORTING
      domname         = 'BSTAT'
      text            = 'X'
    TABLES
      values_tab      = values_tab
    EXCEPTIONS
      no_values_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  cls: s_bstat.

  IF c_rfb01 = 'X'.
    LOOP AT values_tab
      WHERE domvalue_l <> 'V'   " 暫存文件
        AND domvalue_l <> 'W'   " 具有文件識別更改的暫存文件
        AND domvalue_l <> 'Z'.  " 被刪除的暫存文件
      s_bstat-sign   = 'I' .
      s_bstat-option = 'EQ'.
      s_bstat-low    = values_tab-domvalue_l.
      APPEND s_bstat.
    ENDLOOP.
  ENDIF.

  IF c_rfbv1 = 'X'.
    LOOP AT values_tab
      WHERE domvalue_l = 'V'   " 暫存文件
         OR domvalue_l = 'W'.  " 具有文件識別更改的暫存文件
      s_bstat-sign   = 'I'.
      s_bstat-option = 'EQ'.
      s_bstat-low    = values_tab-domvalue_l.
      APPEND s_bstat.
    ENDLOOP.
  ENDIF.

  IF c_rdfbv1 = 'X'.
    LOOP AT values_tab
      WHERE domvalue_l = 'Z'.  " 被刪除的暫存文件
      s_bstat-sign   = 'I' .
      s_bstat-option = 'EQ'.
      s_bstat-low    = values_tab-domvalue_l.
      APPEND s_bstat.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " initial_document_status_range
*&---------------------------------------------------------------------*
*&      Form  extract_acct_doc_header_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM extract_acct_doc_header_data .
  cls: t_dochd.
  SELECT bukrs belnr gjahr blart bldat budat
         usnam ppnam xblnr bktxt waers kursf bstat hwaer

         awtyp awkey                                 " DEVK927878-LIV
*        Added by JasonLian on 2023/08/07 (SAP-PIC-ADD-20230724)
         cpudt xref2_hd
*        End of JasonLian's modification on 2023/08/07 (SAP-PIC-ADD-20230724)
*        Added by JasonLian on 2023/08/07 (SAP-PIC-ADD-20230724)
         tcode
*        End of JasonLian's modification on 2023/08/07 (SAP-PIC-ADD-20230724)
         INTO CORRESPONDING FIELDS OF TABLE t_dochd
         FROM bkpf
         WHERE bukrs EQ p_bukrs
          AND  belnr IN s_belnr
          AND  gjahr IN s_gjahr
          AND  blart IN s_blart
          AND  budat IN s_budat
          AND  cpudt IN s_cpudt
          AND  usnam IN s_usnam
          AND  bstat IN s_bstat
          AND  ppnam IN s_ppnam.
  IF t_dochd[] IS INITIAL.
    MESSAGE i001(fot_b2a).
    STOP.
  ENDIF.
  SORT t_dochd BY bukrs belnr gjahr.

* Added by JasonLian on 2023/08/07 (SAP-PIC-ADD-20230724)
* 用會計傳票暫存日期抓會計主管姓名
  DATA:
    lv_cpudt        LIKE bkpf-cpudt,
    lv_inauguration LIKE zfi0037-inauguration,
    lv_acctname     LIKE zfi0037-acctname.

  LOOP AT t_dochd.
    CLEAR: lv_cpudt, lv_inauguration, lv_acctname.

*    Modified by JasonLian on 2023/12/15
**   決定會計傳票暫存日期
*    IF t_dochd-xref2_hd IS INITIAL.
*      lv_cpudt = t_dochd-cpudt.
*    ELSE.
*      lv_cpudt = t_dochd-xref2_hd.
*    ENDIF.
*   決定會計傳票暫存日期
    IF t_dochd-tcode = 'FB08' OR
       t_dochd-tcode = 'F.80' OR
       t_dochd-tcode = 'MR8M'.
      lv_cpudt = t_dochd-cpudt.
    ELSE.
      IF t_dochd-xref2_hd IS INITIAL.
        lv_cpudt = t_dochd-cpudt.
      ELSE.
        lv_cpudt = t_dochd-xref2_hd.
      ENDIF.
    ENDIF.
*   End of JasonLian's modification on 2023/12/15

*   用會計傳票暫存日期決定其會計主管
    SELECT inauguration acctname
      INTO (lv_inauguration, lv_acctname)
      FROM zfi0037
      WHERE bukrs = t_dochd-bukrs
        AND inauguration <= lv_cpudt
      ORDER BY inauguration DESCENDING.

*     只抓最近的那個會計主管
      IF sy-subrc = 0.
        t_dochd-acctname = lv_acctname.
        MODIFY t_dochd.
        EXIT.
      ENDIF.
    ENDSELECT.
  ENDLOOP.
* End of JasonLian's modification on 2023/08/07 (SAP-PIC-ADD-20230724)

ENDFORM.                    " extract_acct_doc_header_data
*&---------------------------------------------------------------------*
*&      Form  extract_acct_doc_item_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM extract_acct_doc_item_data .
  DEFINE append_liv.
    s_liv-sign = 'I'.
    s_liv-option = 'EQ'.
    s_liv-low = 'EQ'.
    s_liv-low = &1.
    collect s_liv.
  END-OF-DEFINITION.


  cls: t_docit.
  IF c_rfb01 = 'X'.      " Posting Document
    SELECT * INTO CORRESPONDING FIELDS OF TABLE t_docit FROM bseg
             FOR ALL ENTRIES IN t_dochd
             WHERE bukrs EQ t_dochd-bukrs
               AND  belnr EQ t_dochd-belnr
               AND  gjahr EQ t_dochd-gjahr.
  ENDIF.

  IF c_rfbv1 = 'X' OR c_rdfbv1 = 'X'.  " Parking Document
    SELECT bukrs belnr gjahr buzei bschl
           shkzg mwskz dmbtr wrbtr zuonr sgtxt
           kostl hkont anln1 matnr aufnr
           APPENDING CORRESPONDING FIELDS OF TABLE t_docpa
                     FROM vbsega
                     FOR ALL ENTRIES IN t_dochd
                     WHERE ausbk EQ t_dochd-bukrs
                      AND  belnr EQ t_dochd-belnr
                      AND  gjahr EQ t_dochd-gjahr.
    SELECT bukrs belnr gjahr buzei bschl
           koart shkzg mwskz dmbtr wrbtr zuonr sgtxt xref1 xref2 xref3
           kokrs kostl prctr saknr AS hkont anln1 matnr aufnr
           APPENDING CORRESPONDING FIELDS OF TABLE t_docps
                     FROM vbsegs
                     FOR ALL ENTRIES IN t_dochd
                     WHERE ausbk EQ t_dochd-bukrs
                      AND  belnr EQ t_dochd-belnr
                      AND  gjahr EQ t_dochd-gjahr.
    SELECT bukrs belnr gjahr buzei bschl
           shkzg mwskz dmbtr wrbtr zuonr sgtxt xref1 xref2 xref3
           hkont kunnr
           APPENDING CORRESPONDING FIELDS OF TABLE t_docpd
                     FROM vbsegd
                     FOR ALL ENTRIES IN t_dochd
                     WHERE ausbk EQ t_dochd-bukrs
                      AND  belnr EQ t_dochd-belnr
                      AND  gjahr EQ t_dochd-gjahr.
    SELECT bukrs belnr gjahr buzei bschl
           shkzg mwskz dmbtr wrbtr zuonr sgtxt xref1 xref2 xref3
           hkont lifnr
           APPENDING CORRESPONDING FIELDS OF TABLE t_docpk
                     FROM vbsegk
                     FOR ALL ENTRIES IN t_dochd
                     WHERE ausbk EQ t_dochd-bukrs
                      AND  belnr EQ t_dochd-belnr
                      AND  gjahr EQ t_dochd-gjahr.


    LOOP AT t_docpa.
      MOVE-CORRESPONDING t_docpa TO t_docit.
      t_docit-koart = 'A'.
*      append_liv t_docit-belnr.
      APPEND t_docit. CLEAR t_docit.
    ENDLOOP.
    cls: t_docpa.

    LOOP AT t_docps.
      MOVE-CORRESPONDING t_docps TO t_docit.
*      append_liv t_docit-belnr.
      APPEND t_docit. CLEAR t_docit.
    ENDLOOP.
    cls: t_docps.

    LOOP AT t_docpd.
      MOVE-CORRESPONDING t_docpd TO t_docit.
      t_docit-koart = 'D'.
*      append_liv t_docit-belnr.
      APPEND t_docit. CLEAR t_docit.
    ENDLOOP.
    cls: t_docpd.

    LOOP AT t_docpk.
      MOVE-CORRESPONDING t_docpk TO t_docit.
      t_docit-koart = 'K'.
*      append_liv t_docit-belnr.
      APPEND t_docit. CLEAR t_docit.
    ENDLOOP.
    cls: t_docpk.

  ENDIF.
*--> Remark >>>>
*  DELETE T_DOCIT WHERE DMBTR EQ 0.
*--> End of line <<<<
  SORT t_docit BY bukrs belnr gjahr buzei.
ENDFORM.                    " extract_acct_doc_item_data
*&---------------------------------------------------------------------*
*&      Form  extract_acct_text_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM extract_acct_text_data .
  LOOP AT t_docit.
    g_tabix = sy-tabix.
    SELECT SINGLE txt50 INTO t_docit-txt50 FROM skat
                       WHERE spras EQ sy-langu
                        AND  ktopl EQ g_ktopl
                        AND  saknr EQ t_docit-hkont.
    CASE t_docit-koart.
      WHEN 'A'.    " Asset
*        IF NOT T_DOCIT-ANLN1 IS INITIAL.
*          SELECT SINGLE ANLHTXT INTO T_DOCIT-ATTXT FROM ANLH
*                               WHERE BUKRS EQ T_DOCIT-BUKRS
*                                AND  ANLN1 EQ T_DOCIT-ANLN1.
*          SELECT SINGLE KOSTL INTO T_DOCIT-KOSTL FROM ANLZ
*                             WHERE BUKRS EQ T_DOCIT-BUKRS
*                              AND  ANLN1 EQ T_DOCIT-ANLN1
*                              AND  ANLN2 EQ '0000'
*                              AND  BDATU GT SY-DATUM
*                              AND  ADATU LT SY-DATUM     .
*        ENDIF.

* DEVK928193 >>> "A" 類的資產科目 將資產號碼 放置於對象代號名稱欄位
        t_docit-xref2 = t_docit-anln1.
* DEVK928193 <<<

      WHEN 'D'.    " Customer
        IF NOT t_docit-kunnr IS INITIAL.
          SELECT SINGLE adrnr INTO w_adrnr
                              FROM kna1
                              WHERE kunnr EQ t_docit-kunnr.
          SELECT SINGLE sort1 INTO w_sort1
                        FROM adrc WHERE addrnumber = w_adrnr
                                     AND date_from <= sy-datum
                                     AND nation = space
                                     AND date_to => sy-datum.

          t_docit-xref1 = w_sort1.
          t_docit-xref2 = t_docit-kunnr.
        ENDIF.
      WHEN 'K'.    " Vendor
        IF NOT t_docit-lifnr IS INITIAL.
          SELECT SINGLE adrnr INTO w_adrnr
                              FROM lfa1
                              WHERE lifnr EQ t_docit-lifnr.
          SELECT SINGLE sort1 INTO w_sort1
                        FROM adrc WHERE addrnumber = w_adrnr
                                     AND date_from <= sy-datum
                                     AND nation = space
                                     AND date_to => sy-datum.

          t_docit-xref1 = w_sort1.
          t_docit-xref2 = t_docit-lifnr.
        ENDIF.
      WHEN 'M'.    " Material
*        IF NOT T_DOCIT-MATNR IS INITIAL.
*          SELECT SINGLE MAKTX INTO T_DOCIT-ATTXT FROM MAKT
*                             WHERE MATNR EQ T_DOCIT-MATNR
*                              AND  SPRAS EQ SY-LANGU     .
*        ENDIF.
      WHEN 'S'.    " G/L Account
      WHEN OTHERS.
    ENDCASE.
    IF NOT t_docit-kostl IS INITIAL.
      SELECT SINGLE ktext INTO t_docit-ltext FROM cskt
                         WHERE spras EQ sy-langu
                          AND  kokrs EQ g_kokrs
                          AND  kostl EQ t_docit-kostl
                          AND  datbi GE sy-datum     .
    ENDIF.
    IF NOT t_docit-prctr IS INITIAL.
      SELECT SINGLE ktext INTO t_docit-ptext FROM cepct
                         WHERE spras EQ sy-langu
                          AND  prctr EQ t_docit-prctr
                          AND  datbi GE sy-datum
                          AND  kokrs EQ g_kokrs      .
    ENDIF.

    IF t_docit-hkont = '0000128200' OR t_docit-hkont = '0000229200'.
      t_docit-sgtxt = t_docit-mwskz.
    ENDIF.

    MODIFY t_docit INDEX g_tabix.
  ENDLOOP.
ENDFORM.                    " extract_acct_text_data
*&---------------------------------------------------------------------*
*&      Form  write_report
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM write_report .
  DATA: l_pgcnt  TYPE i         ,
        l_modno  TYPE i         ,
        l_pgdat  LIKE bseg-wrbtr,
        l_pgcat  LIKE bseg-wrbtr,
        l_dodat  LIKE bseg-wrbtr,
        l_docat  LIKE bseg-wrbtr,
        l_tabix  LIKE sy-tabix.
*-- MODIFY: ADD 2 VARIABLE L_SGTXT2 L_SGTXT2 - SNBK900170
  DATA: l_sgtxt1(50) TYPE c,
        l_sgtxt2(50) TYPE c,
        l_sgtxt3(50) TYPE c.
*-- END OF MODIFY
*added by Betty SAP_PIC-FI_20250224-傳票清單離職員工簽核欄位調整 20250905 >>>
  DATA: l_lifnr TYPE lifnr.
*added by Betty SAP_PIC-FI_20250224-傳票清單離職員工簽核欄位調整 20250905 <<<  end
  w_cpagno = 1.

* Added by JasonLian on 2023/08/01 (SAP-PIC-ADD-20230724)
  DATA: ws-usnam(10) TYPE c.   "覆核者姓名
  DATA: lv_xref2_hd  TYPE dats.
  DATA: l_doc_page   TYPE i,        "計算每張傳票之頁數
        l_total_page TYPE i,        "用來計算總頁數
        l_sy_pagno   TYPE i.        "用來標示要更新傳票總頁數的哪一頁
* End of JasonLian's modification on 2023/08/01 (SAP-PIC-ADD-20230724)

  l_total_page = 0.   "JasonLian added on 2023/10/20
  LOOP AT t_dochd.
    l_tabix = sy-tabix.
    AT NEW gjahr.
      NEW-PAGE.
      l_total_page = l_total_page + 1.  "Jason Added on 2023/10/20 : 累積計算總頁數
      sy-pagno = 1.
      l_doc_page = 1.   "JasonLian added on 2023/10/20
      DATA: ws-ppnam(10) TYPE c.   "製票員姓名


      CLEAR: l_dodat, l_docat.

      READ TABLE t_dochd INDEX l_tabix.

      IF t_dochd-ppnam IS INITIAL.
        t_dochd-ppnam = t_dochd-usnam.
      ENDIF.
      SELECT SINGLE * FROM usr21 WHERE bname = t_dochd-ppnam.
      IF sy-subrc = 0.
        SELECT SINGLE * FROM adrp WHERE persnumber = usr21-persnumber.
        IF sy-subrc = 0.
          CONCATENATE adrp-name_last adrp-name_first INTO ws-ppnam
                                                     SEPARATED BY ' '.
        ENDIF.
*added by Betty SAP_PIC-FI_20250224-傳票清單離職員工簽核欄位調整 20250905 >>>
      ELSE.
        CLEAR l_lifnr.
        CONCATENATE 'A' t_dochd-ppnam INTO l_lifnr.
        SELECT SINGLE name1 FROM lfa1
          INTO ws-ppnam
          WHERE lifnr = l_lifnr .
*added by Betty SAP_PIC-FI_20250224-傳票清單離職員工簽核欄位調整 20250905 <<<  end
      ENDIF.

*     Added by JasonLian on 2023/08/01 (SAP-PIC-ADD-20230724)
*     抓覆核者姓名
      CLEAR: ws-usnam, usr21, adrp.
      SELECT SINGLE * FROM usr21 WHERE bname = t_dochd-usnam.
      IF sy-subrc = 0.
        SELECT SINGLE * FROM adrp WHERE persnumber = usr21-persnumber.
        IF sy-subrc = 0.
          CONCATENATE adrp-name_last adrp-name_first INTO ws-usnam
                                                     SEPARATED BY ' '.
        ENDIF.
*added by Betty SAP_PIC-FI_20250224-傳票清單離職員工簽核欄位調整 20250905 >>>
      ELSE.
        CLEAR l_lifnr.
        CONCATENATE 'A' t_dochd-usnam INTO l_lifnr.
        SELECT SINGLE name1 FROM lfa1
          INTO ws-usnam
          WHERE lifnr = l_lifnr .
*added by Betty SAP_PIC-FI_20250224-傳票清單離職員工簽核欄位調整 20250905 <<<  end
      ENDIF.
*     End of JasonLian's modification on 2023/08/01 (SAP-PIC-ADD-20230724)
    ENDAT.

    READ TABLE values_tab WITH KEY domvalue_l = t_dochd-bstat.
    SELECT SINGLE ltext INTO l_ltext FROM t003t
                       WHERE spras EQ sy-langu
                        AND  blart EQ t_dochd-blart.
    WRITE: t_dochd-bldat TO l_bldat,
           t_dochd-budat TO l_budat.

    CLEAR w_subrc.

*  Jason Note: 印過帳文件或暫存文件
    IF ( c_rfb01 = 'X' OR c_rfbv1 = 'X' ) AND t_dochd-bstat <> 'Z'.
      l_pgcnt = 1.
      LOOP AT t_docit WHERE bukrs EQ t_dochd-bukrs
                       AND  belnr EQ t_dochd-belnr
                       AND  gjahr EQ t_dochd-gjahr.
        CLEAR: w_endfg.
        IF l_pgcnt EQ 1.
          CLEAR: l_pgdat, l_pgcat, l_dodat, l_docat.
        ENDIF.
        WRITE: AT /01(t_optfm-hkont) t_docit-hkont.
*--> Remark >>>>
*      CASE T_DOCIT-KOART.
*        WHEN 'A'.    " Asset
*          WRITE: AT (T_OPTFM-XREF1) T_DOCIT-ANLN1.
*        WHEN 'D'.    " Customer
*          WRITE: AT (T_OPTFM-XREF1) T_DOCIT-KUNNR.
*        WHEN 'K'.    " Vendor
*          WRITE: AT (T_OPTFM-XREF1) T_DOCIT-LIFNR.
*        WHEN 'M'.    " Material
*          WRITE: AT (T_OPTFM-XREF1) T_DOCIT-MATNR.
*        WHEN 'S'.    " G/L Account
*          WRITE: AT (T_OPTFM-XREF1) ''.
*        WHEN OTHERS.
*      ENDCASE.
*--> End of line <<<<
        WRITE: AT    (t_optfm-xref1) t_docit-xref2.
        WRITE: AT    (t_optfm-kostl) t_docit-kostl,
               AT    (t_optfm-prctr) t_docit-prctr,
               AT    (t_optfm-aufnr) t_docit-aufnr,
               AT    (t_optfm-zuonr) t_docit-zuonr,
               AT    (t_optfm-xref3) t_docit-xref3.
        CASE t_docit-shkzg.
          WHEN 'S'.    " Debit
            WRITE: AT (t_optfm-dbamt) t_docit-wrbtr
                             CURRENCY t_dochd-waers.
            WRITE: AT (t_optfm-cdamt) ''           .
            l_pgdat = l_pgdat + t_docit-wrbtr.
            l_dodat = l_dodat + t_docit-wrbtr.
          WHEN 'H'.    " Credit
            WRITE: AT (t_optfm-dbamt) ''           .
            WRITE: AT (t_optfm-cdamt) t_docit-wrbtr
                             CURRENCY t_dochd-waers.
            l_pgcat = l_pgcat + t_docit-wrbtr.
            l_docat = l_docat + t_docit-wrbtr.
          WHEN OTHERS.
        ENDCASE.
*--  MODIFY: SPLIT SGTXT TO L_SGTXT1 AND L_SGTXT2 -- SNBK900170
*        WRITE: AT    (t_optfm-sgtxt) t_docit-sgtxt.
        CLEAR: l_sgtxt1, l_sgtxt2.
        PERFORM split_sgtxt USING t_docit-sgtxt
                                  l_sgtxt1 '50'
                                  l_sgtxt2 '100'.
        WRITE: AT    (t_optfm-sgtxt) l_sgtxt1.
        SKIP.
        CLEAR: l_sgtxt1.
        PERFORM split_sgtxt USING t_docit-xref1
                                  l_sgtxt1 '12'
                                  l_sgtxt3 '0'.
        t_docit-xref1 = l_sgtxt1.
        CLEAR: l_sgtxt1.
        PERFORM split_sgtxt USING t_docit-ltext
                                  l_sgtxt1 '10'
                                  l_sgtxt3 '0'.
        t_docit-ltext = l_sgtxt1.
        CLEAR: l_sgtxt1.
        PERFORM split_sgtxt USING t_docit-ptext
                                  l_sgtxt1 '10'
                                  l_sgtxt3 '0'.
        t_docit-ptext = l_sgtxt1.

        WRITE: AT /01(t_optfm-hkont) t_docit-txt50.
        WRITE: AT    (t_optfm-xref1) t_docit-xref1,
               AT    (t_optfm-kostl) t_docit-ltext,
               AT    (t_optfm-prctr) t_docit-ptext,
               AT    (t_optfm-aufnr) space,
               AT    (t_optfm-zuonr) space,
               AT    (t_optfm-xref3) space,
               AT    (t_optfm-dbamt) space,
               AT    (t_optfm-cdamt) space,
               AT    (t_optfm-sgtxt) l_sgtxt2.
*-- END OF MODIFY

*      ULINE.
        WRITE: AT /01(t_optfm-hkont) '------------------------------',
               AT    (t_optfm-xref1) '------------'                  ,
               AT    (t_optfm-kostl) '----------'                    ,
               AT    (t_optfm-prctr) '----------'                    ,
               AT    (t_optfm-aufnr) '-------------'                  ,
               AT    (t_optfm-zuonr) '------------------'            ,
               AT    (t_optfm-xref3) '-------------------'          ,
               AT    (t_optfm-dbamt) '----------------'              ,
               AT    (t_optfm-cdamt) '----------------'              ,
               AT    (t_optfm-sgtxt)
                 '--------------------------------------------------'.
        l_modno = l_pgcnt MOD 10.
        IF l_modno EQ 0.                    "Jason Note: 每張傳票筆每累積10筆就要換頁
          w_endfg = 'P'.                    "Jason Note: 同一張傳票內之換頁註記
          l_doc_page = l_doc_page + 1.      "Jason Added on 2023/10/20 : 累積計算同一張傳票的頁數
          l_total_page = l_total_page + 1.  "Jason Added on 2023/10/20 : 累積計算總頁數
        ENDIF.
        AT END OF gjahr.
          w_cpagno = w_cpagno + sy-pagno.
          READ TABLE t_dochd INDEX l_tabix.
          w_endfg = 'L'.                    "Jason Note: 一張傳票之結束註記
*         Added by JasonLian on 2023/11/02
*        如果該傳票剛好是10、20、30 、....項，則音為前面被多加1頁，所以應該要扣掉
          IF l_modno = 0.
            l_doc_page = l_doc_page - 1.
            l_total_page = l_total_page - 1.
          ENDIF.
*         End of JasonLian's modification on 2023/11/02
        ENDAT.

        IF w_endfg NE space.                "Jason Note: 遇到換頁或結束註記，就跑到第55行，以便印會計主管簽核區域
          SKIP TO LINE 55.
          ULINE.

*Modifed by JasonLian on 2023/08/07 (SAP-PIC-ADD-20230724)
*如果是PIC, 則要加印會計主管、覆核 的名字並印相關日期

*          WRITE: AT /01(10) '會計主管：',
*                 AT  35(06) '覆核：',
*                 AT  65(08) '製票員：',
*                 AT  73(10) ws-ppnam,
*                 AT  98(01) '|',
*                 AT  99(t_optfm-xref3) '本頁合計：',
*                 AT    (t_optfm-dbamt) l_pgdat CURRENCY t_dochd-waers,
*                 AT    (t_optfm-cdamt) l_pgcat CURRENCY t_dochd-waers,
**                 AT 153(01) '|',
*                 AT 154(t_optfm-sgtxt) ''.
*
*          CLEAR: l_pgdat, l_pgcat.
*          WRITE: AT /98(01) '|'.
**          WRITE: AT /98(01) '|',
**                 AT 153(01) '|'.
*          WRITE: AT /01(t_optfm-hkont) '',
*                 AT    (t_optfm-xref1) '',
*                 AT    (t_optfm-kostl) '',
*                 AT    (t_optfm-prctr) '',
*                 AT    (t_optfm-aufnr) '',
*                 AT    (t_optfm-zuonr) '',
*                 AT  98(01) '|',
*                 AT  99(t_optfm-xref3) '累頁合計：',
*                 AT    (t_optfm-dbamt) l_dodat CURRENCY t_dochd-waers,
*                 AT    (t_optfm-cdamt) l_docat CURRENCY t_dochd-waers,
**                 AT 153(01) '|',
*                 AT 154(t_optfm-sgtxt) ''.
*          ULINE.
          IF t_dochd-acctname IS INITIAL. "如果沒有會計主管, 則與原先相同不變
            WRITE: AT /01(10) '會計主管：',
                   AT  35(06) '覆核：',
                   AT  65(08) '製票員：',
                   AT  73(10) ws-ppnam,
                   AT  98(01) '|',
                   AT  99(t_optfm-xref3) '本頁合計：',
                   AT    (t_optfm-dbamt) l_pgdat CURRENCY t_dochd-waers,
                   AT    (t_optfm-cdamt) l_pgcat CURRENCY t_dochd-waers,
*                   AT 153(01) '|',
                   AT 154(t_optfm-sgtxt) ''.

            CLEAR: l_pgdat, l_pgcat.
            WRITE: AT /98(01) '|'.
*            WRITE: AT /98(01) '|',
*                   AT 153(01) '|'.
            WRITE: AT /01(t_optfm-hkont) '',
                   AT    (t_optfm-xref1) '',
                   AT    (t_optfm-kostl) '',
                   AT    (t_optfm-prctr) '',
                   AT    (t_optfm-aufnr) '',
                   AT    (t_optfm-zuonr) '',
                   AT  98(01) '|',
                   AT  99(t_optfm-xref3) '累頁合計：',
                   AT    (t_optfm-dbamt) l_dodat CURRENCY t_dochd-waers,
                   AT    (t_optfm-cdamt) l_docat CURRENCY t_dochd-waers,
*                   AT 153(01) '|',
                   AT 154(t_optfm-sgtxt) ''.
            ULINE.
            PERFORM report_footer.
          ELSE.  "如果有會計主管, 則加印會計主管、製票人姓名、日期
*           暫存文件(只顯示會計主管、製票員姓名)
            IF t_dochd-bstat = 'V'.  "暫存文件
              WRITE: AT /01(10) '會計主管：',
                     AT  11(10) t_dochd-acctname,          "會計主管姓名
                     AT  35(06) '覆核：',
                     AT  65(08) '製票員：',
                     AT  73(10) ws-usnam,                  "製票員姓名(BKPF-USNAM)
                     AT  98(01) '|',
                     AT  99(t_optfm-xref3) '本頁合計：',
                     AT    (t_optfm-dbamt) l_pgdat CURRENCY t_dochd-waers,
                     AT    (t_optfm-cdamt) l_pgcat CURRENCY t_dochd-waers,
                     AT 154(t_optfm-sgtxt) ''.

              CLEAR: l_pgdat, l_pgcat.
              WRITE: AT /98(01) '|'.
              WRITE: AT /01(t_optfm-hkont) '',
                     AT    (t_optfm-xref1) '',
                     AT    (t_optfm-kostl) '',
                     AT    (t_optfm-prctr) '',
                     AT    (t_optfm-aufnr) '',
                     AT    (t_optfm-zuonr) '',
                     AT  73(10) t_dochd-cpudt,             "製票員日期(暫存文件建立日)
                     AT  98(01) '|',
                     AT  99(t_optfm-xref3) '累頁合計：',
                     AT    (t_optfm-dbamt) l_dodat CURRENCY t_dochd-waers,
                     AT    (t_optfm-cdamt) l_docat CURRENCY t_dochd-waers,
                     AT 154(t_optfm-sgtxt) ''.
              ULINE.
              PERFORM report_footer.
*           已過帳文件(顯示會計主管、覆核、製票員姓名)
            ELSE.                    "已過帳文件
              WRITE: AT /01(10) '會計主管：',
                     AT  11(10) t_dochd-acctname,          "會計主管姓名
                     AT  35(06) '覆核：',
                     AT  41(10) ws-usnam,                  "覆核姓名
                     AT  65(08) '製票員：',
                     AT  73(10) ws-ppnam,                  "製票員姓名
                     AT  98(01) '|',
                     AT  99(t_optfm-xref3) '本頁合計：',
                     AT    (t_optfm-dbamt) l_pgdat CURRENCY t_dochd-waers,
                     AT    (t_optfm-cdamt) l_pgcat CURRENCY t_dochd-waers,
                     AT 154(t_optfm-sgtxt) ''.

              CLEAR: l_pgdat, l_pgcat.
              WRITE: AT /98(01) '|'.
              WRITE: AT /01(t_optfm-hkont) '',
                     AT    (t_optfm-xref1) '',
                     AT    (t_optfm-kostl) '',
                     AT    (t_optfm-prctr) '',
                     AT    (t_optfm-aufnr) '',
                     AT    (t_optfm-zuonr) ''.
              WRITE: AT  11(10) t_dochd-cpudt,             "會計主管日期(過帳執行日)
                     AT  41(10) t_dochd-cpudt.             "覆核日期(過帳執行日)
*             Modified by JasonLian on 2023/12/15
*              IF t_dochd-xref2_hd IS NOT INITIAL.
              IF t_dochd-xref2_hd IS NOT INITIAL AND
                 t_dochd-tcode <> 'FB08' AND
                 t_dochd-tcode <> 'F.80' AND
                 t_dochd-tcode <> 'MR8M'.
*             End of JasonLian on 2023/12/15
                MOVE t_dochd-xref2_hd TO lv_xref2_hd.      "原t_dochd-xref2_hd 非日期格式, 需先做轉換
                WRITE  AT  73(10) lv_xref2_hd.             "製票員日期(暫存文件建立日)
              ELSE.
                WRITE  AT  73(10) t_dochd-cpudt.           "製票員日期(過帳執行日)
              ENDIF.
              WRITE: AT  98(01) '|',
                     AT  99(t_optfm-xref3) '累頁合計：',
                     AT    (t_optfm-dbamt) l_dodat CURRENCY t_dochd-waers,
                     AT    (t_optfm-cdamt) l_docat CURRENCY t_dochd-waers,
                     AT 154(t_optfm-sgtxt) ''.
              ULINE.
              PERFORM report_footer.
            ENDIF.
          ENDIF.
* End of JasonLian's modification on 2023/08/07 (SAP-PIC-ADD-20230724)

*         if W_ENDFG eq 'L'.
*           skip to line 59.
*         endif.
*         new-page.
        ENDIF.
        l_pgcnt = l_pgcnt + 1.    "Jason Note: 每張傳票之item 數目
      ENDLOOP.
*    Added by JasonLian on 2023/10/20
*    更新每張傳票的總頁碼
      WRITE l_doc_page TO w_tpagno LEFT-JUSTIFIED.
      l_sy_pagno = l_total_page - l_doc_page + 1.    "由總頁數往前推，以更新本張傳票的頁碼
      DO l_doc_page TIMES.
        READ LINE 64 OF PAGE l_sy_pagno.
        REPLACE '&' WITH w_tpagno INTO sy-lisel.
        IF sy-subrc IS INITIAL.
          MODIFY CURRENT LINE.
        ENDIF.
        l_sy_pagno = l_sy_pagno + 1.
      ENDDO.
*    End of JasonLian's modification on 2023/10/20
      w_subrc = sy-subrc.
    ENDIF.
*  Jason Note: 印被刪除的暫存文件或沒有item項的文件
    IF ( c_rdfbv1 EQ 'X' AND t_dochd-bstat = 'Z' ) OR NOT w_subrc IS INITIAL.
*      WRITE: AT /001(010) '公司代碼：'                                   ,
*                 011(004) T_DOCHD-BUKRS                                  ,
*                 016(003) ' / '                                          ,
*                 020(010) '會計文件：'                                   ,
*                 030(010) T_DOCHD-BELNR                                  ,
*                 040(003) ' / '                                          ,
*                 043(010) '會計年度：'                                   ,
*                 053(004) T_DOCHD-GJAHR                                  ,
*                 057(003) ' / '                                          ,
*                 060(010) '文件類型：'                                   ,
*                 070(004) T_DOCHD-BLART                                  ,
*                 074(015) L_LTEXT                                        ,
*                 089(003) ' / '                                          ,
*                 092(010) '文件日期：'                                   ,
*                 102(010) T_DOCHD-BLDAT                                  ,
*                 112(003) ' / '                                          ,
*                 115(010) '過帳日期：'                                   ,
*                 125(010) T_DOCHD-BUDAT                                  .
*      WRITE: AT /001(010) '文件狀態：'                                   ,
*                 011(060) VALUES_TAB-DDTEXT                              ,
*                 071(003) ' / '                                          ,
*                 074(010) '文件幣別：'                                   ,
*                 084(005) T_DOCHD-WAERS                                  ,
*                 089(003) ' / '                                          ,
*                 092(006) '匯率：'                                       ,
*                 098(012) T_DOCHD-KURSF                                  ,
*                 110(003) ' / '                                          ,
*                 113(010) '本國幣別：'                                   ,
*                 123(005) T_DOCHD-HWAER                                  .
      WRITE: AT /001(010) '文件日期：'                                   ,
                 011(010) t_dochd-bldat                                  ,
                 022(003) ' / '                                          ,
                 026(010) '表頭參考：'                                   ,
                 036(016) t_dochd-xblnr                                  ,
                 053(003) ' / '                                          ,
                 057(010) '表頭內文：'                                   ,
                 067(025) t_dochd-bktxt                                  ,
                 093(003) ' / '                                          ,
                 097(010) '文件幣別：'                                   ,
                 107(005) t_dochd-waers                                  ,
                 113(003) ' / '                                          ,
                 117(010) '本國幣別：'                                   ,
                 128(005) t_dochd-hwaer                                  ,
                 134(003) ' / '                                          ,
                 138(006) '匯率：'                                       ,
                 144(012) t_dochd-kursf                                  ,
                 157(003) ' / '                                          ,
                 161(010) '文件狀態：'                                   ,
                 171(030) values_tab-ddtext                              .
      ULINE.
      SKIP TO LINE 55.
      ULINE.

*Modifed by JasonLian on 2023/08/07 (SAP-PIC-ADD-20230724)
*如果是PIC, 則要加印會計主管、覆核 的名字並印相關日期
*      WRITE: AT /01(10) '會計主管：',
*             AT  35(06) '覆核：',
*             AT  65(08) '製票員：',
*             AT  73(10) ws-ppnam,
*             AT  98(01) '|',
*             AT  99(t_optfm-xref3) '本頁合計：',
*             AT    (t_optfm-dbamt) l_pgdat CURRENCY t_dochd-waers,
*             AT    (t_optfm-cdamt) l_pgcat CURRENCY t_dochd-waers,
**             AT 153(01) '|',
*             AT 154(t_optfm-sgtxt) ''.
*      CLEAR: l_pgdat, l_pgcat.
*      WRITE: AT /98(01) '|'.
**      WRITE: AT /98(01) '|',
**             AT 153(01) '|'.
*      WRITE: AT /01(t_optfm-hkont) '',
*             AT    (t_optfm-xref1) '',
*             AT    (t_optfm-kostl) '',
*             AT    (t_optfm-prctr) '',
*             AT    (t_optfm-aufnr) '',
*             AT    (t_optfm-zuonr) '',
*             AT  98(01) '|',
*             AT  99(t_optfm-xref3) '累頁合計：',
*             AT    (t_optfm-dbamt) l_dodat CURRENCY t_dochd-waers,
*             AT    (t_optfm-cdamt) l_docat CURRENCY t_dochd-waers,
**             AT 153(01) '|',
*             AT 154(t_optfm-sgtxt) ''.
      IF t_dochd-acctname IS INITIAL. "如果沒有會計主管, 則與原先相同不變
        WRITE: AT /01(10) '會計主管：',
               AT  35(06) '覆核：',
               AT  65(08) '製票員：',
               AT  73(10) ws-ppnam,
               AT  98(01) '|',
               AT  99(t_optfm-xref3) '本頁合計：',
               AT    (t_optfm-dbamt) l_pgdat CURRENCY t_dochd-waers,
               AT    (t_optfm-cdamt) l_pgcat CURRENCY t_dochd-waers,
               AT 154(t_optfm-sgtxt) ''.
        CLEAR: l_pgdat, l_pgcat.

        WRITE: AT /98(01) '|'.
        WRITE: AT /01(t_optfm-hkont) '',
               AT    (t_optfm-xref1) '',
               AT    (t_optfm-kostl) '',
               AT    (t_optfm-prctr) '',
               AT    (t_optfm-aufnr) '',
               AT    (t_optfm-zuonr) '',
               AT  98(01) '|',
               AT  99(t_optfm-xref3) '累頁合計：',
               AT    (t_optfm-dbamt) l_dodat CURRENCY t_dochd-waers,
               AT    (t_optfm-cdamt) l_docat CURRENCY t_dochd-waers,
               AT 154(t_optfm-sgtxt) ''.
        ULINE. "Jason Added
        PERFORM report_footer.
      ELSE.  "如果有會計主管, 則加印會計主管、製票人姓名、日期
*     暫存文件(只顯示會計主管、製票員姓名)
        IF t_dochd-bstat = 'V'.  "暫存文件
          WRITE: AT /01(10) '會計主管：',
                 AT  11(10) t_dochd-acctname,          "會計主管姓名
                 AT  35(06) '覆核：',
                 AT  65(08) '製票員：',
                 AT  73(10) ws-usnam,                  "製票員姓名(BKPF-USNAM)
                 AT  98(01) '|',
                 AT  99(t_optfm-xref3) '本頁合計：',
                 AT    (t_optfm-dbamt) l_pgdat CURRENCY t_dochd-waers,
                 AT    (t_optfm-cdamt) l_pgcat CURRENCY t_dochd-waers,
                 AT 154(t_optfm-sgtxt) ''.

          CLEAR: l_pgdat, l_pgcat.
          WRITE: AT /98(01) '|'.
          WRITE: AT /01(t_optfm-hkont) '',
                 AT    (t_optfm-xref1) '',
                 AT    (t_optfm-kostl) '',
                 AT    (t_optfm-prctr) '',
                 AT    (t_optfm-aufnr) '',
                 AT    (t_optfm-zuonr) '',
                 AT  73(10) t_dochd-cpudt,             "製票員日期(暫存文件建立日)
                 AT  98(01) '|',
                 AT  99(t_optfm-xref3) '累頁合計：',
                 AT    (t_optfm-dbamt) l_dodat CURRENCY t_dochd-waers,
                 AT    (t_optfm-cdamt) l_docat CURRENCY t_dochd-waers,
                 AT 154(t_optfm-sgtxt) ''.
          ULINE.
          PERFORM report_footer.
*       已過帳文件(顯示會計主管、覆核、製票員姓名)
        ELSE.                    "已過帳文件
          WRITE: AT /01(10) '會計主管：',
                 AT  11(10) t_dochd-acctname,          "會計主管姓名
                 AT  35(06) '覆核：',
                 AT  41(10) ws-usnam,                  "覆核姓名
                 AT  65(08) '製票員：',
                 AT  73(10) ws-ppnam,                  "製票員姓名
                 AT  98(01) '|',
                 AT  99(t_optfm-xref3) '本頁合計：',
                 AT    (t_optfm-dbamt) l_pgdat CURRENCY t_dochd-waers,
                 AT    (t_optfm-cdamt) l_pgcat CURRENCY t_dochd-waers,
                 AT 154(t_optfm-sgtxt) ''.

          CLEAR: l_pgdat, l_pgcat.
          WRITE: AT /98(01) '|'.
          WRITE: AT /01(t_optfm-hkont) '',
                 AT    (t_optfm-xref1) '',
                 AT    (t_optfm-kostl) '',
                 AT    (t_optfm-prctr) '',
                 AT    (t_optfm-aufnr) '',
                 AT    (t_optfm-zuonr) ''.
          WRITE: AT  11(10) t_dochd-cpudt,             "會計主管日期(過帳執行日)
                 AT  41(10) t_dochd-cpudt.             "覆核日期(過帳執行日)

*             Modified by JasonLian on 2023/12/15
*          IF t_dochd-xref2_hd IS NOT INITIAL.
          IF t_dochd-xref2_hd IS NOT INITIAL AND
             t_dochd-tcode <> 'FB08' AND
             t_dochd-tcode <> 'F.80' AND
             t_dochd-tcode <> 'MR8M'.
*             End of JasonLian on 2023/12/15
            MOVE t_dochd-xref2_hd TO lv_xref2_hd.      "原t_dochd-xref2_hd 非日期格式, 需先做轉換
            WRITE  AT  73(10) lv_xref2_hd.             "製票員日期(暫存文件建立日)
          ELSE.
            WRITE  AT  73(10) t_dochd-cpudt.           "製票員日期(過帳執行日)
          ENDIF.
          WRITE: AT  98(01) '|',
                 AT  99(t_optfm-xref3) '累頁合計：',
                 AT    (t_optfm-dbamt) l_dodat CURRENCY t_dochd-waers,
                 AT    (t_optfm-cdamt) l_docat CURRENCY t_dochd-waers,
                 AT 154(t_optfm-sgtxt) ''.
          ULINE.
          PERFORM report_footer.
        ENDIF.
      ENDIF.
*     Added by JasonLian on 2023/10/20
*     更新每張傳票的總頁碼
      l_doc_page = 1.
      WRITE l_doc_page TO w_tpagno LEFT-JUSTIFIED.
      l_sy_pagno = l_total_page - l_doc_page + 1.
      DO l_doc_page TIMES.
        READ LINE 64 OF PAGE l_sy_pagno.
        REPLACE '&' WITH w_tpagno INTO sy-lisel.
        IF sy-subrc IS INITIAL.
          MODIFY CURRENT LINE.
        ENDIF.
        l_sy_pagno = l_sy_pagno + 1.
      ENDDO.
*    End of JasonLian's modification on 2023/10/20
* End of JasonLian's modification on 2023/08/07 (SAP-PIC-ADD-20230724)

*    AT END OF gjahr.
*        w_cpagno = w_c pagno + sy-pagno.
*        READ TABLE t_dochd INDEX l_tabix.
*        w_endfg = 'L'.
*
**        SKIP TO LINE 59.
** 2023/10/13 >>> 報表 Uline 移除
**        ULINE.
**        PERFORM reserve_line.
** 2023/10/13 <<<
*
*    ENDAT.
*      ULINE.   "
    ENDIF.
  ENDLOOP.
ENDFORM.                    " write_report
*&---------------------------------------------------------------------*
*&      Form  report_footer
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM report_footer .
*  sy-linno = 59. " 2023/11/13 Reserve line start
  WRITE sy-pagno TO w_pagno LEFT-JUSTIFIED.
  CONCATENATE w_pagno '/&' INTO w_pagno.
  WRITE: AT /01(t_optfm-hkont) '',
         AT    (t_optfm-xref1) '',
         AT    (t_optfm-kostl) '',
         AT    (t_optfm-prctr) '',
         AT    (t_optfm-aufnr) '',
         AT    (t_optfm-zuonr) '',
         AT    (t_optfm-xref3) '',
         AT    (t_optfm-dbamt) '',
         AT    (t_optfm-cdamt) '',
         AT    153(01) '|',
         AT    154 '過帳日期：',
         AT    164 t_dochd-budat.
  WRITE: AT /153(01) '|'.
  WRITE: AT /01(t_optfm-hkont) '',
         AT    (t_optfm-xref1) '',
         AT    (t_optfm-kostl) '',
         AT    (t_optfm-prctr) '',
         AT    (t_optfm-aufnr) '',
         AT    (t_optfm-zuonr) '',
         AT    (t_optfm-xref3) '',
         AT    (t_optfm-dbamt) '',
         AT    (t_optfm-cdamt) '',
         AT    153(01) '|',
         AT    154 '會計文件：',
         AT    164 t_dochd-blart,
         AT    167 t_dochd-belnr.
  WRITE: AT /153(01) '|'.
  WRITE: AT /01(t_optfm-hkont) '',
         AT    (t_optfm-xref1) '',
         AT    (t_optfm-kostl) '',
         AT    (t_optfm-prctr) '',
         AT    (t_optfm-aufnr) '',
         AT    (t_optfm-zuonr) '',
         AT    (t_optfm-xref3) '',
         AT    (t_optfm-dbamt) '',
         AT    (t_optfm-cdamt) '',
         AT    153(01) '|',
         AT    154 '頁    碼：',
         AT    164 w_pagno.
  WRITE: AT /153(01) '|',
             154 '--------------------------------------------------'.
*  Marked by JasonLian on 2023/10/19
*  更新每張傳票的總頁碼 => 移至外面做
*  IF w_endfg = 'L'.
*    WRITE sy-pagno TO w_tpagno LEFT-JUSTIFIED.
*
*    DO w_cpagno TIMES.
*      READ LINE 64 OF PAGE sy-index.
*      REPLACE '&' WITH w_tpagno INTO sy-lisel.
*      IF sy-subrc IS INITIAL.
*        MODIFY CURRENT LINE.
*      ENDIF.
*    ENDDO.
*  ENDIF.
*  End of JasonLian on 2023/10/19
ENDFORM.                    " report_footer
*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTH_OBJECT
*&---------------------------------------------------------------------*
FORM check_auth_object .
  DATA: w_subrc LIKE sy-subrc.

  AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
           ID 'BUKRS' FIELD p_bukrs
           ID 'ACTVT' FIELD '01'.
  w_subrc = sy-subrc.
  IF NOT w_subrc IS INITIAL.
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
             ID 'BUKRS' FIELD p_bukrs
             ID 'ACTVT' FIELD '02'.
    w_subrc = sy-subrc.
    IF NOT w_subrc IS INITIAL.
      AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
               ID 'BUKRS' FIELD p_bukrs
               ID 'ACTVT' FIELD '03'.
      w_subrc = sy-subrc.
    ENDIF.
  ENDIF.
*
  IF NOT w_subrc IS INITIAL.
    MESSAGE e460(f5) WITH p_bukrs.
  ENDIF.
ENDFORM.                    " check_auth_object
*&---------------------------------------------------------------------*
*&      Form  set_liv_doc
*&---------------------------------------------------------------------*
*FORM set_liv_doc .
*  CHECK NOT s_belnr2[] IS INITIAL.
*
*  CLEAR: s_liv, s_liv[].
**  LOOP AT s_belnr2.
**    s_awkey-sign = s_belnr2-sign.
**    s_awkey-low = s_belnr2-low.
**    s_awkey-low+10(1) = '*'.
**    s_awkey-option = 'CP'.
**
**    IF s_belnr2-high = s_belnr2-low.
**      CLEAR s_belnr2-high.
**    ENDIF.
**
**    IF s_belnr2-high <> space.
**      s_awkey-high = s_belnr2-high.
**      s_awkey-high+10(1) = '*'.
**      s_awkey-option = 'BT'.
**    ENDIF.
**
**    COLLECT s_awkey.
**  ENDLOOP.
*
*  SELECT belnr awkey FROM bkpf
*    INTO CORRESPONDING FIELDS OF TABLE l_bkpf
*   WHERE bukrs  = p_bukrs AND gjahr IN s_gjahr
*     AND awtyp IN s_awtyp.
*
*  LOOP AT l_bkpf.
*    CHECK l_bkpf-awkey(10) IN s_belnr2.
*
*    s_belnr-low    = l_bkpf-belnr.
*    s_belnr-sign   = 'I'.
*    s_belnr-option = 'EQ'.
*    COLLECT: s_belnr.
*  ENDLOOP.
*
*  IF s_belnr[] IS INITIAL AND NOT s_belnr2[] IS INITIAL.
*    MESSAGE i001(fot_b2a).
*    STOP.
*  ENDIF.
*
*  CLEAR: l_bkpf, l_bkpf[].
*ENDFORM.                    " set_liv_doc
*&---------------------------------------------------------------------*
*&      Form  GET_LIV_simulate_data
*&---------------------------------------------------------------------*
*FORM get_liv_simulate_data .
*  DATA l_index TYPE i.
*  DATA l_buzei LIKE t_docit-buzei.
**  DATA l_z027  LIKE zmm0027 OCCURS 0 WITH HEADER LINE.
*
**  CHECK c_rfbv1 <> space AND NOT s_liv[] IS INITIAL.
*
**  CLEAR: s_belnr2, s_belnr2[], l_zmm0027, l_zmm0027[],
**         l_z027, l_z027.
*
*  LOOP AT t_dochd WHERE awtyp IN s_awtyp
*                    AND awkey <> space.
*    s_belnr2-low    = t_dochd-awkey.
*    s_belnr2-sign   = 'I'.
*    s_belnr2-option = 'EQ'.
*    COLLECT s_belnr2.
*  ENDLOOP.
*
*  CHECK NOT s_belnr2[] IS INITIAL.
*  SELECT * FROM zmmliv02
*    INTO CORRESPONDING FIELDS OF TABLE l_zmmliv02
*   WHERE bukrs  = p_bukrs AND gjahr IN s_gjahr
*     AND awtyp IN s_awtyp AND awref IN s_belnr2.
*  CHECK sy-subrc = 0.
*
*  SELECT * FROM zmm0027
*    INTO CORRESPONDING FIELDS OF TABLE l_zmm0027
*   WHERE gjahr IN s_gjahr
*     AND belnr IN s_belnr2.
*  l_z027[] = l_zmm0027[].
*  CLEAR: l_zmm0027, l_zmm0027[].
*
*  LOOP AT t_dochd WHERE awtyp IN s_awtyp
*                    AND awkey <> space.
*
*    CHECK t_dochd-belnr IN s_liv.
*
*    CLEAR l_buzei.
*    LOOP AT t_docit WHERE belnr = t_dochd-belnr
*                      AND gjahr = t_dochd-gjahr.
*      l_buzei = t_docit-buzei.
*    ENDLOOP.
*
*    CLEAR: l_index, l_zmm0027, l_zmm0027[].
*    LOOP AT l_z027 WHERE belnr = t_dochd-awkey(10)
*                     AND gjahr = t_dochd-gjahr.
*      MOVE-CORRESPONDING l_z027 TO l_zmm0027.
*      APPEND l_zmm0027.
*    ENDLOOP.
*
*    LOOP AT l_zmmliv02 WHERE awtyp = t_dochd-awtyp
*                         AND awref = t_dochd-awkey(10)
*                         AND aworg = t_dochd-gjahr
*                         AND bukrs = t_dochd-bukrs.
*      l_index = l_index + 1.
*      CHECK l_index > 1.
*      MOVE-CORRESPONDING l_zmmliv02 TO t_docit.
*      t_docit-belnr = t_dochd-belnr.
*      t_docit-dmbtr = t_docit-wrbtr = l_zmmliv02-rmwwr.
*
*      t_docit-buzei = l_buzei = l_buzei + 1.
*
*      l_index = l_index - 1.
*      CLEAR l_zmm0027.
*      READ TABLE l_zmm0027 INDEX l_index.
*
*      IF t_docit-hkont = l_zmm0027-saknr AND sy-subrc = 0.
*        t_docit-xref1 = l_zmm0027-xref1.
*        t_docit-xref2 = l_zmm0027-xref2.
*      ENDIF.
*      l_index = l_index + 1.
*
*      IF t_docit-koart = 'S' AND
*         t_docit-hkont <> '0000128200'.
*        SELECT SINGLE ctrnotmp INTO t_docit-zuonr
*          FROM zmm0024
*         WHERE ebeln = t_docit-belnr.
*      ENDIF.
*
*      APPEND t_docit.
*    ENDLOOP.
*  ENDLOOP.
*
*  SORT t_docit BY bukrs belnr gjahr buzei.
*  CLEAR: l_zmm0027, l_zmm0027[], l_zmmliv02, l_zmmliv02[].
*ENDFORM.                    " GET_LIV_simulate_data
*&---------------------------------------------------------------------*
*&      Form  CONVERT_STRING_TO_XSTRING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM convert_string_to_xstring USING l_butxt l_length.
  DATA: lv_unicode_string TYPE string,
        lv_xstring_stream TYPE xstring,
        l_xstring TYPE xstring.
  CLEAR:lv_unicode_string,lv_xstring_stream,l_xstring.
  lv_unicode_string = l_butxt.

  CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
    EXPORTING
      codepage_to      = '8300'
      unicode_string   = lv_unicode_string
    IMPORTING
      xstring_stream   = lv_xstring_stream
    EXCEPTIONS
      invalid_codepage = 1
      invalid_string   = 2
      OTHERS           = 3.

  IF sy-subrc = 0.
    l_xstring = lv_xstring_stream.
  ENDIF.
  l_length = XSTRLEN( l_xstring ).
ENDFORM.                    " CONVERT_STRING_TO_XSTRING
*&---------------------------------------------------------------------*
*&      Form  SPLIT_SGTXT
*&---------------------------------------------------------------------*
* SNBK900170:  SPLIT SGTXT TO L_SGTXT1 L_SGTXT2 (UNICODE)
*----------------------------------------------------------------------*
FORM split_sgtxt  USING    p_sgtxt
                           p_sgtxt1 p_len1
                           p_sgtxt2 p_len2.
  DATA: l_str(500) TYPE c.
  DATA: l_len TYPE i,
        l_lenc TYPE i,
        l_pos TYPE i,
        l_cnt TYPE i,
        l_pos1 TYPE i,
        l_pos2 TYPE i.
  DATA: address1(64) TYPE c,
        address2(64) TYPE c.

  l_str = p_sgtxt.
  l_lenc = NUMOFCHAR( l_str ).

  l_pos = 0. l_cnt = 0. l_pos1 = 0. l_pos2 = 0.

  DO l_lenc TIMES.
    l_len = cl_abap_list_utilities=>dynamic_output_length( l_str+l_pos(1) ).
    IF l_str+l_pos(1) EQ space.
      l_len = 1.
    ENDIF.

    ADD l_len TO l_cnt.

    IF l_cnt > p_len1.
      IF l_cnt > p_len2.
        EXIT.
      ENDIF.
      p_sgtxt2+l_pos2(1) = l_str+l_pos(1).
      ADD 1 TO l_pos2.
    ELSE.
      p_sgtxt1+l_pos1(1) = l_str+l_pos(1).
      ADD 1 TO l_pos1.
    ENDIF.
    ADD 1 TO l_pos.
  ENDDO.

ENDFORM.                    " SPLIT_SGTXT

*&---------------------------------------------------------------------*
*& Form AUTHORITY_CHECK
*&---------------------------------------------------------------------*
*& 權限物件尚待 user 決定
*&---------------------------------------------------------------------*
FORM authority_check.
  DATA: lv_text TYPE string.
  lv_text = '無維護會計主管權限!'.
*     AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
*                          ID 'DICBERCLS' FIELD 'ZCUS'
*                          ID 'ACTVT' FIELD '02'.

  AUTHORITY-CHECK OBJECT 'ZFI0037'
                    ID 'BUKRS'  FIELD 'PIC'.

  IF sy-subrc <> 0.
    MESSAGE e899(v1) WITH lv_text.                    "無維護會計主管權限
  ENDIF.
ENDFORM.                    "authority_check
*&---------------------------------------------------------------------*
*&      Form  RESERVE_LINE
*&---------------------------------------------------------------------*
FORM reserve_line .
  SKIP TO LINE 59.
  WRITE: AT 153(01) '|'.
ENDFORM.                    " RESERVE_LINE
