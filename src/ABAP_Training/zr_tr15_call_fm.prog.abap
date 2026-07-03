*&---------------------------------------------------------------------*
*& Report  ZR_TR15_CALL_FM
*& 練習 15：呼叫 Function Module（答案程式——呼叫端）
*&---------------------------------------------------------------------*
* FM 是「跨程式共用」的邏輯單位：
*   SE37 可單獨測試、任何程式都能 CALL FUNCTION 呼叫
* 方向容易搞混：
*   FM 定義的 IMPORTING（它要「收」的）→ 呼叫端寫在 EXPORTING（我「送」的）
*   FM 定義的 EXPORTING（它要「給」的）→ 呼叫端寫在 IMPORTING（我「收」的）
*&---------------------------------------------------------------------*
REPORT zr_tr15_call_fm.

DATA gv_revenue TYPE s_price.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 正常呼叫
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_CALC_REVENUE'
    EXPORTING
      iv_price      = '1500.00'
      iv_seatsocc   = 200
    IMPORTING
      ev_revenue    = gv_revenue
    EXCEPTIONS
      invalid_input = 1
      OTHERS        = 2.
  IF sy-subrc = 0.
    WRITE: / '票價 1500.00 × 200 座 = 營收', gv_revenue.
  ENDIF.

*----------------------------------------------------------------------*
* 錯誤輸入：FM 裡 RAISE invalid_input → 呼叫端 sy-subrc = 1
* EXCEPTIONS 後面的數字是「發生該例外時 sy-subrc 要變成幾」
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_CALC_REVENUE'
    EXPORTING
      iv_price      = '-99.00'
      iv_seatsocc   = 10
    IMPORTING
      ev_revenue    = gv_revenue
    EXCEPTIONS
      invalid_input = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
    WRITE: / '負數票價被 FM 擋下，sy-subrc =', sy-subrc.
  ENDIF.