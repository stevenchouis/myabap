*&---------------------------------------------------------------------*
*& INCLUDE          ZXCO1U01
*&---------------------------------------------------------------------*
CALL METHOD zcl_en08_complog=>log_change
  EXPORTING
    it_head = header_table[]
    it_comp = component_table[].
