*&---------------------------------------------------------------------*
*& Report  ZR_TR02_TYPE_LIKE_NEW
*& 練習 2：變數宣告與 TYPE / LIKE（答案程式，新式寫法版）
*& 對照 ZR_TR02_TYPE_LIKE：輸出相同，差別是用行內宣告 DATA(...)
*&---------------------------------------------------------------------*
REPORT zr_tr02_type_like_new.

* 型別無法從值推導出來的變數，仍要事先宣告：
* 'p' 帶小數的金額若寫 DATA(gv_price) = '1250.50'，會被推導成 c LENGTH 7（文字）
DATA gv_price TYPE p LENGTH 8 DECIMALS 2.
CONSTANTS gc_tax_rate TYPE p LENGTH 3 DECIMALS 2 VALUE '0.05'.

START-OF-SELECTION.
  " 行內宣告：型別由右邊的值推導
  DATA(gv_count) = 3.                        " 整數字面值 → i
  DATA(gv_name)  = `基礎 ABAP Training`.     " 反引號 → string
  DATA(gv_code)  = 'TR02'.                   " 單引號 → c LENGTH 4
  DATA(gv_today) = sy-datum.                 " 系統欄位 → d
  gv_price = '1250.50'.

  " 用既有變數初始化：型別跟 gv_price 一樣（效果等於 LIKE gv_price）
  DATA(gv_price_tax) = gv_price.
  gv_price_tax = gv_price * ( 1 + gc_tax_rate ).
  DATA(gv_backup)    = gv_name.              " 跟 gv_name 同型別（string）

  WRITE: / '課程名稱：', gv_name,
         / '課程代碼：', gv_code,
         / '上課次數：', gv_count,
         / '今天日期：', gv_today,
         / '定價    ：', gv_price,
         / '含稅價  ：', gv_price_tax,
         / '備份字串：', gv_backup.
