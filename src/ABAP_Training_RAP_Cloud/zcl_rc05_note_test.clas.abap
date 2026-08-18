CLASS zcl_rc05_note_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC

  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS setup.
    METHODS create_draft_and_activate FOR TESTING.
    METHODS edit_and_discard FOR TESTING.

ENDCLASS.


CLASS zcl_rc05_note_test IMPLEMENTATION.

  METHOD setup.

    " 清掉可能殘留的 Draft（Discard，找不到殘留也不會影響後續，這裡不斷言）
    MODIFY ENTITIES OF zi_rc05_note
      ENTITY Note
      EXECUTE Discard
        FROM VALUE #( ( %key-note_id = 'RC05TEST01' )
                       ( %key-note_id = 'RC05TEST02' ) )
      FAILED   DATA(ls_failed_discard)
      REPORTED DATA(ls_reported_discard).

    COMMIT ENTITIES
      RESPONSE OF zi_rc05_note
      FAILED   DATA(ls_failed_commit1)
      REPORTED DATA(ls_reported_commit1).

    " 清掉可能殘留的 Active 資料
    MODIFY ENTITIES OF zi_rc05_note
      ENTITY Note
      DELETE
        FROM VALUE #( ( %key-note_id = 'RC05TEST01' )
                       ( %key-note_id = 'RC05TEST02' ) )
      FAILED   DATA(ls_failed_delete)
      REPORTED DATA(ls_reported_delete).

    COMMIT ENTITIES
      RESPONSE OF zi_rc05_note
      FAILED   DATA(ls_failed_commit2)
      REPORTED DATA(ls_reported_commit2).

  ENDMETHOD.

  METHOD create_draft_and_activate.

    DATA(lv_id) = 'RC05TEST01'.

    " ---- CREATE 一筆 Draft 實例（%is_draft = mk-on）----
    MODIFY ENTITIES OF zi_rc05_note
      ENTITY Note
      CREATE FROM
        VALUE #( ( %cid = 'C1'
                   %is_draft = if_abap_behv=>mk-on
                   %control-note_id = if_abap_behv=>mk-on
                   note_id          = lv_id
                   %control-title   = if_abap_behv=>mk-on
                   title            = 'Draft Test Note'
                   %control-content = if_abap_behv=>mk-on
                   content          = 'Initial content' ) )
      FAILED   DATA(ls_failed_create)
      REPORTED DATA(ls_reported_create).

    cl_abap_unit_assert=>assert_initial( ls_failed_create-note ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc05_note
      FAILED   DATA(ls_failed_commit1)
      REPORTED DATA(ls_reported_commit1).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit1-note ).

    " ---- 驗證：草稿只存在 Draft Table，Active Table 完全沒有 ----
    SELECT SINGLE note_id FROM zrc05_note_d WHERE note_id = @lv_id INTO @DATA(lv_draft_id).
    cl_abap_unit_assert=>assert_equals( act = lv_draft_id exp = lv_id ).

    SELECT SINGLE note_id FROM zrc05_note WHERE note_id = @lv_id INTO @DATA(lv_active_id).
    cl_abap_unit_assert=>assert_initial( lv_active_id ).

    " ---- EXECUTE Activate ----
    MODIFY ENTITIES OF zi_rc05_note
      ENTITY Note
      EXECUTE Activate
        AUTO FILL CID
        WITH VALUE #( ( %key-note_id = lv_id ) )
      FAILED   DATA(ls_failed_activate)
      REPORTED DATA(ls_reported_activate).

    cl_abap_unit_assert=>assert_initial( ls_failed_activate-note ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc05_note
      FAILED   DATA(ls_failed_commit2)
      REPORTED DATA(ls_reported_commit2).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit2-note ).

    " ---- 驗證：Activate 之後，Draft Table 清空，Active Table 有資料 ----
    CLEAR lv_draft_id.
    SELECT SINGLE note_id FROM zrc05_note_d WHERE note_id = @lv_id INTO @lv_draft_id.
    cl_abap_unit_assert=>assert_initial( lv_draft_id ).

    SELECT SINGLE title FROM zrc05_note WHERE note_id = @lv_id INTO @DATA(lv_title).
    cl_abap_unit_assert=>assert_equals( act = lv_title exp = 'Draft Test Note' ).

  ENDMETHOD.

  METHOD edit_and_discard.

    DATA(lv_id) = 'RC05TEST02'.

    " ---- CREATE 一筆正常的 Active 資料（%is_draft = mk-off，不經過 Draft）----
    MODIFY ENTITIES OF zi_rc05_note
      ENTITY Note
      CREATE FROM
        VALUE #( ( %cid = 'C2'
                   %is_draft = if_abap_behv=>mk-off
                   %control-note_id = if_abap_behv=>mk-on
                   note_id          = lv_id
                   %control-title   = if_abap_behv=>mk-on
                   title            = 'Original Title'
                   %control-content = if_abap_behv=>mk-on
                   content          = 'Original content' ) )
      FAILED   DATA(ls_failed_create)
      REPORTED DATA(ls_reported_create).

    cl_abap_unit_assert=>assert_initial( ls_failed_create-note ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc05_note
      FAILED   DATA(ls_failed_commit1)
      REPORTED DATA(ls_reported_commit1).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit1-note ).

    " ---- EXECUTE Edit：把 Active 複製一份到 Draft Table ----
    MODIFY ENTITIES OF zi_rc05_note
      ENTITY Note
      EXECUTE Edit
        AUTO FILL CID
        WITH VALUE #( ( %key-note_id = lv_id
                         %param-preserve_changes = 'X' ) )
      FAILED   DATA(ls_failed_edit)
      REPORTED DATA(ls_reported_edit).

    cl_abap_unit_assert=>assert_initial( ls_failed_edit-note ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc05_note
      FAILED   DATA(ls_failed_commit2)
      REPORTED DATA(ls_reported_commit2).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit2-note ).

    " ---- 驗證：Draft Table 現在有一份複本 ----
    SELECT SINGLE note_id FROM zrc05_note_d WHERE note_id = @lv_id INTO @DATA(lv_draft_id).
    cl_abap_unit_assert=>assert_equals( act = lv_draft_id exp = lv_id ).

    " ---- EXECUTE Discard：丟棄這份 Draft 複本 ----
    MODIFY ENTITIES OF zi_rc05_note
      ENTITY Note
      EXECUTE Discard
        FROM VALUE #( ( %key-note_id = lv_id ) )
      FAILED   DATA(ls_failed_discard)
      REPORTED DATA(ls_reported_discard).

    cl_abap_unit_assert=>assert_initial( ls_failed_discard-note ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc05_note
      FAILED   DATA(ls_failed_commit3)
      REPORTED DATA(ls_reported_commit3).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit3-note ).

    " ---- 驗證：Draft Table 清空，Active Table 的原始資料完全沒被動到 ----
    CLEAR lv_draft_id.
    SELECT SINGLE note_id FROM zrc05_note_d WHERE note_id = @lv_id INTO @lv_draft_id.
    cl_abap_unit_assert=>assert_initial( lv_draft_id ).

    SELECT SINGLE title FROM zrc05_note WHERE note_id = @lv_id INTO @DATA(lv_title).
    cl_abap_unit_assert=>assert_equals( act = lv_title exp = 'Original Title' ).

  ENDMETHOD.

ENDCLASS.
