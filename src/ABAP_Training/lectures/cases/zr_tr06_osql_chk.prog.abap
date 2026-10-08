REPORT zr_tr06_osql_chk LINE-SIZE 150.
* 驗證 Open SQL 7.40 之後的功能（2026-10-08，本系統 7.54）

START-OF-SELECTION.

* 1) SELECT 清單裡做運算、放字面值
  SELECT carrid, connid, fldate, price, seatsocc,
         price * seatsocc AS revenue,
         'X' AS flag
    FROM sflight
    WHERE carrid = 'LH'
    ORDER BY fldate
    INTO TABLE @DATA(gt_1)
    UP TO 2 ROWS.
  LOOP AT gt_1 INTO DATA(gs_1).
    WRITE: / '1)', gs_1-carrid, gs_1-connid, gs_1-price, gs_1-seatsocc, gs_1-revenue, gs_1-flag.
  ENDLOOP.

* 2) 字串函式
  SELECT carrid, connid,
         concat( carrid, connid ) AS code,
         substring( cityfrom, 1, 3 ) AS from3,
         length( cityfrom ) AS len,
         upper( cityto ) AS to_up
    FROM spfli
    WHERE carrid = 'LH'
    ORDER BY connid
    INTO TABLE @DATA(gt_2)
    UP TO 2 ROWS.
  LOOP AT gt_2 INTO DATA(gs_2).
    WRITE: / '2)', gs_2-code, gs_2-from3, gs_2-len, gs_2-to_up.
  ENDLOOP.

* 3) CASE（搜尋式與簡單式）
  SELECT carrid, connid, price,
         CASE WHEN price < 500  THEN 'LOW'
              WHEN price < 1000 THEN 'MID'
              ELSE 'HIGH' END AS level,
         CASE carrid WHEN 'LH' THEN 'Lufthansa' ELSE 'Other' END AS name
    FROM sflight
    WHERE carrid = 'LH'
    ORDER BY price
    INTO TABLE @DATA(gt_3)
    UP TO 2 ROWS.
  LOOP AT gt_3 INTO DATA(gs_3).
    WRITE: / '3)', gs_3-carrid, gs_3-price, gs_3-level, gs_3-name.
  ENDLOOP.

* 4) COALESCE + LEFT OUTER JOIN：沒對到的右表欄位換成預設值
  SELECT a~carrid, coalesce( b~connid, '----' ) AS connid
    FROM scarr AS a
    LEFT OUTER JOIN spfli AS b ON a~carrid = b~carrid
    WHERE a~carrid IN ( 'AB', 'LH' )
    ORDER BY a~carrid, connid
    INTO TABLE @DATA(gt_4).
  LOOP AT gt_4 INTO DATA(gs_4).
    WRITE: / '4)', gs_4-carrid, gs_4-connid.
  ENDLOOP.

* 5) CAST
  SELECT carrid, connid, CAST( seatsocc AS DEC( 15, 2 ) ) AS seats_dec
    FROM sflight
    WHERE carrid = 'LH'
    INTO TABLE @DATA(gt_5)
    UP TO 1 ROWS.
  LOOP AT gt_5 INTO DATA(gs_5).
    WRITE: / '5)', gs_5-carrid, gs_5-seats_dec.
  ENDLOOP.

* 6) LEFT OUTER JOIN 的 WHERE 引用右表欄位
  SELECT a~carrid, b~connid
    FROM scarr AS a
    LEFT OUTER JOIN spfli AS b ON a~carrid = b~carrid
    WHERE b~cityfrom = 'FRANKFURT'
    ORDER BY a~carrid, b~connid
    INTO TABLE @DATA(gt_6).
  WRITE: / '6) LEFT JOIN WHERE right field, lines =', lines( gt_6 ).

* 7) UNION：兩個 SELECT 的結果合併
  SELECT carrid, connid FROM spfli WHERE cityfrom = 'FRANKFURT'
  UNION
  SELECT carrid, connid FROM spfli WHERE cityto = 'FRANKFURT'
    INTO TABLE @DATA(gt_7).
  WRITE: / '7) UNION lines =', lines( gt_7 ).

* 8) FOR ALL ENTRIES 新寫法
  SELECT carrid, connid FROM spfli WHERE carrid = 'LH' INTO TABLE @DATA(gt_keys).
  IF gt_keys IS NOT INITIAL.
    SELECT carrid, connid, fldate
      FROM sflight
      FOR ALL ENTRIES IN @gt_keys
      WHERE carrid = @gt_keys-carrid AND connid = @gt_keys-connid
      INTO TABLE @DATA(gt_8).
    WRITE: / '8) FOR ALL ENTRIES lines =', lines( gt_8 ).
  ENDIF.

* 9) WITH（CTE）
  WITH +lh AS ( SELECT carrid, connid, seatsocc FROM sflight WHERE carrid = 'LH' )
  SELECT connid, SUM( seatsocc ) AS seats
    FROM +lh
    GROUP BY connid
    ORDER BY connid
    INTO TABLE @DATA(gt_9).
  WRITE: / '9) CTE lines =', lines( gt_9 ).

* 10) SELECT FROM @itab
  SELECT carrid, connid FROM @gt_keys AS k
    WHERE connid > '0400'
    INTO TABLE @DATA(gt_10).
  WRITE: / '10) FROM @itab lines =', lines( gt_10 ).

* 11) UP TO n ROWS OFFSET m
  SELECT carrid, connid FROM spfli
    ORDER BY carrid, connid
    INTO TABLE @DATA(gt_11)
    UP TO 3 ROWS OFFSET 2.
  LOOP AT gt_11 INTO DATA(gs_11).
    WRITE: / '11)', gs_11-carrid, gs_11-connid.
  ENDLOOP.

* 12) 視窗函數 OVER
  SELECT carrid, connid, fldate, seatsocc,
         SUM( seatsocc ) OVER( PARTITION BY carrid ) AS carr_total
    FROM sflight
    WHERE carrid = 'LH'
    ORDER BY fldate
    INTO TABLE @DATA(gt_12)
    UP TO 2 ROWS.
  LOOP AT gt_12 INTO DATA(gs_12).
    WRITE: / '12)', gs_12-carrid, gs_12-connid, gs_12-seatsocc, gs_12-carr_total.
  ENDLOOP.
