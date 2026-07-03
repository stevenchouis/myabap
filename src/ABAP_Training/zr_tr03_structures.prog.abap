*&---------------------------------------------------------------------*
*& Report  ZR_TR03_STRUCTURES
*& 練習 3：Local Type 與 Structure（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr03_structures.

*----------------------------------------------------------------------*
* TYPES：定義「自訂型別」
* 注意：TYPES 只是型別的「藍圖」，本身不佔記憶體、不能存資料
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_student,
         id     TYPE c LENGTH 5,               " 學號
         name   TYPE string,                   " 姓名
         score1 TYPE i,                        " 期中成績
         score2 TYPE i,                        " 期末成績
         avg    TYPE p LENGTH 5 DECIMALS 1,    " 平均
       END OF ty_student.

*----------------------------------------------------------------------*
* 用自訂型別宣告「結構變數」——這才是真正佔記憶體、能存資料的物件
*----------------------------------------------------------------------*
DATA: gs_student TYPE ty_student,     " TYPE 參照自訂型別
      gs_backup  LIKE gs_student.     " LIKE 參照既有變數（跟 gs_student 同型別）

START-OF-SELECTION.
  " 用連字號「-」存取結構裡的欄位
  gs_student-id     = 'S0001'.
  gs_student-name   = '王小明'.
  gs_student-score1 = 78.
  gs_student-score2 = 91.
  gs_student-avg    = ( gs_student-score1 + gs_student-score2 ) / 2.

  " 同型別的結構可以整筆直接複製
  gs_backup = gs_student.

  " 改掉原本結構的欄位，證明備份是「另一份資料」，不會跟著變
  gs_student-name = '此欄已被改掉'.

  WRITE: / '=== 備份結構（複製後不受原結構修改影響）===',
         / '學號：', gs_backup-id,
         / '姓名：', gs_backup-name,
         / '期中：', gs_backup-score1,
         / '期末：', gs_backup-score2,
         / '平均：', gs_backup-avg.

  WRITE: / '=== 原結構（姓名已被修改）===',
         / '姓名：', gs_student-name.
