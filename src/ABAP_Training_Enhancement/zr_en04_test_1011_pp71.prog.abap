REPORT zr_en04_test_1011_pp71.

FIELD-SYMBOLS: <fs_werks> TYPE any,
               <fs_auart> TYPE any,
               <fs_fevor> TYPE any,
               <fs_wempf> TYPE any.

DATA: ls_caufvd_imp TYPE caufvd,
      ls_caufvd_exp TYPE caufvd,
      lv_retcode    TYPE sy-subrc.

WRITE: / 'EN04 Plant 1011 / Order Type PP71 萬用字元規則測試'.
WRITE: / '=========================================='.

* ---- 先清掉本次測試會用到的流水號，讓每次重跑結果可預期 ----
DELETE FROM zen04_seq WHERE werks = '1011' AND auart = 'PP71'.
COMMIT WORK.

* ---- 暖身呼叫：讓 SAPLCOZF／SAPLCOKO1 載入記憶體 ----
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

ASSIGN ('(SAPLCOZF)CAUFVD-WERKS') TO <fs_werks>.
ASSIGN ('(SAPLCOZF)CAUFVD-AUART') TO <fs_auart>.
ASSIGN ('(SAPLCOZF)CAUFVD-FEVOR') TO <fs_fevor>.
ASSIGN ('(SAPLCOKO1)AFPOD-WEMPF') TO <fs_wempf>.

IF <fs_werks> IS NOT ASSIGNED OR <fs_auart> IS NOT ASSIGNED
   OR <fs_fevor> IS NOT ASSIGNED OR <fs_wempf> IS NOT ASSIGNED.
  WRITE: / '無法動態存取全域資料，測試中止'.
  RETURN.
ENDIF.

* ---- 用任意的 FEVOR/WEMPF，驗證萬用字元 '*' 規則不限值都會比對成功 ----
<fs_werks> = '1011'.
<fs_auart> = 'PP71'.
<fs_fevor> = 'XYZ'.
<fs_wempf> = 'ANYONE0001'.

CLEAR ls_caufvd_exp.
CALL FUNCTION 'CO_ZF_NUMBER_GET'
  EXPORTING
    caufvd_imp = ls_caufvd_imp
    nkrange    = '01'
    object     = 'AUFTRAG'
  IMPORTING
    caufvd_exp = ls_caufvd_exp
    retcode    = lv_retcode.

WRITE: / '第 1 次呼叫（FEVOR=XYZ／WEMPF=ANYONE0001）CAUFVD_EXP-AUFNR =', ls_caufvd_exp-aufnr.

* ---- 換一組完全不同的 FEVOR/WEMPF，驗證萬用字元規則一樣命中、且共用同一組流水號 ----
<fs_fevor> = '999'.
<fs_wempf> = 'DIFFERENT9'.

CLEAR ls_caufvd_exp.
CALL FUNCTION 'CO_ZF_NUMBER_GET'
  EXPORTING
    caufvd_imp = ls_caufvd_imp
    nkrange    = '01'
    object     = 'AUFTRAG'
  IMPORTING
    caufvd_exp = ls_caufvd_exp
    retcode    = lv_retcode.

WRITE: / '第 2 次呼叫（FEVOR=999／WEMPF=DIFFERENT9）CAUFVD_EXP-AUFNR =', ls_caufvd_exp-aufnr.
WRITE: / '(預期格式：PP + 年2碼 + 月代碼1碼 + 流水號4碼；兩次 FEVOR/WEMPF 不同但都應命中同一組流水號，第2次應比第1次多1)'.