REPORT zr_rap05_detdemo.

DATA(lv_test_id) = 'DET_TEST01'.

DELETE FROM zrap03_umtest WHERE id = @lv_test_id.

WRITE: / 'before EML'.

MODIFY ENTITIES OF zi_rap03_umtest
  ENTITY Test
    CREATE FIELDS ( id descr )
    WITH VALUE #( ( %cid = 'C1' id = lv_test_id descr = 'RAP05 Determination Demo' ) )
  FAILED   DATA(ls_failed)
  REPORTED DATA(ls_reported).

WRITE: / 'after EML, failed is initial:', xsdbool( ls_failed IS INITIAL ).

COMMIT ENTITIES.

WRITE: / 'after commit entities'.

SELECT SINGLE id, descr, created_at, created_by
  FROM zrap03_umtest
  WHERE id = @lv_test_id
  INTO @DATA(ls_check).

IF sy-subrc = 0.
  WRITE: / 'DB check OK, id =', ls_check-id.
  WRITE: / 'descr =', ls_check-descr.
  IF ls_check-created_at IS NOT INITIAL.
    WRITE: / 'created_at auto-filled: YES'.
  ELSE.
    WRITE: / 'created_at auto-filled: NO (still initial!)'.
  ENDIF.
  IF ls_check-created_by = sy-uname.
    WRITE: / 'created_by auto-filled correctly:', ls_check-created_by.
  ELSE.
    WRITE: / 'created_by unexpected value:', ls_check-created_by.
  ENDIF.
ELSE.
  WRITE: / 'DB check FAILED: row not found'.
ENDIF.
