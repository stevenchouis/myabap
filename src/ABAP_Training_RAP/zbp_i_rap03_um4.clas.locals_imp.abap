CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS lock FOR LOCK
      IMPORTING it_lock FOR LOCK test.

    METHODS create FOR MODIFY
      IMPORTING it_create FOR CREATE test.

    METHODS read FOR READ
      IMPORTING it_read FOR READ test RESULT et_result.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD lock.
  ENDMETHOD.

  METHOD create.
    LOOP AT it_create INTO DATA(ls_create).
      INSERT zrap03_umtest FROM @( VALUE #( client = sy-mandt id = ls_create-id descr = ls_create-descr ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    LOOP AT it_read INTO DATA(ls_key).
      SELECT SINGLE id, descr FROM zrap03_umtest WHERE id = @ls_key-id INTO @DATA(ls_data).
      IF sy-subrc = 0.
        APPEND VALUE #( %key = ls_key-%key id = ls_data-id descr = ls_data-descr ) TO et_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
