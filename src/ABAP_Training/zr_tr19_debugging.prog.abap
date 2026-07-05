*&---------------------------------------------------------------------*
*& Report  ZR_TR19_DEBUGGING
*& 練習 19：Debugger 抓 bug（答案程式＝修正版）
*& 三個 bug 的修正處都以 FIX 註解標明；埋 bug 原版見 ex19 題目
*&---------------------------------------------------------------------*
REPORT zr_tr19_debugging.

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
       END OF ty_student.
DATA: gt_students TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id,
      gs_student  TYPE ty_student,
      gv_sum      TYPE i,
      gv_count    TYPE i,
      gv_avg      TYPE p LENGTH 6 DECIMALS 2.

PARAMETERS p_min TYPE i DEFAULT 60.

START-OF-SELECTION.
  gs_student-id = 'S0001'. gs_student-name = '王小明'. gs_student-score = 85.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0002'. gs_student-name = '李小美'. gs_student-score = 92.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0003'. gs_student-name = '陳大文'. gs_student-score = 67.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0004'. gs_student-name = '張三豐'. gs_student-score = 45.
  APPEND gs_student TO gt_students.

*----------------------------------------------------------------------*
* Bug A：LOOP INTO 拿到的是複本，改完沒寫回 → 表格內容不變（白改）
* FIX：MODIFY 寫回（或改用 LOOP ASSIGNING，見講義 16）
* Debugger 證據：ENDLOOP 後看 gt_students，score 仍是 85/92/67/45
*----------------------------------------------------------------------*
  LOOP AT gt_students INTO gs_student.
    gs_student-score = gs_student-score + 5.
    MODIFY gt_students FROM gs_student.            " FIX A
  ENDLOOP.

*----------------------------------------------------------------------*
* Bug B：p_min 很高時一筆都沒迴圈到 → gv_count = 0
*        → 除以零 dump COMPUTE_INT_ZERODIVIDE
* FIX：除之前檢查分母
* Debugger 證據：ST22 案發行 = gv_avg 計算行；該行前 gv_count = 0
*----------------------------------------------------------------------*
  CLEAR: gv_sum, gv_count.
  LOOP AT gt_students INTO gs_student WHERE score >= p_min.
    gv_sum   = gv_sum + gs_student-score.
    gv_count = gv_count + 1.
  ENDLOOP.
  IF gv_count > 0.                                 " FIX B
    gv_avg = gv_sum / gv_count.
    WRITE: / '達門檻人數：', gv_count, '平均：', gv_avg.
  ELSE.
    WRITE: / '無人達門檻', p_min, '分'.
  ENDIF.

*----------------------------------------------------------------------*
* Bug C：READ TABLE 失敗不會清 work area → 印出的是殘留值
* FIX：檢查 sy-subrc（講義 4 的鐵律）
* Debugger 證據：READ 後 sy-subrc = 4，gs_student 仍是迴圈最後一筆
*----------------------------------------------------------------------*
  READ TABLE gt_students INTO gs_student WITH KEY id = 'S9999'.
  IF sy-subrc = 0.                                 " FIX C
    WRITE: / 'S9999 的成績：', gs_student-score.
  ELSE.
    WRITE: / '查無此學號 S9999'.
  ENDIF.
