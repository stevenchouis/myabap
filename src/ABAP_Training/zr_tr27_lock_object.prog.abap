REPORT zr_tr27_lock_object.

PARAMETERS p_id TYPE ztr21_stud-id DEFAULT 'S9001' OBLIGATORY.

DATA: ls_stud TYPE ztr21_stud.

WRITE: / 'ex27 Lock Object 練習：', p_id.
WRITE: / '=================================='.

* ---- 1. 上鎖 ----
CALL FUNCTION 'ENQUEUE_EZTR21_STUD'
  EXPORTING
    mandt          = sy-mandt
    id             = p_id
  EXCEPTIONS
    foreign_lock   = 1
    system_failure = 2
    OTHERS         = 3.

CASE sy-subrc.
  WHEN 0.
    WRITE: / '呼叫 ENQUEUE_EZTR21_STUD（學號', p_id, '）：sy-subrc = 0（鎖定成功）'.
  WHEN 1.
    WRITE: / '呼叫 ENQUEUE_EZTR21_STUD（學號', p_id, '）：sy-subrc = 1（已被其他人鎖定，中止）'.
    RETURN.
  WHEN OTHERS.
    WRITE: / '呼叫 ENQUEUE_EZTR21_STUD（學號', p_id, '）：sy-subrc =', sy-subrc, '（鎖定系統異常，中止）'.
    RETURN.
ENDCASE.

* ---- 2. 讀取資料（模擬進入編輯畫面） ----
SELECT SINGLE * FROM ztr21_stud INTO ls_stud WHERE id = p_id.
IF sy-subrc = 0.
  WRITE: / '讀取到學生資料：', ls_stud-id, ls_stud-name, ls_stud-score.
ELSE.
  WRITE: / '查無此學號的學生資料：', p_id.
ENDIF.

* ---- 3. 驗證 E 模式可疊加：同一使用者再鎖一次 ----
CALL FUNCTION 'ENQUEUE_EZTR21_STUD'
  EXPORTING
    mandt          = sy-mandt
    id             = p_id
  EXCEPTIONS
    foreign_lock   = 1
    system_failure = 2
    OTHERS         = 3.

IF sy-subrc = 0.
  WRITE: / '再次呼叫 ENQUEUE_EZTR21_STUD（同一使用者）：sy-subrc = 0（鎖定次數疊加，未被自己擋下）'.
ELSE.
  WRITE: / '再次呼叫 ENQUEUE_EZTR21_STUD：sy-subrc =', sy-subrc, '（非預期，E 模式應允許同一使用者疊加）'.
ENDIF.

* ---- 4./5. 解鎖：呼叫兩次 ENQUEUE 就要呼叫兩次 DEQUEUE 才會真正解鎖 ----
CALL FUNCTION 'DEQUEUE_EZTR21_STUD'
  EXPORTING
    mandt = sy-mandt
    id    = p_id.
WRITE: / '呼叫 DEQUEUE_EZTR21_STUD 第 1 次'.

CALL FUNCTION 'DEQUEUE_EZTR21_STUD'
  EXPORTING
    mandt = sy-mandt
    id    = p_id.
WRITE: / '呼叫 DEQUEUE_EZTR21_STUD 第 2 次'.

WRITE: / '本次編輯流程結束，鎖定已釋放'.
