CLASS zcl_am05_flight_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    CLASS-METHODS check_carrier_exists
      IMPORTING
        VALUE(iv_mandt)  TYPE mandt
        VALUE(iv_carrid) TYPE s_carr_id
      RAISING
        cx_amdp_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am05_flight_validator IMPLEMENTATION.

  METHOD check_carrier_exists BY DATABASE PROCEDURE
    FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING scarr.

    DECLARE lv_cnt INTEGER;
    DECLARE SQLSCRIPT_ERROR CONDITION FOR SQL_ERROR_CODE 10001;

    SELECT COUNT(*) INTO lv_cnt FROM scarr
     WHERE mandt = :iv_mandt AND carrid = :iv_carrid;

    IF :lv_cnt = 0 THEN
      SIGNAL SQLSCRIPT_ERROR SET MESSAGE_TEXT = 'Carrier not found in SCARR';
    END IF;

  ENDMETHOD.

ENDCLASS.
