REPORT zr_tr04_new_chk.
* 驗證講義 3／4／18 新式寫法對照的細節（2026-10-08）

TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
       END OF ty_student,
       BEGIN OF ty_student_lite,
         id   TYPE c LENGTH 5,
         name TYPE string,
         memo TYPE string,
       END OF ty_student_lite.
TYPES tt_student TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id.

DATA: gs_full TYPE ty_student,
      gs_lite TYPE ty_student_lite,
      gs_hit  TYPE ty_student.

START-OF-SELECTION.
* 1) MOVE-CORRESPONDING vs CORRESPONDING #( )：目的端多出的欄位
  gs_full = VALUE #( id = 'S0001' name = '王小明' score = 85 ).
  gs_lite-memo = 'KEEP'.
  MOVE-CORRESPONDING gs_full TO gs_lite.
  WRITE: / '1a) MOVE-CORRESPONDING :', gs_lite-id, gs_lite-name, gs_lite-memo.
  gs_lite-memo = 'KEEP'.
  gs_lite = CORRESPONDING #( gs_full ).
  WRITE: / '1b) CORRESPONDING #( ) :', gs_lite-id, gs_lite-name, gs_lite-memo.
  gs_lite-memo = 'KEEP'.
  gs_lite = CORRESPONDING #( BASE ( gs_lite ) gs_full ).
  WRITE: / '1c) CORRESPONDING BASE :', gs_lite-id, gs_lite-name, gs_lite-memo.

* 2) 表格運算式找不到
  DATA(gt_students) = VALUE tt_student( ( id = 'S0001' name = '王小明' score = 85 ) ).
  TRY.
      gs_hit = gt_students[ id = 'S9999' ].
      WRITE: / '2) found'.
    CATCH cx_sy_itab_line_not_found.
      WRITE: / '2) CX_SY_ITAB_LINE_NOT_FOUND, sy-subrc =', sy-subrc.
  ENDTRY.

* 3) VALUE #( itab[ ] OPTIONAL / DEFAULT )
  gs_hit = VALUE #( gt_students[ id = 'S9999' ] OPTIONAL ).
  WRITE: / '3a) OPTIONAL :', gs_hit-id, gs_hit-name, gs_hit-score.
  gs_hit = VALUE #( gt_students[ id = 'S9999' ] DEFAULT VALUE #( id = 'XXXXX' ) ).
  WRITE: / '3b) DEFAULT  :', gs_hit-id.

* 4) APPEND VALUE #( ) TO
  APPEND VALUE #( id = 'S0002' name = '李小美' score = 92 ) TO gt_students.
  WRITE: / '4) lines =', lines( gt_students ).

* 5) replace( ) occ = 0
  DATA(gv_s) = replace( val = `a-b-c` sub = `-` with = `+` ).
  DATA(gv_all) = replace( val = `a-b-c` sub = `-` with = `+` occ = 0 ).
  WRITE: / '5) replace:', gv_s, ' occ=0:', gv_all.
