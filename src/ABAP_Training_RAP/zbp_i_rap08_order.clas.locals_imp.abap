CLASS lhc_header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS lock FOR LOCK
      IMPORTING it_lock FOR LOCK Header.

    METHODS create FOR MODIFY
      IMPORTING it_create FOR CREATE Header.

    METHODS create_item FOR MODIFY
      IMPORTING it_create FOR CREATE Header\_Item.

    METHODS update FOR MODIFY
      IMPORTING it_update FOR UPDATE Header.

    METHODS delete FOR MODIFY
      IMPORTING it_delete FOR DELETE Header.

    METHODS confirmOrder FOR MODIFY
      IMPORTING keys FOR ACTION Header~confirmOrder RESULT result.

    METHODS addItem FOR MODIFY
      IMPORTING keys FOR ACTION Header~addItem RESULT result.

    METHODS read_header FOR READ
      IMPORTING it_read FOR READ Header RESULT et_result.

    METHODS get_instance_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR Header RESULT result.
ENDCLASS.

CLASS lhc_header IMPLEMENTATION.

  METHOD lock.
  ENDMETHOD.

  METHOD create.
    LOOP AT it_create INTO DATA(ls_create).
      INSERT zrap08_order FROM @( VALUE #(
        client      = sy-mandt
        order_id    = ls_create-order_id
        description = ls_create-description
        status      = 'N'
        created_at  = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) )
        created_by  = sy-uname ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD create_item.
    LOOP AT it_create INTO DATA(ls_create).
      LOOP AT ls_create-%target INTO DATA(ls_target).
        IF ls_target-quantity <= 0.
          APPEND VALUE #( %cid = ls_target-%cid ) TO failed-item.
          APPEND VALUE #( %cid = ls_target-%cid
                           %msg = new_message_with_text(
                             severity = if_abap_behv_message=>severity-error
                             text     = 'Quantity must be greater than zero' ) )
            TO reported-item.
          CONTINUE.
        ENDIF.

        INSERT zrap08_order_i FROM @( VALUE #(
          client        = sy-mandt
          order_id      = ls_create-%key-order_id
          item_id       = ls_target-item_id
          material_desc = ls_target-material_desc
          quantity      = ls_target-quantity ) ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    LOOP AT it_update INTO DATA(ls_update).
      UPDATE zrap08_order SET description = @ls_update-description
        WHERE order_id = @ls_update-%key-order_id.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT it_delete INTO DATA(ls_delete).
      " Composition 的存在依賴關係：刪 Header 前要先刪掉所有底下的 Item，Unmanaged 不會自動連帶處理
      DELETE FROM zrap08_order_i WHERE order_id = @ls_delete-%key-order_id.
      DELETE FROM zrap08_order   WHERE order_id = @ls_delete-%key-order_id.
    ENDLOOP.
  ENDMETHOD.

  METHOD confirmOrder.
    LOOP AT keys INTO DATA(ls_key).
      SELECT COUNT(*) FROM zrap08_order_i WHERE order_id = @ls_key-%key-order_id INTO @DATA(lv_count).
      IF lv_count = 0.
        APPEND VALUE #( %key = ls_key-%key ) TO failed-header.
        APPEND VALUE #( %key = ls_key-%key
                         %msg = new_message_with_text(
                           severity = if_abap_behv_message=>severity-error
                           text     = 'Cannot confirm an order with no items' ) )
          TO reported-header.
        CONTINUE.
      ENDIF.

      UPDATE zrap08_order SET status = 'C' WHERE order_id = @ls_key-%key-order_id.
    ENDLOOP.

    LOOP AT keys INTO ls_key.
      SELECT SINGLE order_id, description, status, created_at, created_by
        FROM zrap08_order WHERE order_id = @ls_key-%key-order_id INTO @DATA(ls_data).
      IF sy-subrc = 0.
        APPEND VALUE #(
          %key   = ls_key-%key
          %param = ls_data ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD addItem.
    LOOP AT keys INTO DATA(ls_key).
      IF ls_key-%param-quantity <= 0.
        APPEND VALUE #( %key = ls_key-%key ) TO failed-header.
        APPEND VALUE #( %key = ls_key-%key
                         %msg = new_message_with_text(
                           severity = if_abap_behv_message=>severity-error
                           text     = 'Quantity must be greater than zero' ) )
          TO reported-header.
        CONTINUE.
      ENDIF.

      INSERT zrap08_order_i FROM @( VALUE #(
        client        = sy-mandt
        order_id      = ls_key-%key-order_id
        item_id       = ls_key-%param-item_id
        material_desc = ls_key-%param-material_desc
        quantity      = ls_key-%param-quantity ) ).
    ENDLOOP.

    LOOP AT keys INTO ls_key.
      SELECT SINGLE order_id, description, status, created_at, created_by
        FROM zrap08_order WHERE order_id = @ls_key-%key-order_id INTO @DATA(ls_data).
      IF sy-subrc = 0.
        APPEND VALUE #(
          %key   = ls_key-%key
          %param = ls_data ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_header.
    LOOP AT it_read INTO DATA(ls_key).
      SELECT SINGLE order_id, description, status, created_at, created_by
        FROM zrap08_order WHERE order_id = @ls_key-order_id INTO @DATA(ls_data).
      IF sy-subrc = 0.
        APPEND VALUE #(
          %key        = ls_key-%key
          order_id    = ls_data-order_id
          description = ls_data-description
          status      = ls_data-status
          created_at  = ls_data-created_at
          created_by  = ls_data-created_by ) TO et_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    result = VALUE #( FOR ls_key IN keys
      ( %key            = ls_key-%key
        %field-order_id = if_abap_behv=>fc-f-read_only ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read_item FOR READ
      IMPORTING it_read FOR READ Item RESULT et_result.

    METHODS update FOR MODIFY
      IMPORTING it_update FOR UPDATE Item.

    METHODS delete FOR MODIFY
      IMPORTING it_delete FOR DELETE Item.

    METHODS get_instance_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR Item RESULT result.
ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD read_item.
    LOOP AT it_read INTO DATA(ls_key).
      SELECT SINGLE order_id, item_id, material_desc, quantity
        FROM zrap08_order_i
        WHERE order_id = @ls_key-order_id AND item_id = @ls_key-item_id
        INTO @DATA(ls_data).
      IF sy-subrc = 0.
        APPEND VALUE #(
          %key          = ls_key-%key
          order_id      = ls_data-order_id
          item_id       = ls_data-item_id
          material_desc = ls_data-material_desc
          quantity      = ls_data-quantity ) TO et_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    LOOP AT it_update INTO DATA(ls_update).
      UPDATE zrap08_order_i
        SET material_desc = @ls_update-material_desc,
            quantity      = @ls_update-quantity
        WHERE order_id = @ls_update-%key-order_id
          AND item_id  = @ls_update-%key-item_id.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT it_delete INTO DATA(ls_delete).
      DELETE FROM zrap08_order_i
        WHERE order_id = @ls_delete-%key-order_id
          AND item_id  = @ls_delete-%key-item_id.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    result = VALUE #( FOR ls_key IN keys
      ( %key           = ls_key-%key
        %field-item_id = if_abap_behv=>fc-f-read_only ) ).
  ENDMETHOD.

ENDCLASS.
