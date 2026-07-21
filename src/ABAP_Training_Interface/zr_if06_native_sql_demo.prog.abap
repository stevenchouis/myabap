REPORT zr_if06_native_sql_demo.

PARAMETERS p_carrid TYPE spfli-carrid DEFAULT 'LH'.

START-OF-SELECTION.

  WRITE: / 'Open SQL 版本（框架自動加上 WHERE mandt = sy-mandt，不用自己寫）'.
  ULINE.

  SELECT connid, cityfrom, cityto
    FROM spfli
    WHERE carrid = @p_carrid
    ORDER BY connid
    INTO TABLE @DATA(lt_open).

  LOOP AT lt_open INTO DATA(ls_open).
    WRITE: / ls_open-connid, ls_open-cityfrom, ls_open-cityto.
  ENDLOOP.

  SKIP.
  WRITE: / 'Native SQL 版本（要自己明寫 WHERE mandt = :sy-mandt，否則會撈到所有 Client 的資料）'.
  ULINE.

  DATA: lv_connid   TYPE spfli-connid,
        lv_cityfrom TYPE spfli-cityfrom,
        lv_cityto   TYPE spfli-cityto,
        lv_carrid   TYPE spfli-carrid.

  lv_carrid = p_carrid.

  EXEC SQL.
    OPEN dbcur FOR
      SELECT connid, cityfrom, cityto
      FROM spfli
      WHERE mandt = :sy-mandt AND
            carrid = :lv_carrid
  ENDEXEC.

  DO.
    EXEC SQL.
      FETCH NEXT dbcur INTO :lv_connid, :lv_cityfrom, :lv_cityto
    ENDEXEC.
    IF sy-subrc <> 0.
      EXIT.
    ELSE.
      WRITE: / lv_connid, lv_cityfrom, lv_cityto.
    ENDIF.
  ENDDO.

  EXEC SQL.
    CLOSE dbcur
  ENDEXEC.

  SKIP.
  WRITE: / '兩段輸出的資料應該完全一致——Native SQL 只是自己手動做了 Open SQL 框架幫忙做的 Client 過濾'.
