*&---------------------------------------------------------------------*
*& Report  ZR_TR11_JOIN_NEW
*& 練習 11：多表 JOIN（答案程式，新式寫法版）
*& 對照 ZR_TR11_JOIN：輸出相同；欄位清單用逗號、宿主變數加 @、
*& INTO TABLE @DATA( ) 行內宣告，不必先定義接收結構
*&---------------------------------------------------------------------*
REPORT zr_tr11_join_new.

TABLES spfli.

SELECT-OPTIONS s_carrid FOR spfli-carrid.

START-OF-SELECTION.
* 新式寫法：欄位用逗號分隔；SELECT-OPTIONS 也是宿主變數，要寫 @s_carrid
* @DATA(gt_routes) 的欄位名稱取自 SELECT 清單（carrid、connid……），不用先寫 TYPES
  SELECT a~carrid, a~connid, a~cityfrom, a~cityto, b~carrname
    FROM spfli AS a
    INNER JOIN scarr AS b ON a~carrid = b~carrid
    WHERE a~carrid IN @s_carrid
    INTO TABLE @DATA(gt_routes).

  IF sy-subrc <> 0.
    WRITE / '查無航線資料！請先執行 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.

  DATA(gv_lines) = lines( gt_routes ).
  WRITE: / '=== INNER JOIN：航線清單（含公司名稱），筆數', gv_lines, '==='.
  LOOP AT gt_routes INTO DATA(gs_route).
    WRITE: / gs_route-carrid, gs_route-connid,
             gs_route-carrname(18), gs_route-cityfrom(12),
             '->', gs_route-cityto(12).
  ENDLOOP.

* LEFT OUTER JOIN：右表沒有對應資料時，右表欄位為初始值
  SELECT a~carrid, a~carrname, b~connid
    FROM scarr AS a
    LEFT OUTER JOIN spfli AS b ON a~carrid = b~carrid
    INTO TABLE @DATA(gt_carr).

  gv_lines = lines( gt_carr ).
  WRITE: / '=== LEFT OUTER JOIN：總筆數', gv_lines, '==='.
  WRITE: / '（比 INNER 多出來的，就是沒有航線的公司）'.
  LOOP AT gt_carr INTO DATA(gs_carr) WHERE connid IS INITIAL.
    WRITE: / gs_carr-carrid, gs_carr-carrname, '（無航線）'.
  ENDLOOP.
  IF sy-subrc <> 0.
    WRITE / '（每家公司都有航線）'.
  ENDIF.
