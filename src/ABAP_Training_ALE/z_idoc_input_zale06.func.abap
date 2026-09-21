FUNCTION z_idoc_input_zale06
  IMPORTING
    VALUE(input_method) LIKE bdwfap_par-inputmethd
    VALUE(mass_processing) LIKE bdwfap_par-mass_proc
  EXPORTING
    VALUE(workflow_result) LIKE bdwf_param-result
    VALUE(application_variable) LIKE bdwf_param-appl_var
    VALUE(in_update_task) LIKE bdwfap_par-updatetask
    VALUE(call_transaction_done) LIKE bdwfap_par-calltrans
  TABLES
    idoc_contrl LIKE edidc
    idoc_data LIKE edidd
    idoc_status LIKE bdidocstat
    return_variables LIKE bdwfretvar
    serialization_info LIKE bdi_ser
  EXCEPTIONS
    wrong_function_called.

  CONSTANTS lc_wf_ok    TYPE bdwf_param-result VALUE '0'.
  CONSTANTS lc_wf_error TYPE bdwf_param-result VALUE '99999'.

  DATA lo_in     TYPE REF TO zcl_ale08_po_in.
  DATA lt_seg    TYPE zcl_ale08_po_in=>tt_edidd.
  DATA ls_result TYPE zcl_ale08_po_in=>ty_result.

  lo_in = NEW #( ).
  workflow_result = lc_wf_ok.

  LOOP AT idoc_contrl.
    IF idoc_contrl-mestyp <> 'ZALE06'.
      RAISE wrong_function_called.
    ENDIF.

    CLEAR lt_seg.
    LOOP AT idoc_data WHERE docnum = idoc_contrl-docnum.
      APPEND idoc_data TO lt_seg.
    ENDLOOP.

    ls_result = lo_in->process( iv_docnum = idoc_contrl-docnum
                                it_data   = lt_seg ).

    CLEAR idoc_status.
    idoc_status-docnum = idoc_contrl-docnum.
    idoc_status-msgid  = '00'.
    idoc_status-msgno  = '398'.
    idoc_status-msgv1  = ls_result-message.
    idoc_status-repid  = sy-repid.

    CLEAR return_variables.
    return_variables-doc_number = idoc_contrl-docnum.

    IF ls_result-success = abap_true.
      idoc_status-status         = '53'.
      idoc_status-msgty          = 'S'.
      return_variables-wf_param  = 'Processed_IDOCs'.
    ELSE.
      idoc_status-status         = '51'.
      idoc_status-msgty          = 'E'.
      return_variables-wf_param  = 'Error_IDOCs'.
      workflow_result            = lc_wf_error.
    ENDIF.

    APPEND idoc_status.
    APPEND return_variables.
  ENDLOOP.
ENDFUNCTION.
