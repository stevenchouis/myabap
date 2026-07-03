*&---------------------------------------------------------------------*
*& Include          ZR_TR14_TOP
*& 全域宣告：TYPES / DATA / 選擇畫面（報表的「資料面」都集中在這）
*&---------------------------------------------------------------------*
TABLES sflight.

TYPES: BEGIN OF ty_rev,
         carrid   TYPE sflight-carrid,     " 航空公司
         connid   TYPE sflight-connid,     " 航線
         fldate   TYPE sflight-fldate,     " 航班日期
         seatsocc TYPE sflight-seatsocc,   " 已售座位
         price    TYPE sflight-price,      " 票價
         currency TYPE sflight-currency,   " 幣別
         revenue  TYPE p LENGTH 12 DECIMALS 2,   " 營收
       END OF ty_rev.

DATA: gt_rev   TYPE STANDARD TABLE OF ty_rev,
      gs_rev   TYPE ty_rev,
      gv_count TYPE i.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
  SELECT-OPTIONS: s_carrid FOR sflight-carrid,
                  s_fldate FOR sflight-fldate.
SELECTION-SCREEN END OF BLOCK b1.