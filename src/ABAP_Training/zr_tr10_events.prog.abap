*&---------------------------------------------------------------------*
*& Report  ZR_TR10_EVENTS
*& 練習 10：Report Event 事件流程（答案程式）
*&---------------------------------------------------------------------*
* Report 不是「從上跑到下」，而是由「事件」驅動：
* 系統在不同時機觸發不同事件區塊，順序與寫的位置無關
*&---------------------------------------------------------------------*
REPORT zr_tr10_events NO STANDARD PAGE HEADING LINE-SIZE 60.

TYPES: BEGIN OF ty_student,
         id     TYPE c LENGTH 5,
         name   TYPE string,
         score1 TYPE i,           " 期中
         score2 TYPE i,           " 期末
       END OF ty_student.

DATA: gt_students TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id,
      gs_student  TYPE ty_student,
      gs_detail   TYPE ty_student,
      gv_count    TYPE i.

DATA gv_score TYPE i.
SELECT-OPTIONS s_score FOR gv_score.

* LIKE LINE OF：宣告「跟某個 internal table 的一列同型別」的 work area
DATA gs_score LIKE LINE OF s_score.

*----------------------------------------------------------------------*
* 事件 1：INITIALIZATION
* 時機：程式啟動、選擇畫面顯示「之前」——適合給預設值
*----------------------------------------------------------------------*
INITIALIZATION.
  gs_score-sign   = 'I'.      " I=include
  gs_score-option = 'BT'.     " BT=between
  gs_score-low    = 0.
  gs_score-high   = 100.
  APPEND gs_score TO s_score.

*----------------------------------------------------------------------*
* 事件 2：AT SELECTION-SCREEN
* 時機：使用者按「執行」後、主程式跑「之前」——適合驗證輸入
* E 類訊息會把使用者擋在選擇畫面上，修正後才能繼續
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  LOOP AT s_score INTO gs_score.
    IF gs_score-low < 0 OR gs_score-high > 999.
      MESSAGE '成績範圍請輸入 0～999' TYPE 'E'.
    ENDIF.
  ENDLOOP.

*----------------------------------------------------------------------*
* 事件 3：START-OF-SELECTION——主處理
*----------------------------------------------------------------------*
START-OF-SELECTION.
  gs_student-id = 'S0001'. gs_student-name = '王小明'.
  gs_student-score1 = 78. gs_student-score2 = 91.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0002'. gs_student-name = '李小美'.
  gs_student-score1 = 88. gs_student-score2 = 95.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0003'. gs_student-name = '陳大文'.
  gs_student-score1 = 60. gs_student-score2 = 72.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0004'. gs_student-name = '張三豐'.
  gs_student-score1 = 45. gs_student-score2 = 55.
  APPEND gs_student TO gt_students.

  gv_count = 0.
  LOOP AT gt_students INTO gs_student WHERE score1 IN s_score.
    gv_count = gv_count + 1.
    WRITE: / gs_student-id, gs_student-name,
             gs_student-score1, gs_student-score2.
    HIDE gs_student-id.     " 把這一行對應的學號「藏」進清單（給事件 6 用）
  ENDLOOP.
  CLEAR gs_student-id.      " 清掉，避免雙擊「非資料行」時撈到殘留值

*----------------------------------------------------------------------*
* 事件 4：END-OF-SELECTION
* 時機：主處理全部結束——適合寫總結
*----------------------------------------------------------------------*
END-OF-SELECTION.
  ULINE.
  WRITE: / '符合條件筆數：', gv_count.

*----------------------------------------------------------------------*
* 事件 5：TOP-OF-PAGE
* 時機：基本清單每一頁的開頭（由第一個 WRITE 觸發）——放表頭
*----------------------------------------------------------------------*
TOP-OF-PAGE.
  WRITE: / '學生成績清單（雙擊任一行看明細）'.
  ULINE.

*----------------------------------------------------------------------*
* 事件 6：AT LINE-SELECTION
* 時機：使用者在清單上雙擊（或按 F2）——產生互動明細（第二層清單）
* HIDE 過的欄位值會依雙擊的那一行自動還原
*----------------------------------------------------------------------*
AT LINE-SELECTION.
  IF gs_student-id IS INITIAL.
    WRITE / '請雙擊資料行'.
  ELSE.
    READ TABLE gt_students INTO gs_detail WITH KEY id = gs_student-id.
    IF sy-subrc = 0.
      WRITE: / '=== 學生明細（第', sy-lsind, '層清單）===',
             / '學號：', gs_detail-id,
             / '姓名：', gs_detail-name,
             / '期中：', gs_detail-score1,
             / '期末：', gs_detail-score2.
    ENDIF.
  ENDIF.
