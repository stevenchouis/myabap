REPORT zr_rap07_actdemo.

DELETE FROM zrap03_umtest WHERE id = 'ACT_TEST01'.

MODIFY ENTITIES OF zi_rap03_umtest
  ENTITY Test
    CREATE FIELDS ( id descr )
    WITH VALUE #( ( %cid = 'C1' id = 'ACT_TEST01' descr = 'Action Test' ) )
  FAILED   DATA(ls_failed_create)
  REPORTED DATA(ls_reported_create).

COMMIT ENTITIES.

SELECT SINGLE created_at, created_by FROM zrap03_umtest
  WHERE id = 'ACT_TEST01' INTO @DATA(ls_before).

WRITE: / 'before touch, created_at:', ls_before-created_at.

WAIT UP TO 1 SECONDS.

MODIFY ENTITIES OF zi_rap03_umtest
  ENTITY Test
    EXECUTE touch
    FROM VALUE #( ( %key-id = 'ACT_TEST01' ) )
  RESULT   DATA(ls_result)
  FAILED   DATA(ls_failed_action)
  REPORTED DATA(ls_reported_action).

WRITE: / 'after EXECUTE touch, failed count:', lines( ls_failed_action-test ).

COMMIT ENTITIES.

SELECT SINGLE created_at, created_by FROM zrap03_umtest
  WHERE id = 'ACT_TEST01' INTO @DATA(ls_after).

WRITE: / 'after touch, created_at:', ls_after-created_at.

IF ls_after-created_at > ls_before-created_at.
  WRITE: / 'Action really re-stamped created_at: YES'.
ELSE.
  WRITE: / 'Action really re-stamped created_at: NO'.
ENDIF.

WRITE: / 'result table lines:', lines( ls_result ).
LOOP AT ls_result INTO DATA(ls_res).
  WRITE: / 'result descr:', ls_res-%param-descr.
ENDLOOP.
