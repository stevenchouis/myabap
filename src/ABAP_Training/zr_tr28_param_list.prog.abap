REPORT zr_tr28_param_list.

* ⚠️ 本程式已於 ex28 最終版設計中棄用（2026-07-31）。
* 原本的功能（「沒有保護」的對照按鈕，直接呼叫 Parameter Transaction ZTR28_SM30
* 跳進 SM30）已經併入 ZR_TR28_PRICE_CALC 的選取畫面按鈕，不需要另外維護一支
* 專門展示「不安全做法」的清單程式，教學上重複。
*
* 保留這個物件（沒有清空刪除）是因為 ADT 沒有刪除 ABAP 物件的 API，
* 只能把原始碼改成這份說明留存；物件本身留在 $TMP 當殘留物無妨。
* 正式的維護入口見 ZR_TR28_PARAM_MAINT（T-code ZTR28_MAINT），
* 主要報表見 ZR_TR28_PRICE_CALC。

WRITE: / '本程式已棄用，請改用 ZR_TR28_PRICE_CALC（選取畫面按鈕可直接跳去維護主檔）'.
