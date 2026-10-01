REPORT zr_tr20_sum_chk.
* 驗證講義 20 §3：AT END OF 進出時 work area 的變化（2026-09-30）

TYPES: BEGIN OF ty_rev,
         carrid   TYPE sflight-carrid,
         carrname TYPE scarr-carrname,
         connid   TYPE sflight-connid,
         seatsocc TYPE sflight-seatsocc,
       END OF ty_rev.

DATA: gt_rev TYPE STANDARD TABLE OF ty_rev,
      gs_rev TYPE ty_rev.

gs_rev-carrid = 'AA'. gs_rev-carrname = 'American'. gs_rev-connid = '0017'. gs_rev-seatsocc = 10.
APPEND gs_rev TO gt_rev.
gs_rev-connid = '0064'. gs_rev-seatsocc = 20.
APPEND gs_rev TO gt_rev.
gs_rev-carrid = 'LH'. gs_rev-carrname = 'Lufthansa'. gs_rev-connid = '0400'. gs_rev-seatsocc = 5.
APPEND gs_rev TO gt_rev.

LOOP AT gt_rev INTO gs_rev.
  WRITE: / '1 before AT :', gs_rev-carrid, gs_rev-carrname, gs_rev-connid, gs_rev-seatsocc.
  AT END OF carrid.
    WRITE: / '2 enter AT  :', gs_rev-carrid, gs_rev-carrname, gs_rev-connid, gs_rev-seatsocc.
    SUM.
    WRITE: / '3 after SUM :', gs_rev-carrid, gs_rev-carrname, gs_rev-connid, gs_rev-seatsocc.
  ENDAT.
  WRITE: / '4 after END :', gs_rev-carrid, gs_rev-carrname, gs_rev-connid, gs_rev-seatsocc.
ENDLOOP.
