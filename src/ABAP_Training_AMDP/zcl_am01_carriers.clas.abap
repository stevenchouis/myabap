CLASS zcl_am01_carriers DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    TYPES:
      BEGIN OF ty_carrier,
        carrid   TYPE s_carr_id,
        carrname TYPE s_carrname,
      END OF ty_carrier,
      tt_carrier TYPE STANDARD TABLE OF ty_carrier WITH EMPTY KEY.

    CLASS-METHODS get_carriers
      IMPORTING
        VALUE(iv_mandt) TYPE mandt
      EXPORTING
        VALUE(et_carriers) TYPE tt_carrier.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am01_carriers IMPLEMENTATION.

  METHOD get_carriers BY DATABASE PROCEDURE
    FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING scarr.

    et_carriers = SELECT carrid, carrname
                    FROM scarr
                    WHERE mandt = :iv_mandt
                    ORDER BY carrid;

  ENDMETHOD.

ENDCLASS.
