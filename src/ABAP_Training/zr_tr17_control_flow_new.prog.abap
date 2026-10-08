*&---------------------------------------------------------------------*
*& Report  ZR_TR17_CONTROL_FLOW_NEW
*& 練習 17：運算與流程控制（答案程式，新式寫法版）
*& 對照 ZR_TR17_CONTROL_FLOW：輸出相同；IF 賦值改用 COND、CASE 改用 SWITCH，
*& 迴圈（DO/WHILE/CHECK）沒有新式寫法，維持原樣
*&---------------------------------------------------------------------*
REPORT zr_tr17_control_flow_new.

DATA: gv_a      TYPE i VALUE 17,
      gv_b      TYPE i VALUE 5,
      gv_result TYPE i,
      gv_int    TYPE i,
      gv_dec    TYPE p LENGTH 8 DECIMALS 2,
      gv_score  TYPE i VALUE 75,
      gv_sum    TYPE i,
      gv_loops  TYPE i,
      gv_n      TYPE i.

START-OF-SELECTION.
* 1) 算術運算子：沒有新舊之分
  gv_result = gv_a + gv_b.   WRITE: / '17 + 5 =', gv_result.
  gv_result = gv_a - gv_b.   WRITE: / '17 - 5 =', gv_result.
  gv_result = gv_a * gv_b.   WRITE: / '17 * 5 =', gv_result.
  gv_result = gv_a DIV gv_b. WRITE: / '17 DIV 5 =', gv_result.
  gv_result = gv_a MOD gv_b. WRITE: / '17 MOD 5 =', gv_result.

* 2) 目的地型別決定精度
  gv_int = gv_a / gv_b.
  gv_dec = gv_a / gv_b.
  WRITE: / '存進 i：', gv_int,
         / '存進 p：', gv_dec.

* 3) COND：IF/ELSEIF/ELSE 賦值合成一個運算式
*    # ＝型別由目標推導；目標是 DATA(...) 時，取第一個 THEN 的值（'A' → c LENGTH 1）
  DATA(gv_grade) = COND #( WHEN gv_score >= 80 THEN 'A'
                           WHEN gv_score >= 60 THEN 'B'
                           ELSE 'C' ).
  WRITE: / gv_score, '分 → 等第', gv_grade.

* 4) SWITCH：對同一個值比對多個候選值，回傳對應結果
*    WHEN 後面只能放一個值，CASE 的 WHEN 'B' OR 'C' 要拆成兩個 WHEN
  WRITE / SWITCH string( gv_grade
                         WHEN 'A' THEN `優等`
                         WHEN 'B' THEN `普通`
                         WHEN 'C' THEN `普通`
                         ELSE `資料異常` ).

* 5)～8) 迴圈與 EXIT／CHECK：沒有新式寫法
  DO 5 TIMES.
    WRITE: / '第', sy-index, '圈'.
  ENDDO.

  gv_sum = 0.
  DO.
    gv_sum = gv_sum + sy-index.
    IF gv_sum > 100.
      gv_loops = sy-index.
      EXIT.
    ENDIF.
  ENDDO.
  WRITE: / '累加超過 100：總和', gv_sum, '，最後圈數', gv_loops.

  gv_n = 1.
  WHILE ( gv_n + 1 ) * ( gv_n + 1 ) <= 200.
    gv_n = gv_n + 1.
  ENDWHILE.
  WRITE: / '平方不超過 200 的最大整數：', gv_n.

  DO 10 TIMES.
    CHECK sy-index MOD 2 = 0.
    WRITE: / '偶數：', sy-index.
  ENDDO.
