REPORT zr_tr22_msgid_chk MESSAGE-ID ztr22.
* 驗證講義 22 §4.1：REPORT ... MESSAGE-ID 之後，MESSAGE 可以省略訊息類別（2026-10-08）
* 用 MESSAGE ... INTO 把訊息文字放進變數，不實際顯示，方便無頭執行比對

DATA gv_text TYPE string.

* 1) 省略訊息類別：使用 REPORT 宣告的 ZTR22
MESSAGE s002 WITH 5 sy-uname sy-datum INTO gv_text.
WRITE: / '1)', sy-msgid, sy-msgno, gv_text.

* 2) 明確寫訊息類別：以括號裡的為準，蓋過 REPORT 的預設
MESSAGE s001(00) WITH 'OVERRIDE' INTO gv_text.
WRITE: / '2)', sy-msgid, sy-msgno, gv_text.
