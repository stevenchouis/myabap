REPORT zr_tr26_modern_syntax.

*&---------------------------------------------------------------------*
*& 1. 字串模板（String Template）
*&---------------------------------------------------------------------*
WRITE: / '===== 1. 字串模板 ====='.

DATA: gv_last  TYPE c LENGTH 10 VALUE '王',
      gv_first TYPE c LENGTH 10 VALUE '小明',
      gv_score TYPE i VALUE 85,
      gv_code  TYPE c LENGTH 3 VALUE 'lh'.

WRITE: / |全名：{ gv_last }{ gv_first }|.
WRITE: / |成績（靠右對齊補零）：{ gv_score WIDTH = 5 ALIGN = RIGHT PAD = '0' }|.
WRITE: / |代碼轉大寫：{ gv_code CASE = UPPER }|.

*&---------------------------------------------------------------------*
*& 2. New Open SQL：Inline Declaration ＋ SELECT 內的 CASE 運算式
*&---------------------------------------------------------------------*
WRITE: / '===== 2. New Open SQL ====='.

SELECT scarr~carrid, scarr~carrname, sflight~connid, sflight~price,
       CASE WHEN sflight~price < 500  THEN 'LOW'
            WHEN sflight~price < 1500 THEN 'MID'
            ELSE 'HIGH'
       END AS price_level
  FROM scarr
  INNER JOIN sflight ON sflight~carrid = scarr~carrid
  ORDER BY scarr~carrid, sflight~connid
  INTO TABLE @DATA(gt_flight)
  UP TO 10 ROWS.

LOOP AT gt_flight INTO DATA(gs_flight).
  WRITE: / gs_flight-carrid, gs_flight-carrname(20), gs_flight-connid,
           gs_flight-price, gs_flight-price_level.
ENDLOOP.

*&---------------------------------------------------------------------*
*& 3. COND：依成績算等第（取代 IF/ELSEIF）
*&---------------------------------------------------------------------*
WRITE: / '===== 3. COND ====='.

DATA(gv_level) = COND #( WHEN gv_score >= 90 THEN 'A'
                          WHEN gv_score >= 80 THEN 'B'
                          WHEN gv_score >= 60 THEN 'C'
                          ELSE 'D' ).
WRITE: / |成績等級：{ gv_level }|.

*&---------------------------------------------------------------------*
*& 4. SWITCH：依代碼轉換名稱（取代 CASE 陳述式）
*&---------------------------------------------------------------------*
WRITE: / '===== 4. SWITCH ====='.

DATA gv_carrid TYPE s_carr_id VALUE 'LH'.

DATA(gv_carrname) = SWITCH #( gv_carrid
                       WHEN 'LH' THEN 'Lufthansa'
                       WHEN 'AA' THEN 'American Airlines'
                       WHEN 'UA' THEN 'United Airlines'
                       ELSE 'Unknown' ).
WRITE: / |航空公司：{ gv_carrname }|.

*&---------------------------------------------------------------------*
*& 5. VALUE：建構內表（取代逐筆 APPEND）
*&---------------------------------------------------------------------*
WRITE: / '===== 5. VALUE ====='.

TYPES: BEGIN OF ty_item,
         matnr TYPE c LENGTH 10,
         qty   TYPE i,
       END OF ty_item,
       tt_item TYPE SORTED TABLE OF ty_item
                WITH UNIQUE KEY matnr
                WITH NON-UNIQUE SORTED KEY by_qty COMPONENTS qty.

DATA(gt_item) = VALUE tt_item( ( matnr = 'M001' qty = 10 )
                                ( matnr = 'M002' qty = 25 )
                                ( matnr = 'M003' qty = 5 ) ).

LOOP AT gt_item INTO DATA(gs_item).
  WRITE: / gs_item-matnr, gs_item-qty.
ENDLOOP.

*&---------------------------------------------------------------------*
*& 6. REDUCE：累加（取代 LOOP + ADD）
*&---------------------------------------------------------------------*
WRITE: / '===== 6. REDUCE ====='.

DATA(gv_total_qty) = REDUCE i( INIT sum = 0
                                 FOR wa IN gt_item
                                 NEXT sum = sum + wa-qty ).
WRITE: / |總數量：{ gv_total_qty }|.

*&---------------------------------------------------------------------*
*& 7. FILTER：篩選子集合（取代 LOOP + WHERE 判斷 + APPEND）
*&---------------------------------------------------------------------*
WRITE: / '===== 7. FILTER ====='.

DATA(gt_item_big) = FILTER #( gt_item USING KEY by_qty WHERE qty >= 10 ).

LOOP AT gt_item_big INTO DATA(gs_item_big).
  WRITE: / gs_item_big-matnr, gs_item_big-qty.
ENDLOOP.
