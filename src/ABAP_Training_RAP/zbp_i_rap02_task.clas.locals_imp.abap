CLASS lhc_task DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setCreationInfo FOR DETERMINATION Task~setCreationInfo
      IMPORTING keys FOR Task.
ENDCLASS.

CLASS lhc_task IMPLEMENTATION.

  METHOD setCreationInfo.
    READ ENTITIES OF zi_rap02_task IN LOCAL MODE
      ENTITY task
        FIELDS ( created_at created_by ) WITH CORRESPONDING #( keys )
      RESULT DATA(tasks).

    MODIFY ENTITIES OF zi_rap02_task IN LOCAL MODE
      ENTITY task
        UPDATE FIELDS ( created_at created_by )
        WITH VALUE #( FOR ls_task IN tasks (
          %key       = ls_task-%key
          created_at = cl_abap_tstmp=>utclong2tstmp( utclong_current( ) )
          created_by = sy-uname ) ).
  ENDMETHOD.

ENDCLASS.
