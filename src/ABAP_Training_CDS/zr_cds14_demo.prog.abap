REPORT zr_cds14_demo.

WRITE: / '=== ZI_CDS14_ORGUNIT_HIER: plain Open SQL SELECT (flat rows, no tree traversal) ==='.
SELECT OrgUnitId, ParentId, OrgUnitName, SeqNumber
  FROM zi_cds14_orgunit_hier
  WHERE orgunitid LIKE 'Z%'
  ORDER BY orgunitid
  INTO TABLE @DATA(lt_flat).

LOOP AT lt_flat INTO DATA(ls_flat).
  WRITE: / ls_flat-orgunitid, ls_flat-parentid, ls_flat-orgunitname.
ENDLOOP.

WRITE: / '=== Sanity check: all 6 org units present, root has empty ParentId ==='.
DATA(lv_root_ok) = abap_false.
LOOP AT lt_flat INTO ls_flat WHERE orgunitid = 'ZROOT' AND parentid = ''.
  lv_root_ok = abap_true.
ENDLOOP.
IF lv_root_ok = abap_true AND lines( lt_flat ) = 6.
  WRITE: / 'MATCH: hierarchy table data loaded correctly, row count', lines( lt_flat ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.

WRITE: / '=== Note: Open SQL HIERARCHY_DESCENDANTS() tree traversal was attempted but not resolved headlessly ==='.
WRITE: / 'Real compiler feedback trail (documented in the lecture, not re-executed here):'.
WRITE: / '1) HIERARCHY(SOURCE ... START WHERE ... SIBLINGS ORDER BY ...) -> "START" is invalid here (due to grammar).'.
WRITE: / '2) HIERARCHY_DESCENDANTS(SOURCE zi_cds14_orgunit_hier ...) -> entity must be a hierarchy or exposed via WITH HIERARCHY.'.
WRITE: / '3) WITH HIERARCHY <entity> -> requires a CTE alias (+name), not a plain entity name.'.
WRITE: / '4) WITH +hier AS (plain passthrough SELECT) WITH HIERARCHY +hier -> hierarchy "+HIER" was not found.'.
WRITE: / '5) HIERARCHY(SOURCE ... SIBLINGS ORDER BY ...) without CHILD TO PARENT ASSOCIATION -> SIBLINGS invalid here.'.
WRITE: / '6) HIERARCHY(SOURCE zi_cds14_orgunit_hier) bare form -> ")" invalid here; SOURCE requires CHILD TO PARENT ASSOCIATION or LEVELS.'.
WRITE: / 'Conclusion: this system''s Open SQL HIERARCHY_* navigators require the CHILD TO PARENT ASSOCIATION variant;'.
WRITE: / 'a CDS entity carrying only the @hierarchy.parentChild DDL annotation is not directly usable as a bare HIERARCHY() source.'.
WRITE: / 'Tree traversal verification is deferred to Eclipse Data Preview, which is designed to render CDS Hierarchy entities as a tree.'.
