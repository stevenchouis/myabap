*&---------------------------------------------------------------------*
*& Report  ZR_TR05_ITAB_ADVANCED_NEW
*& 練習 5：Internal Table 進階（答案程式，新式寫法版）
*& 對照 ZR_TR05_ITAB_ADVANCED：輸出相同；VALUE 建表、COND 打等第、
*& 巢狀 VALUE 建 Deep Structure、REDUCE 加總。SORT／MODIFY／DELETE 沒有新式寫法
*&---------------------------------------------------------------------*
REPORT zr_tr05_itab_advanced_new.

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
         grade TYPE c LENGTH 1,
       END OF ty_student.
TYPES tt_student TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id.

START-OF-SELECTION.
  DATA(gt_students) = VALUE tt_student( ( id = 'S0001' name = '王小明' score = 85 )
                                        ( id = 'S0002' name = '李小美' score = 92 )
                                        ( id = 'S0003' name = '陳大文' score = 67 )
                                        ( id = 'S0004' name = '張三豐' score = 45 ) ).

  DATA(gv_lines) = lines( gt_students ).
  WRITE: / '原始筆數：', gv_lines.

  SORT gt_students BY score DESCENDING.
  WRITE / '=== 依成績由高到低 ==='.
  LOOP AT gt_students INTO DATA(gs_student).
    WRITE: / sy-tabix, gs_student-id, gs_student-name, gs_student-score.
  ENDLOOP.

* COND 取代 IF/ELSEIF 賦值；寫回內表仍要 MODIFY
  LOOP AT gt_students INTO gs_student.
    gs_student-grade = COND #( WHEN gs_student-score >= 80 THEN 'A'
                               WHEN gs_student-score >= 60 THEN 'B'
                               ELSE 'C' ).
    MODIFY gt_students FROM gs_student.
  ENDLOOP.

  WRITE / '=== 打上等第 ==='.
  LOOP AT gt_students INTO gs_student.
    WRITE: / sy-tabix, gs_student-id, gs_student-name,
             gs_student-score, gs_student-grade.
  ENDLOOP.

  DELETE gt_students WHERE score < 60.

  gv_lines = lines( gt_students ).
  WRITE: / '=== 刪除不及格後剩', gv_lines, '筆 ==='.
  LOOP AT gt_students INTO gs_student.
    WRITE: / sy-tabix, gs_student-id, gs_student-name,
             gs_student-score, gs_student-grade.
  ENDLOOP.

* Part 6：Deep Structure——VALUE 可以巢狀，內層 exams 也用 VALUE #( ( ) ( ) ) 一起建好
  TYPES: BEGIN OF ty_exam,
           exam_no TYPE i,
           score   TYPE i,
         END OF ty_exam.
  TYPES tt_exam TYPE STANDARD TABLE OF ty_exam WITH NON-UNIQUE KEY exam_no.
  TYPES: BEGIN OF ty_student_deep,
           id        TYPE c LENGTH 5,
           name      TYPE string,
           exams     TYPE tt_exam,
           avg_score TYPE p LENGTH 4 DECIMALS 1,
         END OF ty_student_deep.
  TYPES tt_student_deep TYPE STANDARD TABLE OF ty_student_deep WITH NON-UNIQUE KEY id.

  DATA(gt_students_deep) = VALUE tt_student_deep(
    ( id = 'S0005' name = '林小華'
      exams = VALUE #( ( exam_no = 1 score = 78 )
                       ( exam_no = 2 score = 85 )
                       ( exam_no = 3 score = 90 ) ) )
    ( id = 'S0006' name = '黃小芳'
      exams = VALUE #( ( exam_no = 1 score = 60 )
                       ( exam_no = 2 score = 72 )
                       ( exam_no = 3 score = 55 ) ) ) ).

  WRITE / '=== Deep Structure：每位學生的小考成績與平均 ==='.
  LOOP AT gt_students_deep INTO DATA(gs_student_deep).
    LOOP AT gs_student_deep-exams INTO DATA(gs_exam).
      WRITE: / gs_student_deep-name, '第', gs_exam-exam_no, '次小考：', gs_exam-score.
    ENDLOOP.
*   REDUCE：INIT 給初始值、FOR 逐列、NEXT 每列怎麼累加，取代「累加變數 + LOOP」
    DATA(gv_total) = REDUCE i( INIT sum = 0
                               FOR exam IN gs_student_deep-exams
                               NEXT sum = sum + exam-score ).
    gs_student_deep-avg_score = gv_total / lines( gs_student_deep-exams ).
    MODIFY gt_students_deep FROM gs_student_deep TRANSPORTING avg_score
      WHERE id = gs_student_deep-id.
    WRITE: / gs_student_deep-name, '平均：', gs_student_deep-avg_score.
  ENDLOOP.
