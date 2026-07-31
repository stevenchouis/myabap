REPORT zr_tr28_param_list.

TABLES: ztr28_wparm, sscrfields.

SELECT-OPTIONS s_werks FOR ztr28_wparm-werks.

SELECTION-SCREEN FUNCTION KEY 1.

DATA: gt_wparm TYPE STANDARD TABLE OF ztr28_wparm.

INITIALIZATION.
  sscrfields-functxt_01 = '維護主檔(SM30)'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      " 示範「土法煉鋼」的做法：直接呼叫 SM30，完全不經過 ZR_TR28_PARAM_MAINT 那個
      " Wrapper——沒有 AUTHORITY-CHECK、沒有 Lock Object、也沒有依工廠篩選，
      " 跟 ZR_TR28_PARAM_MAINT（AUTHORITY-CHECK -> ENQUEUE -> VIEW_MAINTENANCE_CALL
      " 帶 WERKS 篩選 -> DEQUEUE）刻意做對照，說明為什麼需要包一層 Wrapper。
      SET PARAMETER ID 'VIM' FIELD 'ZTR28_WPARM'.
      CALL TRANSACTION 'SM30' AND SKIP FIRST SCREEN.
  ENDCASE.

START-OF-SELECTION.
  SELECT * FROM ztr28_wparm
    WHERE werks IN @s_werks
    ORDER BY werks, param
    INTO TABLE @gt_wparm.

  LOOP AT gt_wparm INTO DATA(gs_wparm).
    WRITE: / gs_wparm-werks, gs_wparm-param, gs_wparm-parval, gs_wparm-partxt.
  ENDLOOP.

  IF sy-subrc <> 0.
    WRITE: / '（沒有資料，或選取條件沒有命中）'.
  ENDIF.
