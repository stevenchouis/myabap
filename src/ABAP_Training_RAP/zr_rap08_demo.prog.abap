REPORT zr_rap08_demo.

" 先清掉這個測試專用 order_id 的舊資料，讓重跑冪等（只鎖定這個 demo 用的 ID，不動其他資料）
DELETE FROM zrap08_order_i WHERE order_id = 'ORD001'.
DELETE FROM zrap08_order   WHERE order_id = 'ORD001'.
COMMIT WORK.

MODIFY ENTITIES OF zi_rap08_order
  ENTITY Header
    CREATE FIELDS ( description )
    WITH VALUE #( ( %cid = 'H1' order_id = 'ORD001' description = 'Demo Order' ) )

  ENTITY Header
    CREATE BY \_Item
      FIELDS ( item_id material_desc quantity )
      WITH VALUE #( ( %key-order_id = 'ORD001'
                       %target = VALUE #(
                         ( %cid = 'I1' item_id = '0010' material_desc = 'Widget A' quantity = '5' )
                         ( %cid = 'I2' item_id = '0020' material_desc = 'Widget B' quantity = '3' ) ) ) )

  FAILED   DATA(ls_failed)
  REPORTED DATA(ls_reported).

IF ls_failed-header IS NOT INITIAL OR ls_failed-item IS NOT INITIAL.
  WRITE: / 'CREATE FAILED'.
ELSE.
  COMMIT ENTITIES.
  WRITE: / 'after commit entities'.
ENDIF.

READ ENTITIES OF zi_rap08_order
  ENTITY Header
    FIELDS ( order_id description )
    WITH VALUE #( ( order_id = 'ORD001' ) )
  RESULT DATA(lt_header).

LOOP AT lt_header INTO DATA(ls_header).
  WRITE: / 'header found:', ls_header-order_id, ls_header-description.
ENDLOOP.

READ ENTITIES OF zi_rap08_order
  ENTITY Item
    FIELDS ( order_id item_id material_desc quantity )
    WITH VALUE #( ( order_id = 'ORD001' item_id = '0010' )
                   ( order_id = 'ORD001' item_id = '0020' ) )
  RESULT DATA(lt_item).

WRITE: / 'item rows found:', lines( lt_item ).
LOOP AT lt_item INTO DATA(ls_item).
  WRITE: / ls_item-item_id, ls_item-material_desc, ls_item-quantity.
ENDLOOP.
