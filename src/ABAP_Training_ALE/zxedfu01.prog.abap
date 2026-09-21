zcl_ale10_invoic_ext=>fill_control(
  EXPORTING
    is_vbdkr    = dvbdkr
  CHANGING
    cs_control  = control_record_out ).
