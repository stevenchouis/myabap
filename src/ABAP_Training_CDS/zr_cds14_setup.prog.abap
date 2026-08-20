REPORT zr_cds14_setup.

DELETE FROM ztcds14_orgunit WHERE orgunit_id LIKE 'Z%'.

INSERT ztcds14_orgunit FROM TABLE @( VALUE #(
  ( client = sy-mandt orgunit_id = 'ZROOT'    parent_id = ''       orgunit_name = 'CEO Office'       seq_number = '0010' )
  ( client = sy-mandt orgunit_id = 'ZSALES'   parent_id = 'ZROOT'  orgunit_name = 'Sales Division'   seq_number = '0010' )
  ( client = sy-mandt orgunit_id = 'ZOPS'     parent_id = 'ZROOT'  orgunit_name = 'Operations'       seq_number = '0020' )
  ( client = sy-mandt orgunit_id = 'ZSALESEU' parent_id = 'ZSALES' orgunit_name = 'Sales Europe'     seq_number = '0010' )
  ( client = sy-mandt orgunit_id = 'ZSALESUS' parent_id = 'ZSALES' orgunit_name = 'Sales US'         seq_number = '0020' )
  ( client = sy-mandt orgunit_id = 'ZOPSFLT'  parent_id = 'ZOPS'   orgunit_name = 'Flight Operations' seq_number = '0010' )
) ).

WRITE: / 'Inserted rows:', sy-dbcnt.

SELECT COUNT(*) FROM ztcds14_orgunit WHERE orgunit_id LIKE 'Z%' INTO @DATA(lv_count).
WRITE: / 'Total ZCDS14 test rows in table:', lv_count.
