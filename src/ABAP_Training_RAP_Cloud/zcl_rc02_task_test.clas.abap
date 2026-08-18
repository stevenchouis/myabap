CLASS zcl_rc02_task_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC

  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS setup.
    METHODS create_update_delete FOR TESTING.
    METHODS create_invalid_status FOR TESTING.
    METHODS execute_mark_done FOR TESTING.

ENDCLASS.


CLASS zcl_rc02_task_test IMPLEMENTATION.

  METHOD setup.

    " 確保每次測試前都是乾淨狀態，避免前一次測試斷言失敗、
    " 中止在 DELETE 清理步驟之前，導致殘留資料撞到 Key 已存在的錯誤
    MODIFY ENTITIES OF zi_rc01_task
      ENTITY Task
      DELETE
        FROM VALUE #( ( %key-task_id = 'RC02TEST01' )
                       ( %key-task_id = 'RC02TEST02' )
                       ( %key-task_id = 'RC02TEST03' ) )
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    COMMIT ENTITIES
      RESPONSE OF zi_rc01_task
      FAILED DATA(ls_failed_commit)
      REPORTED DATA(ls_reported_commit).

  ENDMETHOD.

  METHOD create_update_delete.

    DATA(lv_id) = 'RC02TEST01'.

    " ---- CREATE ----
    MODIFY ENTITIES OF zi_rc01_task
      ENTITY Task
      CREATE FIELDS ( task_id description status priority due_date )
        WITH VALUE #( ( %cid = 'C1'
                         task_id = lv_id
                         description = 'ABAP Unit created task'
                         status = 'O'
                         priority = 'M'
                         due_date = '20261231' ) )
      FAILED DATA(ls_failed_create)
      REPORTED DATA(ls_reported_create).

    IF ls_reported_create-task IS NOT INITIAL.
      cl_abap_unit_assert=>fail( ls_reported_create-task[ 1 ]-%msg->if_message~get_text( ) ).
    ENDIF.
    cl_abap_unit_assert=>assert_initial( ls_failed_create-task ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc01_task
      FAILED DATA(ls_failed_commit1)
      REPORTED DATA(ls_reported_commit1).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit1-task ).

    " ---- READ: verify create + Determination auto-fill ----
    READ ENTITIES OF zi_rc01_task
      ENTITY Task
      FIELDS ( description status created_at created_by )
      WITH VALUE #( ( %key-task_id = lv_id ) )
      RESULT DATA(lt_read1).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_read1 ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_read1[ 1 ]-description
                                         exp = 'ABAP Unit created task' ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_read1[ 1 ]-created_at ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_read1[ 1 ]-created_by ).

    " ---- UPDATE ----
    MODIFY ENTITIES OF zi_rc01_task
      ENTITY Task
      UPDATE FIELDS ( status )
        WITH VALUE #( ( %key-task_id = lv_id status = 'D' ) )
      FAILED DATA(ls_failed_update)
      REPORTED DATA(ls_reported_update).

    cl_abap_unit_assert=>assert_initial( ls_failed_update-task ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc01_task
      FAILED DATA(ls_failed_commit2)
      REPORTED DATA(ls_reported_commit2).

    " ---- READ: verify update ----
    READ ENTITIES OF zi_rc01_task
      ENTITY Task
      FIELDS ( status )
      WITH VALUE #( ( %key-task_id = lv_id ) )
      RESULT DATA(lt_read2).

    cl_abap_unit_assert=>assert_equals( act = lt_read2[ 1 ]-status exp = 'D' ).

    " ---- DELETE (cleanup) ----
    MODIFY ENTITIES OF zi_rc01_task
      ENTITY Task
      DELETE
        FROM VALUE #( ( %key-task_id = lv_id ) )
      FAILED DATA(ls_failed_delete)
      REPORTED DATA(ls_reported_delete).

    cl_abap_unit_assert=>assert_initial( ls_failed_delete-task ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc01_task
      FAILED DATA(ls_failed_commit3)
      REPORTED DATA(ls_reported_commit3).

    " ---- READ: verify delete ----
    READ ENTITIES OF zi_rc01_task
      ENTITY Task
      FIELDS ( task_id )
      WITH VALUE #( ( %key-task_id = lv_id ) )
      RESULT DATA(lt_read3).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_read3 ) exp = 0 ).

  ENDMETHOD.

  METHOD create_invalid_status.

    DATA(lv_id) = 'RC02TEST02'.

    " ---- CREATE with an invalid status value ----
    MODIFY ENTITIES OF zi_rc01_task
      ENTITY Task
      CREATE FIELDS ( task_id description status priority due_date )
        WITH VALUE #( ( %cid = 'C2'
                         task_id = lv_id
                         description = 'Invalid status test'
                         status = 'X'
                         priority = 'M'
                         due_date = '20261231' ) )
      FAILED DATA(ls_failed_create)
      REPORTED DATA(ls_reported_create).

    cl_abap_unit_assert=>assert_initial( ls_failed_create-task ).

    " ---- COMMIT: Validation should reject it here ----
    COMMIT ENTITIES
      RESPONSE OF zi_rc01_task
      FAILED DATA(ls_failed_commit)
      REPORTED DATA(ls_reported_commit).

    cl_abap_unit_assert=>assert_not_initial( ls_failed_commit-task ).

    " ---- 官方文件 ABENBDL_VALIDATIONS／ABAPROLLBACK_ENTITIES 明講：
    " COMMIT ENTITIES 失敗後 Transactional Buffer 不會自動清空，
    " 直接 READ ENTITIES 還是會讀到緩衝區裡的「失敗」資料，
    " 必須明確呼叫 ROLLBACK ENTITIES 才會清掉緩衝區、恢復可操作狀態 ----
    ROLLBACK ENTITIES.

    " ---- READ: 緩衝區清空後，資料庫應該完全沒有這筆被拒絕的資料 ----
    READ ENTITIES OF zi_rc01_task
      ENTITY Task
      FIELDS ( task_id )
      WITH VALUE #( ( %key-task_id = lv_id ) )
      RESULT DATA(lt_read).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_read ) exp = 0 ).

  ENDMETHOD.

  METHOD execute_mark_done.

    DATA(lv_id) = 'RC02TEST03'.

    " ---- CREATE ----
    MODIFY ENTITIES OF zi_rc01_task
      ENTITY Task
      CREATE FIELDS ( task_id description status priority due_date )
        WITH VALUE #( ( %cid = 'C3'
                         task_id = lv_id
                         description = 'Action test task'
                         status = 'O'
                         priority = 'M'
                         due_date = '20261231' ) )
      FAILED DATA(ls_failed_create)
      REPORTED DATA(ls_reported_create).

    cl_abap_unit_assert=>assert_initial( ls_failed_create-task ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc01_task
      FAILED DATA(ls_failed_commit1)
      REPORTED DATA(ls_reported_commit1).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit1-task ).

    " ---- EXECUTE markDone ----
    MODIFY ENTITIES OF zi_rc01_task
      ENTITY Task
      EXECUTE markDone
        FROM VALUE #( ( %key-task_id = lv_id ) )
      RESULT DATA(ls_result)
      FAILED DATA(ls_failed_action)
      REPORTED DATA(ls_reported_action).

    cl_abap_unit_assert=>assert_initial( ls_failed_action-task ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc01_task
      FAILED DATA(ls_failed_commit2)
      REPORTED DATA(ls_reported_commit2).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit2-task ).

    " ---- 驗證 RESULT：Action 呼叫端直接回傳表格，內容包在 %param 底下 ----
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result[ 1 ]-%param-status exp = 'D' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result[ 1 ]-%param-description
                                         exp = 'Action test task' ).

    " ---- READ：驗證真的持久化到資料庫，不是只有 RESULT 好看 ----
    READ ENTITIES OF zi_rc01_task
      ENTITY Task
      FIELDS ( status )
      WITH VALUE #( ( %key-task_id = lv_id ) )
      RESULT DATA(lt_read).

    cl_abap_unit_assert=>assert_equals( act = lt_read[ 1 ]-status exp = 'D' ).

  ENDMETHOD.

ENDCLASS.
