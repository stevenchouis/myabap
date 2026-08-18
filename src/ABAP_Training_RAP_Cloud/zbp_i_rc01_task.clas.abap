*----------------------------------------------------------------------*
* Global Class（Eclipse 類別編輯器主要區域）
*----------------------------------------------------------------------*
CLASS zbp_i_rc01_task DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF zi_rc01_task.
ENDCLASS.

CLASS zbp_i_rc01_task IMPLEMENTATION.
ENDCLASS.

*----------------------------------------------------------------------*
* Local Types（Eclipse 類別編輯器下方「Local Types」分頁）
* 這段內容含 IMPORTING ... FOR ... 語法，abap-remote-fs MCP 工具的
* replace_string_in_abap_object 存檔會失敗，本課由使用者直接在 Eclipse 貼上，
* Claude 事後用 get_abap_diagnostics／run_unit_tests 驗證行為正確。
*----------------------------------------------------------------------*
CLASS lhc_task DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setCreationInfo FOR DETERMINE ON SAVE
      IMPORTING keys FOR Task~setCreationInfo.
    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR Task~validateStatus.
    METHODS markDone FOR MODIFY
      IMPORTING keys FOR ACTION Task~markDone RESULT result.
ENDCLASS.

CLASS lhc_task IMPLEMENTATION.

  METHOD setCreationInfo.
    MODIFY ENTITIES OF zi_rc01_task IN LOCAL MODE
      ENTITY Task
      UPDATE FIELDS ( created_at created_by )
      WITH VALUE #( FOR key IN keys
                     ( %key = key-%key
                       created_at   = utclong_current( )
                       created_by   = cl_abap_context_info=>get_user_technical_name( ) ) ).
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITIES OF zi_rc01_task IN LOCAL MODE
      ENTITY Task
      FIELDS ( status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_task).

    LOOP AT lt_task INTO DATA(ls_task) WHERE status <> 'O' AND status <> 'D'.
      APPEND VALUE #( %key = ls_task-%key ) TO failed-task.
      APPEND VALUE #( %key = ls_task-%key
                       %msg = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = |Status { ls_task-status } is not a valid value| ) )
        TO reported-task.
    ENDLOOP.
  ENDMETHOD.

  METHOD markDone.
    MODIFY ENTITIES OF zi_rc01_task IN LOCAL MODE
      ENTITY Task
      UPDATE FIELDS ( status )
      WITH VALUE #( FOR key IN keys
                     ( %key = key-%key
                       status = 'D' ) )
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).

    failed   = CORRESPONDING #( DEEP lt_failed ).
    reported = CORRESPONDING #( DEEP lt_reported ).

    READ ENTITIES OF zi_rc01_task IN LOCAL MODE
      ENTITY Task
      FIELDS ( task_id description status priority due_date created_at created_by )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_task).

    result = VALUE #( FOR ls_task IN lt_task
                       ( %key = ls_task-%key %param = ls_task ) ).
  ENDMETHOD.

ENDCLASS.
