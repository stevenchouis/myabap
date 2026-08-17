REPORT zr_rap09_demo.

DELETE FROM zrap08_order_i WHERE order_id IN ('R901', 'R902', 'R903', 'R904').
DELETE FROM zrap08_order   WHERE order_id IN ('R901', 'R902', 'R903', 'R904').
COMMIT WORK.

WRITE: / '=== Scenario 1: confirm order with 0 items -> should FAIL ==='.

MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    CREATE FIELDS ( description )
    WITH VALUE #( ( %cid = 'H1' order_id = 'R901' description = 'No Items Order' ) )
  FAILED   DATA(ls_failed1)
  REPORTED DATA(ls_reported1).
COMMIT ENTITIES.

MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    EXECUTE confirmOrder
      FROM VALUE #( ( %key-order_id = 'R901' ) )
  FAILED   DATA(ls_failed1b)
  REPORTED DATA(ls_reported1b).
COMMIT ENTITIES.

WRITE: / 'confirm R901 failed:', xsdbool( ls_failed1b-header IS NOT INITIAL ).
LOOP AT ls_reported1b-header INTO DATA(ls_msg1).
  WRITE: / '  message:', ls_msg1-%msg->if_message~get_text( ).
ENDLOOP.

WRITE: / '=== Scenario 2: confirm order with 1 valid item -> should SUCCEED ==='.

MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    CREATE FIELDS ( description )
    WITH VALUE #( ( %cid = 'H2' order_id = 'R902' description = 'Valid Order' ) )

  ENTITY Header
    CREATE BY \_Item
      FIELDS ( item_id material_desc quantity )
      WITH VALUE #( ( %key-order_id = 'R902'
                       %target = VALUE #(
                         ( %cid = 'I1' item_id = '0010' material_desc = 'Widget' quantity = '5' ) ) ) )
  FAILED   DATA(ls_failed2)
  REPORTED DATA(ls_reported2).
COMMIT ENTITIES.

WRITE: / 'create R902+item failed:', xsdbool( ls_failed2-header IS NOT INITIAL OR ls_failed2-item IS NOT INITIAL ).

MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    EXECUTE confirmOrder
      FROM VALUE #( ( %key-order_id = 'R902' ) )
      RESULT DATA(lt_result2)
  FAILED   DATA(ls_failed2b)
  REPORTED DATA(ls_reported2b).
COMMIT ENTITIES.

WRITE: / 'confirm R902 failed:', xsdbool( ls_failed2b-header IS NOT INITIAL ).
LOOP AT lt_result2 INTO DATA(ls_res2).
  WRITE: / '  status after confirm:', ls_res2-%param-status.
ENDLOOP.

SELECT SINGLE status FROM zrap08_order WHERE order_id = 'R902' INTO @DATA(lv_db_status).
WRITE: / '  DB status:', lv_db_status.

WRITE: / '=== Scenario 3: create item with quantity <= 0 -> should FAIL at create ==='.

MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    CREATE FIELDS ( description )
    WITH VALUE #( ( %cid = 'H3' order_id = 'R903' description = 'Bad Item Order' ) )

  ENTITY Header
    CREATE BY \_Item
      FIELDS ( item_id material_desc quantity )
      WITH VALUE #( ( %key-order_id = 'R903'
                       %target = VALUE #(
                         ( %cid = 'I1' item_id = '0010' material_desc = 'Bad Widget' quantity = '-1' ) ) ) )
  FAILED   DATA(ls_failed3)
  REPORTED DATA(ls_reported3).
COMMIT ENTITIES.

WRITE: / 'create R903 header failed:', xsdbool( ls_failed3-header IS NOT INITIAL ).
WRITE: / 'create R903 item failed:', xsdbool( ls_failed3-item IS NOT INITIAL ).
LOOP AT ls_reported3-item INTO DATA(ls_msg3).
  WRITE: / '  item message:', ls_msg3-%msg->if_message~get_text( ).
ENDLOOP.

SELECT COUNT(*) FROM zrap08_order_i WHERE order_id = 'R903' INTO @DATA(lv_item_count3).
WRITE: / '  item rows for R903 in DB:', lv_item_count3.

WRITE: / '=== Scenario 4: addItem on an existing order, then confirm ==='.

MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    CREATE FIELDS ( description )
    WITH VALUE #( ( %cid = 'H4' order_id = 'R904' description = 'AddItem Test Order' ) )
  FAILED   DATA(ls_failed4)
  REPORTED DATA(ls_reported4).
COMMIT ENTITIES.

WRITE: / 'create R904 failed:', xsdbool( ls_failed4-header IS NOT INITIAL ).

" 先試不合法的 quantity，應該被拒絕
MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    EXECUTE addItem
      FROM VALUE #( ( %key-order_id = 'R904'
                       %param-item_id = '0010'
                       %param-material_desc = 'Bad Widget'
                       %param-quantity = '-1' ) )
  FAILED   DATA(ls_failed4b)
  REPORTED DATA(ls_reported4b).
COMMIT ENTITIES.

WRITE: / 'addItem (bad quantity) failed:', xsdbool( ls_failed4b-header IS NOT INITIAL ).
LOOP AT ls_reported4b-header INTO DATA(ls_msg4b).
  WRITE: / '  message:', ls_msg4b-%msg->if_message~get_text( ).
ENDLOOP.

SELECT COUNT(*) FROM zrap08_order_i WHERE order_id = 'R904' INTO @DATA(lv_count_after_bad).
WRITE: / '  item rows for R904 after bad addItem:', lv_count_after_bad.

" 再試合法的 quantity，應該成功
MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    EXECUTE addItem
      FROM VALUE #( ( %key-order_id = 'R904'
                       %param-item_id = '0010'
                       %param-material_desc = 'Good Widget'
                       %param-quantity = '3' ) )
      RESULT DATA(lt_result4)
  FAILED   DATA(ls_failed4c)
  REPORTED DATA(ls_reported4c).
COMMIT ENTITIES.

WRITE: / 'addItem (valid) failed:', xsdbool( ls_failed4c-header IS NOT INITIAL ).

SELECT COUNT(*) FROM zrap08_order_i WHERE order_id = 'R904' INTO @DATA(lv_count_after_good).
WRITE: / '  item rows for R904 after good addItem:', lv_count_after_good.

SELECT SINGLE material_desc, quantity FROM zrap08_order_i
  WHERE order_id = 'R904' AND item_id = '0010' INTO @DATA(ls_item_check).
WRITE: / '  item material_desc:', ls_item_check-material_desc, ' quantity:', ls_item_check-quantity.

" 現在應該可以成功 confirm 了
MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    EXECUTE confirmOrder
      FROM VALUE #( ( %key-order_id = 'R904' ) )
  FAILED   DATA(ls_failed4d)
  REPORTED DATA(ls_reported4d).
COMMIT ENTITIES.

WRITE: / 'confirm R904 (after addItem) failed:', xsdbool( ls_failed4d-header IS NOT INITIAL ).

SELECT SINGLE status FROM zrap08_order WHERE order_id = 'R904' INTO @DATA(lv_final_status).
WRITE: / '  final DB status:', lv_final_status.
