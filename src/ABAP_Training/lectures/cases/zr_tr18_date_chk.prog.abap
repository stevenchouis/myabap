REPORT zr_tr18_date_chk.
* 驗證講義 17／18 新式寫法的細節（2026-10-08）
DATA: gv_d     TYPE d VALUE '20261008',
      gv_dats  TYPE sydatum VALUE '20261008',
      gv_txt   TYPE c LENGTH 10,
      gv_score TYPE i VALUE 30,
      gv_code  TYPE c LENGTH 1 VALUE 'X'.
DATA(gv_inl) = sy-datum.
* --- 日期輸出 ---
WRITE: / '1) TYPE d        :', gv_d.
WRITE: / '2) TYPE d (10)   :', (10) gv_d.
WRITE: / '3) TYPE sydatum  :', gv_dats.
WRITE: / '4) DATA( sy-datum ):', gv_inl.
WRITE gv_d TO gv_txt.
WRITE: / '5) WRITE d TO c10:', gv_txt.
WRITE: / '6) template      :', |{ gv_d DATE = USER }|.
WRITE: / '7) template ISO  :', |{ gv_d DATE = ISO }|.
* --- COND / SWITCH 沒有分支命中、也沒有 ELSE ---
DATA(gv_c1) = COND string( WHEN gv_score >= 60 THEN `PASS` ).
WRITE: / '8) COND no ELSE  : [', gv_c1, ']'.
TRY.
    DATA(gv_s1) = SWITCH string( gv_code WHEN 'A' THEN `AAA` ).
    WRITE: / '9) SWITCH no ELSE: [', gv_s1, ']'.
  CATCH cx_root INTO DATA(gx).
    WRITE: / '9) SWITCH no ELSE: exception', gx->get_text( ).
ENDTRY.
* --- CASE 沒有 WHEN OTHERS ---
CASE gv_code.
  WHEN 'A'.
    WRITE / '10) CASE A'.
ENDCASE.
WRITE: / '10) CASE without OTHERS: no error'.
