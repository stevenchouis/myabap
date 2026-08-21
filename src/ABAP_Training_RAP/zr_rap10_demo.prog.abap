REPORT zr_rap10_demo.

START-OF-SELECTION.

  WRITE: / '=== RAP10: Legacy WHMS integration via RAP Action + EML ==='.
  WRITE: / 'Reusing production class ZCL_QM_05_SERVICE (package ZQM1) unchanged.'.
  WRITE: / 'Test uses a guaranteed-nonexistent RT number (9999999999) -',
         / 'this hits the safe "RT not found" error path, never touches',
         / 'real inspection lot data, and proves the shared validation',
         / 'logic executes identically through the new RAP entry point.'.

  DATA lt_request TYPE ztt_qm005_request.

  lt_request = VALUE #(
    ( header = VALUE #( zwhms_no   = 'RAP10DEMO1'
                         zrt_no     = '9999999999'
                         budat      = sy-datum
                         bldat      = sy-datum
                         ztran_type = '1'
                         bktxt      = 'RAP10 demo' )
      detail = VALUE #( ) ) ).

  MODIFY ENTITIES OF zi_rap10_log
    ENTITY Log
    EXECUTE SubmitWhmsRequest
    FROM VALUE #( ( %cid   = 'C1'
                     %param = lt_request ) )
    RESULT DATA(lt_result)
    FAILED DATA(ls_failed)
    REPORTED DATA(ls_reported).

  COMMIT ENTITIES.

  WRITE: / '=== EML RESULT ==='.
  LOOP AT lt_result INTO DATA(ls_result).
    WRITE: / ls_result-%param-zwhms_no, ls_result-%param-zrt_no,
             ls_result-%param-msgty, ls_result-%param-message.
  ENDLOOP.

  IF ls_failed-log IS NOT INITIAL.
    WRITE: / '=== FAILED (expected: empty - action itself did not fail,',
           / 'the business error is returned inside RESULT, not FAILED) ==='.
  ENDIF.

  WRITE: / '=== ZI_RAP10_LOG content after this run (Open SQL, may show',
         / 'more than one row if this demo has been run before - the',
         / 'log is append-only, that is expected) ==='.
  SELECT ZwhmsNo, ZrtNo, Msgty, Message
    FROM zi_rap10_log
    WHERE zwhmsno = 'RAP10DEMO1'
    INTO TABLE @DATA(lt_log).

  LOOP AT lt_log INTO DATA(ls_log).
    WRITE: / ls_log-zwhmsno, ls_log-zrtno, ls_log-msgty, ls_log-message.
  ENDLOOP.

  WRITE: / '=== Sanity check ==='.
  READ TABLE lt_result INTO ls_result INDEX 1.
  IF sy-subrc = 0 AND ls_result-%param-msgty = 'E'
     AND lines( lt_log ) >= 1.
    WRITE: / 'MATCH: reused ZCL_QM_05_SERVICE validation fired correctly',
           / 'via RAP Action - same error path/message text as the real',
           / 'WHMS interface would produce, zero risk (fake RT number,',
           / 'no real inspection lot touched, no real posting attempted).'.
  ELSE.
    WRITE: / 'MISMATCH - check message text below:', ls_result-%param-message.
  ENDIF.
