REPORT zr_cds16_demo.

" Backfill headcount for the cds14 test data (cds14's own snapshot program is untouched)
UPDATE ztcds14_orgunit SET headcount = 5  WHERE orgunit_id = 'ZROOT'.
UPDATE ztcds14_orgunit SET headcount = 20 WHERE orgunit_id = 'ZSALES'.
UPDATE ztcds14_orgunit SET headcount = 8  WHERE orgunit_id = 'ZOPS'.
UPDATE ztcds14_orgunit SET headcount = 12 WHERE orgunit_id = 'ZSALESEU'.
UPDATE ztcds14_orgunit SET headcount = 8  WHERE orgunit_id = 'ZSALESUS'.
UPDATE ztcds14_orgunit SET headcount = 8  WHERE orgunit_id = 'ZOPSFLT'.
COMMIT WORK.

WRITE: / '=== 1. Analytical + Value Help annotations: plain Open SQL works normally ==='.
SELECT OrgUnitId, ParentId, OrgUnitName, HeadCount
  FROM zi_cds16_orgunit_final
  WHERE orgunitid LIKE 'Z%'
  ORDER BY orgunitid
  INTO TABLE @DATA(lt_result).

LOOP AT lt_result INTO DATA(ls_row).
  WRITE: / ls_row-orgunitid, ls_row-parentid, ls_row-orgunitname, ls_row-headcount.
ENDLOOP.

DATA(lv_total_head) = REDUCE i( INIT sum = 0 FOR ls IN lt_result NEXT sum = sum + ls-headcount ).
WRITE: / 'Sum of HeadCount across all org units:', lv_total_head.

WRITE: / '=== 2. Virtual Element (DisplayLabel): plain Open SQL only sees the placeholder ==='.
DATA(lv_all_blank) = abap_true.
LOOP AT lt_result INTO ls_row.
ENDLOOP.
SELECT OrgUnitId, DisplayLabel FROM zi_cds16_orgunit_final WHERE orgunitid = 'ZROOT' INTO TABLE @DATA(lt_label_flat).
READ TABLE lt_label_flat INTO DATA(ls_label_flat) INDEX 1.
WRITE: / 'ZROOT DisplayLabel via Open SQL:', ls_label_flat-displaylabel, '(expected: blank placeholder)'.

WRITE: / '=== 3. Virtual Element exit class logic, verified directly via Mock (cds10/cds12 technique) ==='.
TYPES: BEGIN OF ty_orig,
         orgunitid   TYPE c LENGTH 10,
         orgunitname TYPE c LENGTH 40,
         headcount   TYPE i,
       END OF ty_orig.
TYPES: BEGIN OF ty_calc,
         displaylabel TYPE c LENGTH 60,
       END OF ty_calc.
DATA lt_orig TYPE STANDARD TABLE OF ty_orig WITH EMPTY KEY.
DATA lt_calc TYPE STANDARD TABLE OF ty_calc WITH EMPTY KEY.

lt_orig = VALUE #( ( orgunitid = 'ZROOT' orgunitname = 'CEO Office' headcount = 5 ) ).
lt_calc = VALUE #( ( displaylabel = '' ) ).

DATA(lo_calc) = NEW zcl_cds16_label_calc( ).
TRY.
    lo_calc->if_sadl_exit_calc_element_read~calculate(
      EXPORTING it_original_data           = lt_orig
                it_requested_calc_elements = VALUE if_sadl_exit_calc_element_read=>tt_elements( )
      CHANGING  ct_calculated_data         = lt_calc ).
  CATCH cx_sadl_exit INTO DATA(lx_error).
    WRITE: / 'EXCEPTION:', lx_error->get_text( ).
ENDTRY.

READ TABLE lt_calc INTO DATA(ls_calc) INDEX 1.
WRITE: / 'Computed DisplayLabel:', ls_calc-displaylabel.

WRITE: / '=== Final sanity check ==='.
IF lv_total_head = 61 AND ls_label_flat-displaylabel IS INITIAL AND ls_calc-displaylabel CS 'CEO Office'.
  WRITE: / 'MATCH: analytics/value-help work via Open SQL, virtual element placeholder confirmed, exit class logic verified via mock'.
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
