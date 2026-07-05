*&---------------------------------------------------------------------*
*& Report  ZR_TR18_STRING_DATE
*& 練習 18：字串與日期處理（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr18_string_date.

DATA: gv_last  TYPE c LENGTH 10 VALUE '王',
      gv_first TYPE c LENGTH 10 VALUE '小明',
      gv_full  TYPE string,
      gv_abc   TYPE string,
      gv_csv   TYPE string VALUE 'S0001,王小明,85',
      gv_id    TYPE c LENGTH 5,
      gv_name  TYPE string,
      gv_score TYPE string,
      gv_text  TYPE c LENGTH 30 VALUE '  ABAP   is   fun  ',
      gv_str   TYPE string,
      gv_len   TYPE i,
      gv_today TYPE d,
      gv_due   TYPE d,
      gv_frst  TYPE d,
      gv_lastd TYPE d,
      gv_days  TYPE i.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 1) CONCATENATE：c 欄位尾端空白自動忽略；SEPARATED BY 給分隔符
*----------------------------------------------------------------------*
  CONCATENATE gv_last gv_first INTO gv_full.
  WRITE: / '全名：', gv_full.
  CONCATENATE 'A' 'B' 'C' INTO gv_abc SEPARATED BY '-'.
  WRITE: / '串接：', gv_abc.

*----------------------------------------------------------------------*
* 2) SPLIT：依分隔符拆進多個變數
*----------------------------------------------------------------------*
  SPLIT gv_csv AT ',' INTO gv_id gv_name gv_score.
  WRITE: / '學號：', gv_id, ' 姓名：', gv_name, ' 成績：', gv_score.

*----------------------------------------------------------------------*
* 3) 位移「寫入」：位移從 0 起算，後 3 碼 = +2(3)
*----------------------------------------------------------------------*
  gv_id+2(3) = '***'.
  WRITE: / '遮罩後學號：', gv_id.

*----------------------------------------------------------------------*
* 4) CONDENSE：整理空白（[ ] 括起來才看得出效果）
*----------------------------------------------------------------------*
  CONDENSE gv_text.
  WRITE: / 'CONDENSE 後：[', gv_text, ']'.
  gv_text = '  ABAP   is   fun  '.
  CONDENSE gv_text NO-GAPS.
  WRITE: / 'NO-GAPS 後：[', gv_text, ']'.

*----------------------------------------------------------------------*
* 5) REPLACE + TRANSLATE
*----------------------------------------------------------------------*
  gv_str = 'ABAP is fun'.
  REPLACE 'fun' WITH 'great' INTO gv_str.
  TRANSLATE gv_str TO UPPER CASE.
  WRITE: / '取代+轉大寫：', gv_str.

*----------------------------------------------------------------------*
* 6) strlen( )：c 型別不含尾端空白
*----------------------------------------------------------------------*
  gv_len = strlen( gv_full ).
  WRITE: / '全名長度：', gv_len.

*----------------------------------------------------------------------*
* 7) 日期運算：d 可直接加減天數；兩日期相減 = 天數差
*----------------------------------------------------------------------*
  gv_today = sy-datum.
  gv_due   = gv_today + 30.
  gv_days  = gv_today - '20260101'.
  WRITE: / '今天：', gv_today,
         / '30 天後：', gv_due,
         / '距 2026/01/01：', gv_days, '天'.

*----------------------------------------------------------------------*
* 8) 月初：日改 01；月末：月初 +31 必落下月 → 改下月 1 號 → 減 1 天
*    （+31 保證跨月：大小月、閏年通吃，不用自己判斷）
*----------------------------------------------------------------------*
  gv_frst = gv_today.
  gv_frst+6(2) = '01'.
  gv_lastd = gv_frst + 31.
  gv_lastd+6(2) = '01'.
  gv_lastd = gv_lastd - 1.
  WRITE: / '本月月初：', gv_frst,
         / '本月月末：', gv_lastd.
