*&---------------------------------------------------------------------*
*& Report  ZR_TR20_CONTROL_BREAK_NEW
*& 練習 20：群組小計（答案程式，新式寫法版）
*& 對照 ZR_TR20_CONTROL_BREAK：輸出相同；AT NEW／AT END OF／SUM 改用
*& LOOP AT ... GROUP BY，小計自己用 REDUCE 算
*&---------------------------------------------------------------------*
REPORT zr_tr20_control_break_new.

TYPES: BEGIN OF ty_rev,
         carrid   TYPE sflight-carrid,
         carrname TYPE scarr-carrname,
         connid   TYPE sflight-connid,
         fldate   TYPE sflight-fldate,
         seatsocc TYPE sflight-seatsocc,
         price    TYPE sflight-price,
         revenue  TYPE p LENGTH 12 DECIMALS 2,
       END OF ty_rev.

TYPES ty_amount TYPE p LENGTH 12 DECIMALS 2.

DATA: gt_rev       TYPE STANDARD TABLE OF ty_rev,
      gv_seats     TYPE sflight-seatsocc,         " 小計：跟明細欄位同型別，輸出格式才一致
      gv_revenue   TYPE ty_amount,
      gv_tot_seats TYPE sflight-seatsocc,
      gv_tot_rev   TYPE ty_amount.

START-OF-SELECTION.
  SELECT f~carrid, c~carrname, f~connid, f~fldate, f~seatsocc, f~price
    FROM sflight AS f
    INNER JOIN scarr AS c ON f~carrid = c~carrid
    INTO CORRESPONDING FIELDS OF TABLE @gt_rev.
  IF sy-subrc <> 0.
    WRITE / '查無資料！請先執行 SAPBC_DATA_GENERATOR'.
    RETURN.
  ENDIF.

  LOOP AT gt_rev ASSIGNING FIELD-SYMBOL(<ls_rev>).
    <ls_rev>-revenue = <ls_rev>-price * <ls_rev>-seatsocc.
  ENDLOOP.

  SORT gt_rev BY carrid connid fldate.

  WRITE / '=== 航班營收（依公司小計） ==='.

* GROUP BY ( 群組鍵 )：同一組的列被歸在一起，外層 LOOP 每組只跑一次
* gs_grp 是群組本身，可以讀群組鍵（gs_grp-carrid、gs_grp-carrname）
  LOOP AT gt_rev INTO DATA(gs_rev)
       GROUP BY ( carrid = gs_rev-carrid carrname = gs_rev-carrname )
       INTO DATA(gs_grp).

    WRITE: / gs_grp-carrid, gs_grp-carrname.               " 組頭

*   LOOP AT GROUP：逐筆讀這一組的成員
    LOOP AT GROUP gs_grp INTO DATA(gs_mem).
      WRITE: /5 gs_mem-connid, gs_mem-fldate,
                gs_mem-seatsocc, gs_mem-revenue.
    ENDLOOP.

*   小計：沒有 SUM，自己用 REDUCE 對這一組加總（只加要的欄位）
    gv_seats   = REDUCE i( INIT s = 0 FOR m IN GROUP gs_grp NEXT s = s + m-seatsocc ).
*   INIT r TYPE ty_amount：累加變數要是金額型別；寫 INIT r = 0 會變成整數 i，小數被截掉
    gv_revenue = REDUCE ty_amount( INIT r TYPE ty_amount
                                   FOR m IN GROUP gs_grp NEXT r = r + m-revenue ).
    WRITE: /5 '小計', 20 gv_seats, gv_revenue.
    ULINE.

    gv_tot_seats = gv_tot_seats + gv_seats.
    gv_tot_rev   = gv_tot_rev + gv_revenue.
  ENDLOOP.

  WRITE: / '總計', 20 gv_tot_seats, gv_tot_rev.
