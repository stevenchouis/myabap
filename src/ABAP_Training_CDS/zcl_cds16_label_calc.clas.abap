CLASS zcl_cds16_label_calc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cds16_label_calc IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    " To compute DisplayLabel we need OrgUnitId, OrgUnitName and HeadCount.
    et_requested_orig_elements = VALUE #(
      ( `ORGUNITID` )
      ( `ORGUNITNAME` )
      ( `HEADCOUNT` )
    ).
  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~calculate.
    LOOP AT it_original_data ASSIGNING FIELD-SYMBOL(<ls_orig>).
      DATA(lv_index) = sy-tabix.

      ASSIGN COMPONENT 'ORGUNITID'   OF STRUCTURE <ls_orig> TO FIELD-SYMBOL(<lv_id>).
      ASSIGN COMPONENT 'ORGUNITNAME' OF STRUCTURE <ls_orig> TO FIELD-SYMBOL(<lv_name>).
      ASSIGN COMPONENT 'HEADCOUNT'   OF STRUCTURE <ls_orig> TO FIELD-SYMBOL(<lv_head>).
      CHECK <lv_id> IS ASSIGNED AND <lv_name> IS ASSIGNED AND <lv_head> IS ASSIGNED.

      READ TABLE ct_calculated_data ASSIGNING FIELD-SYMBOL(<ls_calc>) INDEX lv_index.
      CHECK sy-subrc = 0.

      ASSIGN COMPONENT 'DISPLAYLABEL' OF STRUCTURE <ls_calc> TO FIELD-SYMBOL(<lv_label>).
      CHECK <lv_label> IS ASSIGNED.

      <lv_label> = |{ <lv_id> } - { <lv_name> } ({ <lv_head> } staff)|.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
