*&---------------------------------------------------------------------*
*& Report  ZR_TR20A_SQL_AGG
*& 練習 20a：SQL 聚合與子查詢（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr20a_sql_agg LINE-SIZE 100.

* 傳統寫法：先宣告結構與內表，SELECT 用 INTO CORRESPONDING FIELDS OF TABLE
* 聚合函數的結果欄位一律用 AS 取別名，別名要跟結構欄位同名才對得上
TYPES: BEGIN OF ty_agg,
         carrid    TYPE sflight-carrid,
         carrname  TYPE scarr-carrname,
         cnt       TYPE i,                          " COUNT( * ) 航班數
         seats     TYPE i,                          " SUM( seatsocc ) 已訂座位
         avg_price TYPE p LENGTH 12 DECIMALS 2,     " AVG( price ) 平均票價
         max_price TYPE sflight-price,              " MAX( price )
         min_price TYPE sflight-price,              " MIN( price )
       END OF ty_agg.

DATA: gt_agg    TYPE STANDARD TABLE OF ty_agg,
      gs_agg    TYPE ty_agg,
      gt_airp   TYPE STANDARD TABLE OF spfli-airpfrom,
      gv_airp   TYPE spfli-airpfrom,
      gt_carr   TYPE STANDARD TABLE OF scarr-carrid,
      gv_carr   TYPE scarr-carrid,
      gt_det    TYPE STANDARD TABLE OF sflight,
      gs_det    TYPE sflight,
      gv_total  TYPE i,
      gv_chk    TYPE i,
      gv_cnt    TYPE i,
      gv_sum    TYPE i,
      gv_diff   TYPE i.

START-OF-SELECTION.

*----------------------------------------------------------------------*
* 1. GROUP BY：每家公司一列的統計（資料庫算完才回傳）
*    SELECT 清單裡「不是聚合函數」的欄位，都必須出現在 GROUP BY
*----------------------------------------------------------------------*
  SELECT c~carrid c~carrname
         COUNT( * ) AS cnt
         SUM( f~seatsocc ) AS seats
         AVG( f~price ) AS avg_price
         MAX( f~price ) AS max_price
         MIN( f~price ) AS min_price
    INTO CORRESPONDING FIELDS OF TABLE gt_agg
    FROM sflight AS f
    INNER JOIN scarr AS c ON f~carrid = c~carrid
    GROUP BY c~carrid c~carrname
    ORDER BY c~carrid.
  IF sy-subrc <> 0.
    WRITE / '查無資料！請先執行 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.

  WRITE / '=== 1. 各航空公司統計（GROUP BY） ==='.
  WRITE: /1 'ID', 5 'Name', 27(8) 'Flights', 37(10) 'Seats',
            49(12) 'Avg price', 63(12) 'Max price', 77(12) 'Min price'.
  ULINE.
  LOOP AT gt_agg INTO gs_agg.
    WRITE: /1 gs_agg-carrid, 5(20) gs_agg-carrname, 27(8) gs_agg-cnt, 37(10) gs_agg-seats,
              49(12) gs_agg-avg_price, 63(12) gs_agg-max_price, 77(12) gs_agg-min_price.
  ENDLOOP.

*----------------------------------------------------------------------*
* 2. HAVING：過濾「分組之後」的結果（WHERE 是過濾分組之前的明細）
*----------------------------------------------------------------------*
  CLEAR gt_agg.
  SELECT carrid
         COUNT( * ) AS cnt
         SUM( seatsocc ) AS seats
    INTO CORRESPONDING FIELDS OF TABLE gt_agg
    FROM sflight
    GROUP BY carrid
    HAVING SUM( seatsocc ) > 10000
    ORDER BY carrid.

  SKIP.
  WRITE / '=== 2. 已訂座位總數超過 10000 的公司（HAVING） ==='.
  LOOP AT gt_agg INTO gs_agg.
    WRITE: / gs_agg-carrid, gs_agg-cnt, gs_agg-seats.
  ENDLOOP.

*----------------------------------------------------------------------*
* 3. DISTINCT：取不重複值
*----------------------------------------------------------------------*
  SELECT DISTINCT airpfrom
    FROM spfli
    INTO TABLE gt_airp
    ORDER BY airpfrom.

  SKIP.
  WRITE / '=== 3. 有航班起飛的機場（DISTINCT） ==='.
  LOOP AT gt_airp INTO gv_airp.
    WRITE gv_airp.
  ENDLOOP.

  SELECT COUNT( * ) FROM spfli INTO gv_cnt.
  SELECT COUNT( DISTINCT airpfrom ) FROM spfli INTO gv_sum.
  WRITE: / '航線總數', gv_cnt, '／ 不重複的起飛機場數', gv_sum.

*----------------------------------------------------------------------*
* 4. 子查詢：括號裡的 SELECT 先跑，結果拿來當外層的條件
*----------------------------------------------------------------------*
* 4a. IN ( SELECT ... )：有航線從 FRA 起飛的公司
  SELECT carrid FROM scarr
    INTO TABLE gt_carr
    WHERE carrid IN ( SELECT carrid FROM spfli WHERE airpfrom = 'FRA' )
    ORDER BY carrid.

  SKIP.
  WRITE / '=== 4a. 有航線從 FRA 起飛的公司（IN 子查詢） ==='.
  LOOP AT gt_carr INTO gv_carr.
    WRITE gv_carr.
  ENDLOOP.

* 4b. EXISTS：內層可以引用外層的別名（c~carrid），逐列比對
  CLEAR gt_carr.
  SELECT carrid FROM scarr AS c
    INTO TABLE gt_carr
    WHERE EXISTS ( SELECT * FROM spfli
                     WHERE carrid = c~carrid AND airpfrom = 'FRA' )
    ORDER BY carrid.

  SKIP.
  WRITE / '=== 4b. 同上（EXISTS 子查詢，結果應相同） ==='.
  LOOP AT gt_carr INTO gv_carr.
    WRITE gv_carr.
  ENDLOOP.

* 4c. NOT EXISTS：沒有任何航班的公司（LEFT OUTER JOIN 的另一種做法）
  CLEAR gt_carr.
  SELECT carrid FROM scarr AS c
    INTO TABLE gt_carr
    WHERE NOT EXISTS ( SELECT * FROM sflight WHERE carrid = c~carrid )
    ORDER BY carrid.

  SKIP.
  WRITE / '=== 4c. 沒有任何航班的公司（NOT EXISTS） ==='.
  LOOP AT gt_carr INTO gv_carr.
    WRITE gv_carr.
  ENDLOOP.

*----------------------------------------------------------------------*
* 5. 交叉驗證：資料庫算的座位數，要跟「撈明細再自己累加」的結果一致
*----------------------------------------------------------------------*
  CLEAR gt_agg.
  SELECT carrid SUM( seatsocc ) AS seats
    INTO CORRESPONDING FIELDS OF TABLE gt_agg
    FROM sflight
    GROUP BY carrid
    ORDER BY carrid.
  SELECT * FROM sflight INTO TABLE gt_det.

  SKIP.
  WRITE / '=== 5. 交叉驗證（SQL 聚合 vs 內表累加） ==='.
  LOOP AT gt_agg INTO gs_agg.
    CLEAR gv_chk.
    LOOP AT gt_det INTO gs_det WHERE carrid = gs_agg-carrid.
      gv_chk = gv_chk + gs_det-seatsocc.
    ENDLOOP.
    gv_diff = gs_agg-seats - gv_chk.
    WRITE: / gs_agg-carrid, gs_agg-seats, gv_chk, '差異', gv_diff.
    gv_total = gv_total + gs_agg-seats.
  ENDLOOP.

  SELECT SUM( seatsocc ) FROM sflight INTO gv_sum.
  WRITE: / '全部座位數 SUM（不分組）', gv_sum, '／ 各組加總', gv_total.

*----------------------------------------------------------------------*
* 6. 陷阱：沒有 GROUP BY 的聚合，即使沒有符合條件的資料也一定回傳一列
*----------------------------------------------------------------------*
  SELECT COUNT( * ) SUM( seatsocc )
    FROM sflight
    INTO (gv_cnt, gv_sum)
    WHERE carrid = 'ZZ'.

  SKIP.
  WRITE / '=== 6. 查一個不存在的公司（ZZ） ==='.
  WRITE: / 'sy-subrc =', sy-subrc, '／ COUNT =', gv_cnt, '／ SUM =', gv_sum.
  IF gv_cnt = 0.
    WRITE / '→ sy-subrc 是 0，但其實沒有資料：判斷有沒有資料要看 COUNT( * )'.
  ENDIF.