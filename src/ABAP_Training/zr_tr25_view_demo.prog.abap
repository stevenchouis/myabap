REPORT zr_tr25_view_demo NO STANDARD PAGE HEADING LINE-SIZE 120.

* 講義 25 §1.1：DDIC View 的四種類型
*   Database View   SFLIGHTS   ：SCARR＋SPFLI＋SFLIGHT 的 INNER JOIN，可以 SELECT
*   Projection View DEMO_SPFLI ：SPFLI 的部分欄位，可以 SELECT
*   Maintenance View V_TCURC   ：TCURC＋TCURT（幣別＋文字），給 SM30 維護用，不能 SELECT
*   Help View       H_T005     ：T005＋T005T（國家＋文字），給 Search Help 用，不能 SELECT
* 四種都能當 TYPE 使用（宣告結構）

DATA: gt_flights  TYPE STANDARD TABLE OF sflights,      " Database View 當列型別
      gs_flight   TYPE sflights,
      gt_spfli    TYPE STANDARD TABLE OF demo_spfli,    " Projection View 當列型別
      gs_currency TYPE v_tcurc,                         " Maintenance View：只能當 TYPE
      gs_country  TYPE h_t005.                          " Help View：只能當 TYPE

START-OF-SELECTION.
* 1. Database View：像讀一張表一樣，JOIN 已經定義在 DDIC 裡
  SELECT carrid carrname connid cityfrom cityto fldate seatsmax seatsocc
    FROM sflights
    INTO CORRESPONDING FIELDS OF TABLE gt_flights
    UP TO 5 ROWS
    WHERE carrid = 'LH'.
  WRITE: / 'SFLIGHTS（Database View）讀到', sy-dbcnt, '筆'.
  LOOP AT gt_flights INTO gs_flight.
    WRITE: / gs_flight-carrid, gs_flight-carrname(20), gs_flight-connid,
             gs_flight-cityfrom(12), gs_flight-cityto(12), gs_flight-fldate,
             gs_flight-seatsocc.
  ENDLOOP.
  SKIP.

* 2. Projection View：只露出部分欄位
  SELECT * FROM demo_spfli
    INTO TABLE gt_spfli
    UP TO 3 ROWS.
  WRITE: / 'DEMO_SPFLI（Projection View）讀到', sy-dbcnt, '筆'.
  SKIP.

* 3. Maintenance View、Help View：只能拿來當型別
  gs_currency-waers = 'TWD'.
  gs_currency-ltext = '新台幣'.
  gs_country-land1  = 'TW'.
  gs_country-landx  = '台灣'.
  WRITE: / 'V_TCURC 當 TYPE：', gs_currency-waers, gs_currency-ltext.
  WRITE: / 'H_T005 當 TYPE：',  gs_country-land1, gs_country-landx.
