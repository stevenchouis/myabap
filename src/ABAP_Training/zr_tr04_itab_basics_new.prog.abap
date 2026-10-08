*&---------------------------------------------------------------------*
*& Report  ZR_TR04_ITAB_BASICS_NEW
*& 練習 4：Internal Table 基礎（答案程式，新式寫法版）
*& 對照 ZR_TR04_ITAB_BASICS：VALUE 建表、LOOP INTO DATA( )、表格運算式 itab[ ]
*& 最後一行不同：表格運算式不設 sy-subrc，找不到時改用 line_exists( ) 判斷
*&---------------------------------------------------------------------*
REPORT zr_tr04_itab_basics_new.

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
       END OF ty_student.
TYPES tt_student TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id.

START-OF-SELECTION.
* VALUE tt_student( ( 一列 ) ( 一列 ) ... )：一次建好整張表，取代逐筆填 work area + APPEND
  DATA(gt_students) = VALUE tt_student( ( id = 'S0001' name = '王小明' score = 85 )
                                        ( id = 'S0002' name = '李小美' score = 92 )
                                        ( id = 'S0003' name = '陳大文' score = 67 ) ).

* LOOP AT ... INTO DATA( )：work area 在這裡才宣告，型別是表的列型別
  WRITE / '=== 全部學生 ==='.
  LOOP AT gt_students INTO DATA(gs_student).
    WRITE: / sy-tabix, gs_student-id, gs_student-name, gs_student-score.
  ENDLOOP.

* 表格運算式 itab[ 條件 ]：直接取出符合的那一列
* 找不到會發生例外 CX_SY_ITAB_LINE_NOT_FOUND，所以先用 line_exists( ) 判斷
  IF line_exists( gt_students[ id = 'S0002' ] ).
    DATA(gv_name) = gt_students[ id = 'S0002' ]-name.
    WRITE: / 'WITH KEY 找到 S0002：', gv_name.
  ENDIF.

* itab[ n ]：第 n 列，等於 READ TABLE ... INDEX n
  IF line_exists( gt_students[ 3 ] ).
    gv_name = gt_students[ 3 ]-name.
    WRITE: / 'INDEX 3 讀到的是：', gv_name.
  ENDIF.

* 找不到：表格運算式不會設定 sy-subrc
  IF NOT line_exists( gt_students[ id = 'S9999' ] ).
    WRITE: / '查無 S9999，line_exists( ) = false'.
  ENDIF.
