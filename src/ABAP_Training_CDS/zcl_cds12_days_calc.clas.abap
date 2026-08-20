CLASS zcl_cds12_days_calc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cds12_days_calc IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    " To compute DaysUntilDeparture we need the original FLDATE column.
    et_requested_orig_elements = VALUE #( ( `FLDATE` ) ).
  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA(lv_today) = sy-datum.

    LOOP AT it_original_data ASSIGNING FIELD-SYMBOL(<ls_orig>).
      DATA(lv_index) = sy-tabix.

      ASSIGN COMPONENT 'FLDATE' OF STRUCTURE <ls_orig> TO FIELD-SYMBOL(<lv_fldate>).
      CHECK <lv_fldate> IS ASSIGNED.

      READ TABLE ct_calculated_data ASSIGNING FIELD-SYMBOL(<ls_calc>) INDEX lv_index.
      CHECK sy-subrc = 0.

      ASSIGN COMPONENT 'DAYSUNTILDEPARTURE' OF STRUCTURE <ls_calc> TO FIELD-SYMBOL(<lv_days>).
      CHECK <lv_days> IS ASSIGNED.

      <lv_days> = <lv_fldate> - lv_today.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
