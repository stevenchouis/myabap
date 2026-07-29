REPORT zr_en06_atsave_unit_test.

DATA lo_impl TYPE REF TO zcl_en06_workorder_atsave.
DATA ls_header TYPE cobai_s_header_dialog.

WRITE: / 'EN06 ZCL_EN06_WORKORDER_ATSAVE 安全閘單元測試（不經過真實 BAdI 派送）'.
WRITE: / '=============================================================='.

CREATE OBJECT lo_impl.

* ---- 1. 清掉測試會用到的舊記錄，方便重跑 ----
DELETE FROM zen06_atsave_log WHERE werks = '1011' AND auart = 'PP71'.
COMMIT WORK.

* ---- 2. 安全閘打開的組合：1011/PP71，預期會寫入稽核記錄 ----
CLEAR ls_header.
ls_header-werks = '1011'.
ls_header-auart = 'PP71'.
ls_header-aufnr = 'UNITTEST001'.

lo_impl->if_ex_workorder_update~at_save( is_header_dialog = ls_header ).

DATA(lv_count_open) = 0.
SELECT COUNT(*) FROM zen06_atsave_log
  WHERE werks = '1011' AND auart = 'PP71'
  INTO @lv_count_open.
WRITE: / '安全閘組合（1011/PP71）呼叫後，稽核記錄筆數 =', lv_count_open, '(預期 1)'.

* ---- 3. 安全閘關閉的組合：真實廠別但不是 PP71，預期不寫入 ----
CLEAR ls_header.
ls_header-werks = '1011'.
ls_header-auart = 'PP01'.
ls_header-aufnr = 'UNITTEST002'.

lo_impl->if_ex_workorder_update~at_save( is_header_dialog = ls_header ).

DATA(lv_count_other) = 0.
SELECT COUNT(*) FROM zen06_atsave_log
  WHERE aufnr = 'UNITTEST002'
  INTO @lv_count_other.
WRITE: / '安全閘組合以外（1011/PP01）呼叫後，稽核記錄筆數 =', lv_count_other, '(預期 0)'.