REPORT zr_tr28_param_list.

TABLES ztr28_wparm.
SELECT-OPTIONS s_werks FOR ztr28_wparm-werks.

DATA: gt_wparm TYPE STANDARD TABLE OF ztr28_wparm.

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

TOP-OF-PAGE.
  SET PF-STATUS 'ZTR28LIST'.
  WRITE: / '工廠參數清單 —— 按上方工具列「維護」按鈕可進入維護畫面（會先做權限與鎖定檢查）'.
  ULINE.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'MAINT'.
      " 呼叫 T-code（不是直接呼叫 ZR_TR28_PARAM_MAINT 程式本身），
      " 讓 S_TCODE 這層權限檢查也生效——T-code 名稱要跟 SE93 建立的完全一致
      CALL TRANSACTION 'ZTR28_MAINT'.
  ENDCASE.
