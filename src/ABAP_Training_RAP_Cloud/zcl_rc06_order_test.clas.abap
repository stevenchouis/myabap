CLASS zcl_rc06_order_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC

  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS setup.
    METHODS create_by_association FOR TESTING.
    METHODS delete_cascades_to_items FOR TESTING.

ENDCLASS.


CLASS zcl_rc06_order_test IMPLEMENTATION.

  METHOD setup.

    MODIFY ENTITIES OF zi_rc06_order
      ENTITY Header
      DELETE
        FROM VALUE #( ( %key-order_id = 'RC06TEST01' )
                       ( %key-order_id = 'RC06TEST02' ) )
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    COMMIT ENTITIES
      RESPONSE OF zi_rc06_order
      FAILED   DATA(ls_failed_commit)
      REPORTED DATA(ls_reported_commit).

  ENDMETHOD.

  METHOD create_by_association.

    DATA(lv_order_id) = 'RC06TEST01'.

    " ---- 一次 EML 呼叫同時建立 Header 跟兩筆 Item（Create-by-Association）----
    MODIFY ENTITIES OF zi_rc06_order
      ENTITY Header
        CREATE FIELDS ( order_id description )
        WITH VALUE #( ( %cid = 'H1' order_id = lv_order_id description = 'Demo Order' ) )

      ENTITY Header
        CREATE BY \_Item
          FIELDS ( item_id material_desc quantity )
          WITH VALUE #( ( %cid_ref = 'H1'
                           %target = VALUE #(
                             ( %cid = 'I1' item_id = '0010' material_desc = 'Widget A' quantity = '5' )
                             ( %cid = 'I2' item_id = '0020' material_desc = 'Widget B' quantity = '3' ) ) ) )

      FAILED   DATA(ls_failed_create)
      REPORTED DATA(ls_reported_create).

    IF ls_reported_create-header IS NOT INITIAL.
      cl_abap_unit_assert=>fail( |HEADER: { ls_reported_create-header[ 1 ]-%msg->if_message~get_text( ) }| ).
    ENDIF.
    IF ls_reported_create-item IS NOT INITIAL.
      cl_abap_unit_assert=>fail( |ITEM: { ls_reported_create-item[ 1 ]-%msg->if_message~get_text( ) }| ).
    ENDIF.

    cl_abap_unit_assert=>assert_initial( ls_failed_create-header ).
    cl_abap_unit_assert=>assert_initial( ls_failed_create-item ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc06_order
      FAILED   DATA(ls_failed_commit)
      REPORTED DATA(ls_reported_commit).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit-header ).

    " ---- READ 驗證 Header ----
    READ ENTITIES OF zi_rc06_order
      ENTITY Header
      FIELDS ( description )
      WITH VALUE #( ( %key-order_id = lv_order_id ) )
      RESULT DATA(lt_header).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_header ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_header[ 1 ]-description exp = 'Demo Order' ).

    " ---- READ 驗證兩筆 Item 都真的建立成功 ----
    READ ENTITIES OF zi_rc06_order
      ENTITY Item
      FIELDS ( material_desc quantity )
      WITH VALUE #( ( %key-order_id = lv_order_id %key-item_id = '0010' )
                     ( %key-order_id = lv_order_id %key-item_id = '0020' ) )
      RESULT DATA(lt_item).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_item ) exp = 2 ).

    SORT lt_item BY item_id.
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 1 ]-material_desc exp = 'Widget A' ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 2 ]-material_desc exp = 'Widget B' ).

  ENDMETHOD.

  METHOD delete_cascades_to_items.

    DATA(lv_order_id) = 'RC06TEST02'.

    " ---- CREATE Header + 1 筆 Item ----
    MODIFY ENTITIES OF zi_rc06_order
      ENTITY Header
        CREATE FIELDS ( order_id description )
        WITH VALUE #( ( %cid = 'H2' order_id = lv_order_id description = 'Delete Test Order' ) )

      ENTITY Header
        CREATE BY \_Item
          FIELDS ( item_id material_desc quantity )
          WITH VALUE #( ( %cid_ref = 'H2'
                           %target = VALUE #(
                             ( %cid = 'I3' item_id = '0010' material_desc = 'Gadget' quantity = '1' ) ) ) )

      FAILED   DATA(ls_failed_create)
      REPORTED DATA(ls_reported_create).

    cl_abap_unit_assert=>assert_initial( ls_failed_create-header ).
    cl_abap_unit_assert=>assert_initial( ls_failed_create-item ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc06_order
      FAILED   DATA(ls_failed_commit1)
      REPORTED DATA(ls_reported_commit1).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit1-header ).

    " ---- 直接下 SQL 確認 Item 真的存在 ----
    SELECT SINGLE order_id FROM zrc06_order_i WHERE order_id = @lv_order_id INTO @DATA(lv_item_exists).
    cl_abap_unit_assert=>assert_equals( act = lv_item_exists exp = lv_order_id ).

    " ---- DELETE Header ----
    MODIFY ENTITIES OF zi_rc06_order
      ENTITY Header
      DELETE
        FROM VALUE #( ( %key-order_id = lv_order_id ) )
      FAILED   DATA(ls_failed_delete)
      REPORTED DATA(ls_reported_delete).

    cl_abap_unit_assert=>assert_initial( ls_failed_delete-header ).

    COMMIT ENTITIES
      RESPONSE OF zi_rc06_order
      FAILED   DATA(ls_failed_commit2)
      REPORTED DATA(ls_reported_commit2).

    cl_abap_unit_assert=>assert_initial( ls_failed_commit2-header ).

    " ---- 驗證 Header 跟 Item 都真的沒了：Composition 的擁有關係，
    " 刪除 Header 應該連帶自動刪除底下所有 Item，不需要自己寫 Cascading Delete 邏輯 ----
    SELECT SINGLE order_id FROM zrc06_order WHERE order_id = @lv_order_id INTO @DATA(lv_header_exists).
    cl_abap_unit_assert=>assert_initial( lv_header_exists ).

    CLEAR lv_item_exists.
    SELECT SINGLE order_id FROM zrc06_order_i WHERE order_id = @lv_order_id INTO @lv_item_exists.
    cl_abap_unit_assert=>assert_initial( lv_item_exists ).

  ENDMETHOD.

ENDCLASS.
