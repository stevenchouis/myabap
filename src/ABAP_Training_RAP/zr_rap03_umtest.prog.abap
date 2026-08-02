REPORT zr_rap03_umtest.

WRITE: / 'before EML'.

DELETE FROM zrap03_umtest WHERE id = 'UM0001'.
COMMIT WORK.

MODIFY ENTITIES OF zi_rap03_umtest
  ENTITY Test
    CREATE FIELDS ( id descr )
    WITH VALUE #( ( %cid = 'C1' id = 'UM0001' descr = 'Unmanaged Test' ) )
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).

WRITE: / 'after EML, failed is initial:', xsdbool( ls_failed-test IS INITIAL ).

COMMIT ENTITIES.

WRITE: / 'after commit entities'.

SELECT SINGLE id, descr FROM zrap03_umtest WHERE id = 'UM0001' INTO @DATA(ls_check).
IF sy-subrc = 0.
  WRITE: / 'DB check OK, descr =', ls_check-descr.
ELSE.
  WRITE: / 'DB check FAILED, no record found'.
ENDIF.
