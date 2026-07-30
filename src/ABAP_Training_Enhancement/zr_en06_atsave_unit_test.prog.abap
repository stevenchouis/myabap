REPORT zr_en06_atsave_unit_test.

DATA lo_impl TYPE REF TO zcl_en06_workorder_atsave.
DATA ls_header TYPE cobai_s_header_dialog.

WRITE: / 'EN06 ZCL_EN06_WORKORDER_ATSAVE 安全閘單元測試（不經過真實 BAdI 派送）'.
WRITE: / '=============================================================='.

CREATE OBJECT lo_impl.

* ---- 1. 清掉「本測試專用」的舊記錄，方便重跑 ----
* ⚠️ 只刪測試會用到的特定 AUFNR，不對 werks/auart 做全面 DELETE，
*    避免誤刪真實 CO01 存檔留下的稽核記錄（如 %00000000001 那幾筆）。
DELETE FROM zen06_atsave_log WHERE aufnr = 'UNITTEST001' OR aufnr = 'UNITTEST002'.
COMMIT WORK.

* ---- 2. 安全閘打開的組合：1011/PP71，預期會寫入稽核記錄 ----
CLEAR ls_header.
ls_header-werks = '1011'.
ls_header-auart = 'PP71'.
ls_header-aufnr = 'UNITTEST001'.

lo_impl->if_ex_workorder_update~at_save( is_header_dialog = ls_header ).

DATA(lv_count_open) = 0.
SELECT COUNT(*) FROM zen06_atsave_log
  WHERE aufnr = 'UNITTEST001'
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

* ---- 4. NUMBER_SWITCH 補課：驗證「暫時號碼 -> 真實號碼」回填邏輯 ----
* 背景：真實 CO01 建單時，AT_SAVE 拿到的 AUFNR 還是暫時號碼（如 %00000000001），
* 每次新建工單都從這個暫時號碼重新起算，導致稽核表裡不同真實工單卻共用同一個
* AUFNR，這個問題已經在真實資料裡重現（2026-07-29／2026-07-30 兩筆記錄的
* AUFNR 都是 %00000000001）。NUMBER_SWITCH 是 SAP 標準機制在號碼確定後另外呼叫
* 的掛勾點，這裡驗證 AT_SAVE 寫入暫時號碼後，NUMBER_SWITCH 能正確回填成真實號碼。
WRITE: / ''.
WRITE: / '---- NUMBER_SWITCH 回填測試 ----'.

DELETE FROM zen06_atsave_log WHERE aufnr = '%TESTTEMP01' OR aufnr = 'UT_FINAL001'.
COMMIT WORK.

CLEAR ls_header.
ls_header-werks = '1011'.
ls_header-auart = 'PP71'.
ls_header-aufnr = '%TESTTEMP01'.

lo_impl->if_ex_workorder_update~at_save( is_header_dialog = ls_header ).

DATA(lv_count_temp_before) = 0.
SELECT COUNT(*) FROM zen06_atsave_log
  WHERE aufnr = '%TESTTEMP01'
  INTO @lv_count_temp_before.
WRITE: / 'AT_SAVE 寫入暫時號碼後，AUFNR=%TESTTEMP01 筆數 =', lv_count_temp_before, '(預期 1)'.

lo_impl->if_ex_workorder_update~number_switch(
  i_aufnr_old = '%TESTTEMP01'
  i_aufnr_new = 'UT_FINAL001'
  i_aufpl_old = '0000000000'
  i_aufpl_new = '0000000000' ).

DATA(lv_count_temp_after) = 0.
SELECT COUNT(*) FROM zen06_atsave_log
  WHERE aufnr = '%TESTTEMP01'
  INTO @lv_count_temp_after.
WRITE: / 'NUMBER_SWITCH 呼叫後，暫時號碼 AUFNR=%TESTTEMP01 剩餘筆數 =', lv_count_temp_after, '(預期 0)'.

DATA(lv_count_final) = 0.
SELECT COUNT(*) FROM zen06_atsave_log
  WHERE aufnr = 'UT_FINAL001'
  INTO @lv_count_final.
WRITE: / 'NUMBER_SWITCH 呼叫後，回填的真實號碼 AUFNR=UT_FINAL001 筆數 =', lv_count_final, '(預期 1)'.

* ---- 5. 清掉本次測試留下的記錄，避免污染真實稽核表 ----
* ⚠️ 同步驟 1，只刪測試專用的 AUFNR，不對 werks/auart 做全面 DELETE。
DELETE FROM zen06_atsave_log WHERE aufnr = 'UNITTEST001' OR aufnr = 'UNITTEST002'
  OR aufnr = '%TESTTEMP01' OR aufnr = 'UT_FINAL001'.
COMMIT WORK.
WRITE: / ''.
WRITE: / '測試結束，已清除本次測試產生的記錄。'.
