*&---------------------------------------------------------------------*
*& Report  ZR_TR03_STRUCTURES_NEW
*& 練習 3：Local Type 與 Structure（答案程式，新式寫法版）
*& 對照 ZR_TR03_STRUCTURES：輸出相同；結構用 VALUE #( ) 一次填好
*&---------------------------------------------------------------------*
REPORT zr_tr03_structures_new.

TYPES: BEGIN OF ty_student,
         id     TYPE c LENGTH 5,
         name   TYPE string,
         score1 TYPE i,
         score2 TYPE i,
         avg    TYPE p LENGTH 5 DECIMALS 1,
       END OF ty_student.

DATA gs_student TYPE ty_student.

START-OF-SELECTION.
  " VALUE #( 欄位 = 值 ... )：一次填好整個結構，沒寫到的欄位是初始值
  gs_student = VALUE #( id     = 'S0001'
                        name   = '王小明'
                        score1 = 78
                        score2 = 91 ).
  gs_student-avg = ( gs_student-score1 + gs_student-score2 ) / 2.

  " 行內宣告：型別跟 gs_student 一樣，同時整筆複製
  DATA(gs_backup) = gs_student.

  gs_student-name = '此欄已被改掉'.

  WRITE: / '=== 備份結構（複製後不受原結構修改影響）===',
         / '學號：', gs_backup-id,
         / '姓名：', gs_backup-name,
         / '期中：', gs_backup-score1,
         / '期末：', gs_backup-score2,
         / '平均：', gs_backup-avg.

  WRITE: / '=== 原結構（姓名已被修改）===',
         / '姓名：', gs_student-name.
