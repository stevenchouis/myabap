*&---------------------------------------------------------------------*
*& Report  ZR_TR20_CONTROL_BREAK
*& 練習 20：Control Break 群組小計（答案程式）
*&---------------------------------------------------------------------*
REPORT zr_tr20_control_break.

* 鐵則二：群組欄位（carrid + 一對一的 carrname）放結構最前面
TYPES: BEGIN OF ty_rev,
         carrid   TYPE sflight-carrid,
         carrname TYPE scarr-carrname,
         connid   TYPE sflight-connid,
         fldate   TYPE sflight-fldate,
         seatsocc TYPE sflight-seatsocc,
         price    TYPE sflight-price,
         revenue  TYPE p LENGTH 12 DECIMALS 2,
       END OF ty_rev.

DATA: gt_rev TYPE STANDARD TABLE OF ty_rev,
      gs_rev TYPE ty_rev.

START-OF-SELECTION.
  SELECT f~carrid c~carrname f~connid f~fldate
         f~seatsocc f~price
    INTO CORRESPONDING FIELDS OF TABLE gt_rev
    FROM sflight AS f
    INNER JOIN scarr AS c ON f~carrid = c~carrid.
  IF sy-subrc <> 0.
    WRITE / '查無資料！請先執行 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.

* 算營收：就地修改用 ASSIGNING（講義 16）
  LOOP AT gt_rev ASSIGNING FIELD-SYMBOL(<ls_rev>).
    <ls_rev>-revenue = <ls_rev>-price * <ls_rev>-seatsocc.
  ENDLOOP.

* 鐵則一：Control Break 之前必先依群組欄位排序
  SORT gt_rev BY carrid connid fldate.

*----------------------------------------------------------------------*
* Control Break：AT 區塊只能用在 LOOP ... INTO
*----------------------------------------------------------------------*
  LOOP AT gt_rev INTO gs_rev.

    AT FIRST.
      WRITE / '=== 航班營收（依公司小計） ==='.
    ENDAT.

*   組頭：用 carrname 當斷點（觸發條件＝carrname 及其左邊的 carrid
*   任一變動，效果同 AT NEW carrid），carrid/carrname 兩欄都看得到；
*   若用 AT NEW carrid，carrname 在區塊內會被遮成 '*'
    AT NEW carrname.
      WRITE: / gs_rev-carrid, gs_rev-carrname.
    ENDAT.

    WRITE: /5 gs_rev-connid, gs_rev-fldate,
              gs_rev-seatsocc, gs_rev-revenue.

    AT END OF carrid.
      SUM.                       " 該公司所有數值欄加總進 gs_rev
      WRITE: /5 '小計', 20 gs_rev-seatsocc, gs_rev-revenue.
*     注意：SUM 把 price 也總了——單價合計無意義，不要印
      ULINE.
    ENDAT.

    AT LAST.
      SUM.                       " 全部資料加總
      WRITE: / '總計', 20 gs_rev-seatsocc, gs_rev-revenue.
    ENDAT.

  ENDLOOP.
