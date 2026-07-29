REPORT zr_en04_order_number_demo.

FIELD-SYMBOLS: <fs_werks> TYPE any,
               <fs_auart> TYPE any,
               <fs_fevor> TYPE any,
               <fs_wempf> TYPE any.

DATA: ls_caufvd_imp TYPE caufvd,
      ls_caufvd_exp TYPE caufvd,
      lv_retcode    TYPE sy-subrc.

WRITE: / 'EN04 Implicit Enhancement Point 端對端驗證'.
WRITE: / '=========================================='.

* ---- 1. 清理並準備測試主檔（廠別 ZZ99／製令類型 ZE04，系統不存在的組合）----
DELETE FROM zen04_seq WHERE werks = 'ZZ99' AND auart = 'ZE04'.
DELETE FROM zen04_rule WHERE werks = 'ZZ99' AND auart = 'ZE04'.
DELETE FROM zen04_pltauart WHERE werks = 'ZZ99' AND auart = 'ZE04'.
COMMIT WORK.

INSERT zen04_pltauart FROM @( VALUE #(
  mandt = sy-mandt werks = 'ZZ99' auart = 'ZE04' ) ).

INSERT zen04_rule FROM @( VALUE #(
  mandt    = sy-mandt
  werks    = 'ZZ99'
  auart    = 'ZE04'
  fevor    = '001'
  zgrtype  = 'TESTRECIP01'
  leadcode = 'TR'
  stnum    = '0001' ) ).
COMMIT WORK.

* ---- 2. 暖身呼叫：讓 SAPLCOZF／SAPLCOKO1 載入記憶體，全域 CAUFVD／AFPOD 才存在可供 ASSIGN ----
*    CO_KO1_GET_HEADER 是唯讀 Getter，只有 EXPORTING 參數，呼叫端可以完全不接收，無任何副作用
CLEAR ls_caufvd_exp.
CALL FUNCTION 'CO_ZF_NUMBER_GET'
  EXPORTING
    caufvd_imp = ls_caufvd_imp
    nkrange    = '01'
    object     = 'AUFTRAG'
  IMPORTING
    caufvd_exp = ls_caufvd_exp
    retcode    = lv_retcode.

CALL FUNCTION 'CO_KO1_GET_HEADER'.

* ---- 3. 動態寫入 SAPLCOZF 的全域 CAUFVD、SAPLCOKO1 的全域 AFPOD-WEMPF ----
*    模擬真實 COR1/CO01 交易流程執行到這裡時，這些全域早已被填好的狀態
ASSIGN ('(SAPLCOZF)CAUFVD-WERKS') TO <fs_werks>.
ASSIGN ('(SAPLCOZF)CAUFVD-AUART') TO <fs_auart>.
ASSIGN ('(SAPLCOZF)CAUFVD-FEVOR') TO <fs_fevor>.
ASSIGN ('(SAPLCOKO1)AFPOD-WEMPF') TO <fs_wempf>.

IF <fs_werks> IS NOT ASSIGNED OR <fs_auart> IS NOT ASSIGNED
   OR <fs_fevor> IS NOT ASSIGNED OR <fs_wempf> IS NOT ASSIGNED.
  WRITE: / '無法動態存取全域資料，測試中止'.
  RETURN.
ENDIF.

<fs_werks> = 'ZZ99'.
<fs_auart> = 'ZE04'.
<fs_fevor> = '001'.
<fs_wempf> = 'TESTRECIP01'.

* ---- 4. 第一次呼叫：驗證新建流水號 ----
CLEAR ls_caufvd_exp.
CALL FUNCTION 'CO_ZF_NUMBER_GET'
  EXPORTING
    caufvd_imp = ls_caufvd_imp
    nkrange    = '01'
    object     = 'AUFTRAG'
  IMPORTING
    caufvd_exp = ls_caufvd_exp
    retcode    = lv_retcode.

WRITE: / '第 1 次呼叫（啟用組合 ZZ99/ZE04）CAUFVD_EXP-AUFNR =', ls_caufvd_exp-aufnr.

* ---- 5. 第二次呼叫：驗證流水號遞增 ----
CLEAR ls_caufvd_exp.
CALL FUNCTION 'CO_ZF_NUMBER_GET'
  EXPORTING
    caufvd_imp = ls_caufvd_imp
    nkrange    = '01'
    object     = 'AUFTRAG'
  IMPORTING
    caufvd_exp = ls_caufvd_exp
    retcode    = lv_retcode.

WRITE: / '第 2 次呼叫（啟用組合 ZZ99/ZE04）CAUFVD_EXP-AUFNR =', ls_caufvd_exp-aufnr.
WRITE: / '(預期格式：TR + 年2碼 + 月代碼1碼 + 流水號4碼，第2次流水號應比第1次多1)'.

* ---- 6. 驗證安全閘：未登記的廠別/製令類型組合，會 fall through 走標準取號 ----
<fs_werks> = '9999'.
<fs_auart> = '9999'.

CLEAR ls_caufvd_exp.
CALL FUNCTION 'CO_ZF_NUMBER_GET'
  EXPORTING
    caufvd_imp = ls_caufvd_imp
    nkrange    = '01'
    object     = 'AUFTRAG'
  IMPORTING
    caufvd_exp = ls_caufvd_exp
    retcode    = lv_retcode.

WRITE: / '第 3 次呼叫（未啟用組合 9999/9999）CAUFVD_EXP-AUFNR =', ls_caufvd_exp-aufnr.
WRITE: / '(預期為標準 Number Range 取號結果，12 碼數字，不是 TR 開頭)'.