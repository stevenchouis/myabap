zcl_ale07_matmas_ext=>fill_extension(
  EXPORTING
    iv_segment_name = segment_name
    is_mara         = f_mara
  CHANGING
    ct_idoc_data    = idoc_data[]
    cv_cimtype      = idoc_cimtype ).
