*&---------------------------------------------------------------------*
*& Report  ZR_TR18_STRING_DATE_NEW
*& 練習 18：字串與日期處理（答案程式，新式寫法版）
*& 對照 ZR_TR18_STRING_DATE：輸出相同；字串指令改用字串模板與字串函式，
*& 位移取值與日期運算沒有新式寫法，維持原樣
*&---------------------------------------------------------------------*
REPORT zr_tr18_string_date_new.

DATA: gv_last  TYPE c LENGTH 10 VALUE '王',
      gv_first TYPE c LENGTH 10 VALUE '小明',
      gv_csv   TYPE string VALUE 'S0001,王小明,85',
      gv_id    TYPE c LENGTH 5,
      gv_text  TYPE c LENGTH 30 VALUE '  ABAP   is   fun  ',
      gv_today TYPE d,
      gv_due   TYPE d,
      gv_frst  TYPE d,
      gv_lastd TYPE d,
      gv_days  TYPE i.

START-OF-SELECTION.
* 1) 字串模板 |...|：{ } 裡放變數；c 欄位的尾端空白同樣被忽略
  DATA(gv_full) = |{ gv_last }{ gv_first }|.
  WRITE: / '全名：', gv_full.
* && 串接運算子：把幾段字串接起來
  DATA(gv_abc) = `A` && `-` && `B` && `-` && `C`.
  WRITE: / '串接：', gv_abc.

* 2) segment( )：取第 n 段；SPLIT 一次拆多個變數仍最直接
  gv_id = segment( val = gv_csv index = 1 sep = ',' ).
  DATA(gv_name)  = segment( val = gv_csv index = 2 sep = ',' ).
  DATA(gv_score) = segment( val = gv_csv index = 3 sep = ',' ).
  WRITE: / '學號：', gv_id, ' 姓名：', gv_name, ' 成績：', gv_score.

* 3) 位移寫入：沒有新式寫法
  gv_id+2(3) = '***'.
  WRITE: / '遮罩後學號：', gv_id.

* 4) condense( )：函式寫法，回傳整理後的字串
  gv_text = condense( gv_text ).
  WRITE: / 'CONDENSE 後：[', gv_text, ']'.
  gv_text = '  ABAP   is   fun  '.
  gv_text = condense( val = gv_text del = ` ` from = ` ` to = `` ).
  WRITE: / 'NO-GAPS 後：[', gv_text, ']'.

* 5) replace( ) + to_upper( )：函式可以巢狀，一行完成
  DATA(gv_str) = to_upper( replace( val = `ABAP is fun` sub = `fun` with = `great` ) ).
  WRITE: / '取代+轉大寫：', gv_str.

* 6) strlen( )：本來就是函式
  DATA(gv_len) = strlen( gv_full ).
  WRITE: / '全名長度：', gv_len.

* 7)～8) 日期運算：沒有新式寫法
  gv_today = sy-datum.
  gv_due   = gv_today + 30.
  gv_days  = gv_today - '20260101'.
  WRITE: / '今天：', gv_today,
         / '30 天後：', gv_due,
         / '距 2026/01/01：', gv_days, '天'.

  gv_frst = gv_today.
  gv_frst+6(2) = '01'.
  gv_lastd = gv_frst + 31.
  gv_lastd+6(2) = '01'.
  gv_lastd = gv_lastd - 1.
  WRITE: / '本月月初：', gv_frst,
         / '本月月末：', gv_lastd.
