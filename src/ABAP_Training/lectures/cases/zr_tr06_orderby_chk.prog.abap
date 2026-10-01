REPORT zr_tr06_orderby_chk.
* 驗證講義 6 §3.5 ORDER BY 的傳統寫法（2026-09-30）

DATA: gt_flights TYPE STANDARD TABLE OF sflight,
      gs_flight  TYPE sflight,
      gt_spfli   TYPE STANDARD TABLE OF spfli,
      gs_spfli   TYPE spfli.

* 1) 單欄遞減＋UP TO：排序後才取前 3 筆
SELECT * FROM sflight
  INTO TABLE gt_flights
  UP TO 3 ROWS
  WHERE carrid = 'LH'
  ORDER BY fldate DESCENDING.
WRITE / '1) LH fldate DESCENDING UP TO 3'.
LOOP AT gt_flights INTO gs_flight.
  WRITE: / gs_flight-carrid, gs_flight-connid, gs_flight-fldate.
ENDLOOP.

* 2) 多欄：carrid 遞增、price 遞減
SELECT * FROM sflight
  INTO TABLE gt_flights
  UP TO 6 ROWS
  WHERE carrid IN ('AA','LH')
  ORDER BY carrid price DESCENDING.
WRITE / '2) carrid ASC, price DESC'.
LOOP AT gt_flights INTO gs_flight.
  WRITE: / gs_flight-carrid, gs_flight-connid, gs_flight-price.
ENDLOOP.

* 3) PRIMARY KEY
SELECT * FROM spfli
  INTO TABLE gt_spfli
  WHERE carrid = 'LH'
  ORDER BY PRIMARY KEY.
WRITE / '3) spfli LH PRIMARY KEY'.
LOOP AT gt_spfli INTO gs_spfli.
  WRITE: / gs_spfli-carrid, gs_spfli-connid.
ENDLOOP.

* 4) SELECT ... ENDSELECT 搭配 ORDER BY，抓第一筆就 EXIT
SELECT * FROM sflight
  INTO gs_flight
  WHERE carrid = 'LH'
    AND fldate <= sy-datum
  ORDER BY fldate DESCENDING.
  EXIT.
ENDSELECT.
WRITE: / '4) latest LH flight not after today:', gs_flight-connid, gs_flight-fldate, sy-subrc.
