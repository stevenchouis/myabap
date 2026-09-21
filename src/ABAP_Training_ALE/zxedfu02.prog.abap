zcl_ale10_invoic_ext=>fill_segment(
  EXPORTING
    is_vbdkr     = xvbdkr
  CHANGING
    ct_idoc_data = int_edidd[] ).
