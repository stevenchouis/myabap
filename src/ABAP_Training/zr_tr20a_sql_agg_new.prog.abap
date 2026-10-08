*&---------------------------------------------------------------------*
*& Report  ZR_TR20A_SQL_AGG_NEW
*& 練習 20a：SQL 聚合與子查詢（答案程式，新式寫法版）
*& 對照 ZR_TR20A_SQL_AGG：輸出相同；欄位清單用逗號、宿主變數加 @、
*& INTO 放句尾、@DATA( ) 行內宣告；第 5 段內表累加改用 REDUCE ... WHERE
*&---------------------------------------------------------------------*
REPORT zr_tr20a_sql_agg_new LINE-SIZE 100.

TYPES: BEGIN OF ty_agg,
         carrid    TYPE sflight-carrid,
         carrname  TYPE scarr-carrname,
         cnt       TYPE i,
         seats     TYPE i,
         avg_price TYPE p LENGTH 12 DECIMALS 2,
         max_price TYPE sflight-price,
         min_price TYPE sflight-price,
       END OF ty_agg.

DATA: gt_agg   TYPE STANDARD TABLE OF ty_agg,
      gv_total TYPE i,
      gv_cnt   TYPE i,
      gv_sum   TYPE i.

START-OF-SELECTION.

* 1. GROUP BY：新式寫法欄位用逗號，INTO 放在 ORDER BY 之後
  SELECT c~carrid, c~carrname,
         COUNT( * ) AS cnt,
         SUM( f~seatsocc ) AS seats,
         AVG( f~price ) AS avg_price,
         MAX( f~price ) AS max_price,
         MIN( f~price ) AS min_price
    FROM sflight AS f
    INNER JOIN scarr AS c ON f~carrid = c~carrid
    GROUP BY c~carrid, c~carrname
    ORDER BY c~carrid
    INTO CORRESPONDING FIELDS OF TABLE @gt_agg.
  IF sy-subrc <> 0.
    WRITE / '查無資料！請先執行 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.

  WRITE / '=== 1. 各航空公司統計（GROUP BY） ==='.
  WRITE: /1 'ID', 5 'Name', 27(8) 'Flights', 37(10) 'Seats',
            49(12) 'Avg price', 63(12) 'Max price', 77(12) 'Min price'.
  ULINE.
  LOOP AT gt_agg INTO DATA(gs_agg).
    WRITE: /1 gs_agg-carrid, 5(20) gs_agg-carrname, 27(8) gs_agg-cnt, 37(10) gs_agg-seats,
              49(12) gs_agg-avg_price, 63(12) gs_agg-max_price, 77(12) gs_agg-min_price.
  ENDLOOP.

* 2. HAVING
  CLEAR gt_agg.
  SELECT carrid,
         COUNT( * ) AS cnt,
         SUM( seatsocc ) AS seats
    FROM sflight
    GROUP BY carrid
    HAVING SUM( seatsocc ) > 10000
    ORDER BY carrid
    INTO CORRESPONDING FIELDS OF TABLE @gt_agg.

  SKIP.
  WRITE / '=== 2. 已訂座位總數超過 10000 的公司（HAVING） ==='.
  LOOP AT gt_agg INTO gs_agg.
    WRITE: / gs_agg-carrid, gs_agg-cnt, gs_agg-seats.
  ENDLOOP.

* 3. DISTINCT：@DATA(gt_airp) 是一欄的內表，欄位名 airpfrom
  SELECT DISTINCT airpfrom
    FROM spfli
    ORDER BY airpfrom
    INTO TABLE @DATA(gt_airp).

  SKIP.
  WRITE / '=== 3. 有航班起飛的機場（DISTINCT） ==='.
  LOOP AT gt_airp INTO DATA(gs_airp).
    WRITE gs_airp-airpfrom.
  ENDLOOP.

  SELECT COUNT( * ) FROM spfli INTO @gv_cnt.
  SELECT COUNT( DISTINCT airpfrom ) FROM spfli INTO @gv_sum.
  WRITE: / '航線總數', gv_cnt, '／ 不重複的起飛機場數', gv_sum.

* 4a. IN 子查詢
  SELECT carrid FROM scarr
    WHERE carrid IN ( SELECT carrid FROM spfli WHERE airpfrom = 'FRA' )
    ORDER BY carrid
    INTO TABLE @DATA(gt_carr).

  SKIP.
  WRITE / '=== 4a. 有航線從 FRA 起飛的公司（IN 子查詢） ==='.
  LOOP AT gt_carr INTO DATA(gs_carr).
    WRITE gs_carr-carrid.
  ENDLOOP.

* 4b. EXISTS
  CLEAR gt_carr.
  SELECT carrid FROM scarr AS c
    WHERE EXISTS ( SELECT * FROM spfli
                     WHERE carrid = c~carrid AND airpfrom = 'FRA' )
    ORDER BY carrid
    INTO TABLE @gt_carr.

  SKIP.
  WRITE / '=== 4b. 同上（EXISTS 子查詢，結果應相同） ==='.
  LOOP AT gt_carr INTO gs_carr.
    WRITE gs_carr-carrid.
  ENDLOOP.

* 4c. NOT EXISTS
  CLEAR gt_carr.
  SELECT carrid FROM scarr AS c
    WHERE NOT EXISTS ( SELECT * FROM sflight WHERE carrid = c~carrid )
    ORDER BY carrid
    INTO TABLE @gt_carr.

  SKIP.
  WRITE / '=== 4c. 沒有任何航班的公司（NOT EXISTS） ==='.
  LOOP AT gt_carr INTO gs_carr.
    WRITE gs_carr-carrid.
  ENDLOOP.

* 5. 交叉驗證：內表累加改用 REDUCE，FOR ... WHERE 只加這家公司的列
  CLEAR gt_agg.
  SELECT carrid, SUM( seatsocc ) AS seats
    FROM sflight
    GROUP BY carrid
    ORDER BY carrid
    INTO CORRESPONDING FIELDS OF TABLE @gt_agg.
  SELECT * FROM sflight INTO TABLE @DATA(gt_det).

  SKIP.
  WRITE / '=== 5. 交叉驗證（SQL 聚合 vs 內表累加） ==='.
  LOOP AT gt_agg INTO gs_agg.
    DATA(gv_chk) = REDUCE i( INIT s = 0
                             FOR d IN gt_det WHERE ( carrid = gs_agg-carrid )
                             NEXT s = s + d-seatsocc ).
    DATA(gv_diff) = gs_agg-seats - gv_chk.
    WRITE: / gs_agg-carrid, gs_agg-seats, gv_chk, '差異', gv_diff.
    gv_total = gv_total + gs_agg-seats.
  ENDLOOP.

  SELECT SUM( seatsocc ) FROM sflight INTO @gv_sum.
  WRITE: / '全部座位數 SUM（不分組）', gv_sum, '／ 各組加總', gv_total.

* 6. 陷阱：多個欄位接進多個變數，新式寫法 INTO ( @a, @b )
  SELECT COUNT( * ), SUM( seatsocc )
    FROM sflight
    WHERE carrid = 'ZZ'
    INTO ( @gv_cnt, @gv_sum ).

  SKIP.
  WRITE / '=== 6. 查一個不存在的公司（ZZ） ==='.
  WRITE: / 'sy-subrc =', sy-subrc, '／ COUNT =', gv_cnt, '／ SUM =', gv_sum.
  IF gv_cnt = 0.
    WRITE / '→ sy-subrc 是 0，但其實沒有資料：判斷有沒有資料要看 COUNT( * )'.
  ENDIF.
