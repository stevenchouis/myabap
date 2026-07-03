*&---------------------------------------------------------------------*
*& Report  ZR_TR11_JOIN
*& 練習 11：多表 JOIN（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr11_join.

* TABLES：宣告後 SELECT-OPTIONS 才能 FOR <db表-欄位>
* （畫面會自動帶出欄位說明與 F4 值幫助——比 FOR 自訂變數好用）
TABLES spfli.

* 自訂結構：欄位「名稱」跟資料庫欄位一致，
* 之後 INTO CORRESPONDING FIELDS 才對得起來
TYPES: BEGIN OF ty_route,
         carrid   TYPE spfli-carrid,     " 航空公司代碼
         connid   TYPE spfli-connid,     " 航線編號
         cityfrom TYPE spfli-cityfrom,   " 出發城市
         cityto   TYPE spfli-cityto,     " 目的城市
         carrname TYPE scarr-carrname,   " 航空公司名稱（來自另一張表）
       END OF ty_route.

TYPES: BEGIN OF ty_carr_route,
         carrid   TYPE scarr-carrid,
         carrname TYPE scarr-carrname,
         connid   TYPE spfli-connid,
       END OF ty_carr_route.

DATA: gt_routes TYPE STANDARD TABLE OF ty_route,
      gs_route  TYPE ty_route,
      gt_carr   TYPE STANDARD TABLE OF ty_carr_route,
      gs_carr   TYPE ty_carr_route,
      gv_lines  TYPE i.

SELECT-OPTIONS s_carrid FOR spfli-carrid.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* INNER JOIN：兩張表「都有」的資料才會出現
*   別名：spfli AS a、scarr AS b，欄位用 a~carrid 指明來源
*   ON：兩表的關聯條件
*   INTO CORRESPONDING FIELDS OF TABLE：依「欄位名相同」自動對應
*----------------------------------------------------------------------*
  SELECT a~carrid, a~connid, a~cityfrom, a~cityto, b~carrname
    INTO CORRESPONDING FIELDS OF TABLE @gt_routes
    FROM spfli AS a
    INNER JOIN scarr AS b ON a~carrid = b~carrid
    WHERE a~carrid IN @s_carrid.

  IF sy-subrc <> 0.
    WRITE / '查無航線資料！請先執行 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.

  gv_lines = lines( gt_routes ).
  WRITE: / '=== INNER JOIN：航線清單（含公司名稱），筆數', gv_lines, '==='.
  LOOP AT gt_routes INTO gs_route.
    WRITE: / gs_route-carrid, gs_route-connid,
             gs_route-carrname(18), gs_route-cityfrom(12),
             '->', gs_route-cityto(12).
  ENDLOOP.

*----------------------------------------------------------------------*
* LEFT OUTER JOIN：左表（SCARR）全保留，
* 右表（SPFLI）沒有對應資料時，右表欄位為初始值（空白）
* 用途：找出「沒有開航線的航空公司」這類「左有右無」的需求
*----------------------------------------------------------------------*
  SELECT a~carrid, a~carrname, b~connid
    INTO CORRESPONDING FIELDS OF TABLE @gt_carr
    FROM scarr AS a
    LEFT OUTER JOIN spfli AS b ON a~carrid = b~carrid.

  gv_lines = lines( gt_carr ).
  WRITE: / '=== LEFT OUTER JOIN：總筆數', gv_lines, '==='.
  WRITE: / '（比 INNER 多出來的，就是沒有航線的公司）'.
  LOOP AT gt_carr INTO gs_carr WHERE connid IS INITIAL.
    WRITE: / gs_carr-carrid, gs_carr-carrname, '（無航線）'.
  ENDLOOP.
  IF sy-subrc <> 0.
    WRITE / '（每家公司都有航線）'.
  ENDIF.