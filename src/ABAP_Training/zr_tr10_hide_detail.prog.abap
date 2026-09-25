*&---------------------------------------------------------------------*
*& Report  ZR_TR10_HIDE_DETAIL
*& 講義 10 第 4.6 節驗證用：被 ZR_TR10_HIDE_TEST 以 SUBMIT 呼叫的報表
*& 收到的 p_id 就是呼叫端用 HIDE 取回的學號
*&---------------------------------------------------------------------*
REPORT zr_tr10_hide_detail.

PARAMETERS p_id TYPE c LENGTH 5.

START-OF-SELECTION.
  WRITE / '這是另一支報表 ZR_TR10_HIDE_DETAIL'.
  WRITE: / '收到的 p_id：', p_id.
  ULINE.
  WRITE / '按 F3 返回：因為呼叫端用了 AND RETURN，應回到原本的清單'.
