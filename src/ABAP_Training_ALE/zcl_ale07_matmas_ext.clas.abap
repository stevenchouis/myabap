CLASS zcl_ale07_matmas_ext DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES tt_edidd TYPE STANDARD TABLE OF edidd WITH DEFAULT KEY.

    CONSTANTS:
      c_cimtype     TYPE edidc-cimtyp VALUE 'ZALE06_MATEXT',
      c_seg_general TYPE edidd-segnam VALUE 'E1MARAM',
      c_seg_ext     TYPE edidd-segnam VALUE 'Z1ALE06'.

    CLASS-METHODS fill_extension
      IMPORTING iv_segment_name TYPE edidd-segnam
                is_mara         TYPE mara
      CHANGING  ct_idoc_data    TYPE tt_edidd
                cv_cimtype      TYPE edidc-cimtyp.
ENDCLASS.


CLASS zcl_ale07_matmas_ext IMPLEMENTATION.

  METHOD fill_extension.
    DATA ls_ext TYPE z1ale06.

    cv_cimtype = c_cimtype.

    IF iv_segment_name <> c_seg_general.
      RETURN.
    ENDIF.

    ls_ext-saisj = is_mara-saisj.
    ls_ext-datab = is_mara-datab.
    APPEND VALUE #( segnam = c_seg_ext sdata = ls_ext ) TO ct_idoc_data.
  ENDMETHOD.

ENDCLASS.
