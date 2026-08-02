REPORT zr_rap03_demo.

DATA lv_task_id TYPE zrap02_taskid VALUE 'DEMO0001'.

" 0) 清掉可能殘留的舊測試資料（僅限這個測試專用的 task_id，不動其他資料）
DELETE FROM zrap02_task WHERE task_id = @lv_task_id.
COMMIT WORK.

" 1) CREATE
MODIFY ENTITIES OF zi_rap02_task
  ENTITY Task
    CREATE FIELDS ( task_id description status priority due_date )
    WITH VALUE #( ( %cid = 'C1' task_id = lv_task_id description = 'Demo Task from EML' status = 'O' priority = 'H' due_date = '20260901' ) )
  MAPPED DATA(ls_mapped)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).

IF ls_failed-task IS NOT INITIAL.
  WRITE: / 'CREATE FAILED'.
ELSE.
  WRITE: / 'CREATE OK, task_id =', lv_task_id.
ENDIF.

COMMIT ENTITIES.

SELECT SINGLE task_id, description, status, priority, due_date, created_at, created_by
  FROM zrap02_task
  WHERE task_id = @lv_task_id
  INTO @DATA(ls_check).

WRITE: / 'Read back description:', ls_check-description.
WRITE: / 'Read back status:', ls_check-status.
WRITE: / 'created_by (預期空白，因為 rap05 才教 Determination 自動填值):', ls_check-created_by.

" 2) UPDATE
MODIFY ENTITIES OF zi_rap02_task
  ENTITY Task
    UPDATE FIELDS ( status )
    WITH VALUE #( ( task_id = lv_task_id status = 'D' ) )
  FAILED DATA(ls_failed2)
  REPORTED DATA(ls_reported2).

IF ls_failed2-task IS NOT INITIAL.
  WRITE: / 'UPDATE FAILED'.
ELSE.
  WRITE: / 'UPDATE OK'.
ENDIF.

COMMIT ENTITIES.

SELECT SINGLE status FROM zrap02_task WHERE task_id = @lv_task_id INTO @DATA(lv_status_after).
WRITE: / 'status after update:', lv_status_after.

" 3) DELETE
MODIFY ENTITIES OF zi_rap02_task
  ENTITY Task
    DELETE
    FROM VALUE #( ( task_id = lv_task_id ) )
  FAILED DATA(ls_failed3)
  REPORTED DATA(ls_reported3).

COMMIT ENTITIES.

SELECT SINGLE task_id FROM zrap02_task WHERE task_id = @lv_task_id INTO @DATA(lv_check_deleted).
IF sy-subrc <> 0.
  WRITE: / 'DELETE OK, record no longer exists'.
ELSE.
  WRITE: / 'DELETE FAILED, record still exists'.
ENDIF.
