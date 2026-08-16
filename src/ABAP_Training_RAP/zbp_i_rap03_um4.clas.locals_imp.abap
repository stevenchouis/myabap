CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS lock FOR LOCK
      IMPORTING it_lock FOR LOCK test.

    METHODS create FOR MODIFY
      IMPORTING it_create FOR CREATE test.

    METHODS read FOR READ
      IMPORTING it_read FOR READ test RESULT et_result.

    METHODS determine_creation_info
      RETURNING VALUE(rs_info) TYPE zrap03_umtest.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD lock.
  ENDMETHOD.

  METHOD create.
    DATA(ls_info) = determine_creation_info( ).

    LOOP AT it_create INTO DATA(ls_create).
      IF ls_create-descr IS INITIAL.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-test.
        APPEND VALUE #( %cid = ls_create-%cid
                         %msg = new_message_with_text(
                           severity = if_abap_behv_message=>severity-error
                           text     = 'Description must not be empty' ) )
          TO reported-test.
        CONTINUE.
      ENDIF.

      INSERT zrap03_umtest FROM @( VALUE #(
        client     = sy-mandt
        id         = ls_create-id
        descr      = ls_create-descr
        created_at = ls_info-created_at
        created_by = ls_info-created_by ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD determine_creation_info.
    rs_info-created_at = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) ).
    rs_info-created_by = sy-uname.
  ENDMETHOD.

  METHOD read.
    LOOP AT it_read INTO DATA(ls_key).
      SELECT SINGLE id, descr, created_at, created_by
        FROM zrap03_umtest WHERE id = @ls_key-id INTO @DATA(ls_data).
      IF sy-subrc = 0.
        APPEND VALUE #(
          %key       = ls_key-%key
          id         = ls_data-id
          descr      = ls_data-descr
          created_at = ls_data-created_at
          created_by = ls_data-created_by ) TO et_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
