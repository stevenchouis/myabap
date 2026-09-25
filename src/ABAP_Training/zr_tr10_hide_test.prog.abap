*&---------------------------------------------------------------------*
*& Report  ZR_TR10_HIDE_TEST
*& 講義 10 第 4.4 節與 4.6 節驗證用
*& 測試 1：同一行分別在 WRITE 之前、之後 HIDE，雙擊後比較取回的值
*& 測試 2：在明細清單再雙擊，用 SUBMIT ... AND RETURN 呼叫另一支報表
*&---------------------------------------------------------------------*
REPORT zr_tr10_hide_test.

TYPES ty_id TYPE c LENGTH 5.

DATA: gt_ids    TYPE STANDARD TABLE OF ty_id,
      gv_id     TYPE ty_id,
      gv_before TYPE ty_id,        " HIDE 寫在 WRITE 之前
      gv_after  TYPE ty_id,        " HIDE 寫在 WRITE 之後
      gv_submit TYPE c LENGTH 1.   " 標記「這一行雙擊要 SUBMIT」

START-OF-SELECTION.
  APPEND 'S0001' TO gt_ids.
  APPEND 'S0002' TO gt_ids.
  APPEND 'S0003' TO gt_ids.

  WRITE / '測試 1：雙擊任一學號行，比較兩種 HIDE 位置取回的值'.
  ULINE.
  LOOP AT gt_ids INTO gv_id.
    gv_before = gv_id.
    HIDE gv_before.                " 寫在 WRITE 之前
    WRITE / gv_id.
    gv_after = gv_id.
    HIDE gv_after.                 " 寫在 WRITE 之後
  ENDLOOP.
  ULINE.
  CLEAR: gv_before, gv_after.

AT LINE-SELECTION.
  IF gv_submit = 'X'.
*   測試 2：在明細清單雙擊標記過的那一行
    SUBMIT zr_tr10_hide_detail
      WITH p_id = gv_after
      AND RETURN.
  ELSE.
    WRITE: / '目前清單層級 sy-lsind：', sy-lsind.
    WRITE: / '你雙擊的那一行 sy-lisel：', sy-lisel.
    ULINE.
    WRITE: / 'HIDE 寫在 WRITE 之後，取回：', gv_after.
    WRITE: / 'HIDE 寫在 WRITE 之前，取回：', gv_before.
    ULINE.
    IF gv_after IS NOT INITIAL.
      WRITE /(60) '測試 2：雙擊這一行 → SUBMIT 另一支報表'.   " (60)：指定輸出寬度，中文字一個佔兩格，不指定會被截掉
      gv_submit = 'X'.
      HIDE: gv_submit, gv_after.
      CLEAR gv_submit.
    ENDIF.
  ENDIF.
