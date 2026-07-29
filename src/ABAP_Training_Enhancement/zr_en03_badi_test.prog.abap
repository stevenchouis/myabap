*&---------------------------------------------------------------------*
*& Report ZR_EN03_BADI_TEST
*&---------------------------------------------------------------------*
* Enhancement course en03: BADI_MM_MATNR only has an ENHS/XS shadow on
* top of an old SXSD/XD Definition (true classic BAdI, predates the
* GET BADI/CALL BADI keyword syntax) - it must be called via the old
* cl_exithandler=>get_instance pattern, not the new keywords.
* Question: does a Multi Use BAdI with zero active implementations
* still return a bound, callable instance (unlike Single Use, which
* raises an exception)?
REPORT zr_en03_badi_test.

DATA go_exit TYPE REF TO if_ex_badi_mm_matnr.
DATA ls_mara TYPE mara.

CALL METHOD cl_exithandler=>get_instance
  EXPORTING
    exit_name = 'BADI_MM_MATNR'
  CHANGING
    instance  = go_exit
  EXCEPTIONS
    no_reference = 1
    OTHERS       = 2.
WRITE: / 'cl_exithandler=>get_instance sy-subrc =', sy-subrc.

IF go_exit IS BOUND.
  WRITE: / 'go_exit is bound.'.
ELSE.
  WRITE: / 'go_exit is NOT bound.'.
ENDIF.

CALL METHOD go_exit->check_mara
  EXPORTING
    mdata = ls_mara
  EXCEPTIONS
    in_use = 1.
WRITE: / 'check_mara sy-subrc =', sy-subrc.
WRITE: / 'Reached end of program without a dump.'.