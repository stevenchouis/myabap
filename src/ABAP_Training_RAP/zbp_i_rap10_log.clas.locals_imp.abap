CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS lock FOR LOCK
      IMPORTING it_lock FOR LOCK log.

    METHODS submitWhmsRequest FOR MODIFY
      IMPORTING keys FOR ACTION log~SubmitWhmsRequest RESULT result.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD lock.
  ENDMETHOD.

  METHOD submitWhmsRequest.
    DATA lv_timestamp TYPE timestampl.
    lv_timestamp = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) ).

    LOOP AT keys INTO DATA(ls_key).
      DATA lt_response TYPE ztt_qm005_outbound.
      CLEAR lt_response.

      " Reuse existing production business logic 1:1 - ZCL_QM_05_SERVICE is the same
      " class the Classic REST interface ZCL_QM_05_RESOURCE calls (package ZQM1).
      " Not modified in any way, only called - see rap10 lecture for the architecture.
      zcl_qm_05_service=>process_requests(
        EXPORTING it_request  = ls_key-%param
        IMPORTING et_response = lt_response ).

      LOOP AT lt_response INTO DATA(ls_resp).
        APPEND VALUE #( %cid   = ls_key-%cid
                         %param = ls_resp ) TO result.

        INSERT zrap10_log FROM @( VALUE #(
          mandt      = sy-mandt
          log_id     = cl_system_uuid=>create_uuid_x16_static( )
          zwhms_no   = ls_resp-zwhms_no
          zrt_no     = ls_resp-zrt_no
          msgty      = ls_resp-msgty
          message    = ls_resp-message
          created_at = lv_timestamp ) ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
