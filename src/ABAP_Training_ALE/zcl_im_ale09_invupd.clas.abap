CLASS zcl_im_ale09_invupd DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_invoice_update.
ENDCLASS.


CLASS zcl_im_ale09_invupd IMPLEMENTATION.

  METHOD if_ex_invoice_update~change_at_save.
  ENDMETHOD.


  METHOD if_ex_invoice_update~change_before_update.
  ENDMETHOD.


  METHOD if_ex_invoice_update~change_in_update.
    zcl_ale09_miro_out=>enqueue( s_rbkp_new ).
  ENDMETHOD.

ENDCLASS.
