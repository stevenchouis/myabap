*&---------------------------------------------------------------------*
*& Report  ZR_TR02_TYPE_LIKE
*& 練習 2：變數宣告與 TYPE / LIKE（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr02_type_like.

*----------------------------------------------------------------------*
* TYPE：參照「型別」宣告變數（最常用）
*----------------------------------------------------------------------*
DATA: gv_count TYPE i,                        " 整數
      gv_name  TYPE string,                   " 可變長度字串
      gv_code  TYPE c LENGTH 4,               " 固定長度字元（4 碼）
      gv_price TYPE p LENGTH 8 DECIMALS 2,    " 壓縮數值，小數 2 位（金額常用）
      gv_today TYPE d.                        " 日期，格式 YYYYMMDD

*----------------------------------------------------------------------*
* LIKE：參照「既有的資料物件（變數）」宣告
* 意思是「型別跟那個變數一樣」——來源變數改型別時會自動跟著改，
* 適合宣告「一定要跟某變數同型別」的搭檔變數（備份、暫存）
*----------------------------------------------------------------------*
DATA: gv_price_tax LIKE gv_price,     " 跟 gv_price 同型別
      gv_backup    LIKE gv_name.      " 跟 gv_name  同型別

*----------------------------------------------------------------------*
* CONSTANTS：常數，宣告時必須用 VALUE 給值，之後不可修改
*----------------------------------------------------------------------*
CONSTANTS gc_tax_rate TYPE p LENGTH 3 DECIMALS 2 VALUE '0.05'.

START-OF-SELECTION.
  " 用等號「=」指定值
  gv_count = 3.
  gv_name  = '基礎 ABAP Training'.
  gv_code  = 'TR02'.
  gv_price = '1250.50'.
  gv_today = sy-datum.    " sy-datum 是系統欄位：今天的日期

  " 變數可以參與運算
  gv_price_tax = gv_price * ( 1 + gc_tax_rate ).
  gv_backup    = gv_name.

  WRITE: / '課程名稱：', gv_name,
         / '課程代碼：', gv_code,
         / '上課次數：', gv_count,
         / '今天日期：', gv_today,
         / '定價    ：', gv_price,
         / '含稅價  ：', gv_price_tax,
         / '備份字串：', gv_backup.
