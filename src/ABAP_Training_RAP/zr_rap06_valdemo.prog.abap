REPORT zr_rap06_valdemo.

DELETE FROM zrap03_umtest WHERE id = 'VAL_TEST01' OR id = 'VAL_TEST02'.

WRITE: / 'before EML'.

MODIFY ENTITIES OF zi_rap03_umtest
  ENTITY Test
    CREATE FIELDS ( id descr )
    WITH VALUE #(
      ( %cid = 'C1' id = 'VAL_TEST01' descr = 'Valid Row' )
      ( %cid = 'C2' id = 'VAL_TEST02' descr = '' ) )
  FAILED   DATA(ls_failed)
  REPORTED DATA(ls_reported).

WRITE: / 'after EML, failed count:', lines( ls_failed-test ).
LOOP AT ls_reported-test INTO DATA(ls_msg).
  WRITE: / 'reported message:', ls_msg-%msg->if_message~get_text( ).
ENDLOOP.

COMMIT ENTITIES.

WRITE: / 'after commit entities'.

SELECT id, descr FROM zrap03_umtest
  WHERE id = 'VAL_TEST01' OR id = 'VAL_TEST02'
  INTO TABLE @DATA(lt_check).

WRITE: / 'rows found in DB:', lines( lt_check ).
LOOP AT lt_check INTO DATA(ls_check).
  WRITE: / ls_check-id, ls_check-descr.
ENDLOOP.
