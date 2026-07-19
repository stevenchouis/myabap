CLASS zcl_am08_revenue_classic DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_revenue,
        carrid   TYPE s_carr_id,
        carrname TYPE s_carrname,
        connid   TYPE s_conn_id,
        fldate   TYPE s_date,
        seatsocc TYPE s_seatsocc,
        price    TYPE s_price,
        currency TYPE s_currcode,
        revenue  TYPE p LENGTH 8 DECIMALS 2,
      END OF ty_revenue,
      tt_revenue TYPE STANDARD TABLE OF ty_revenue WITH EMPTY KEY.

    CLASS-METHODS get_revenues
      IMPORTING
        iv_carrid         TYPE s_carr_id
        iv_skip_unsold    TYPE abap_bool
      RETURNING
        VALUE(rt_revenue) TYPE tt_revenue.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_am08_revenue_classic IMPLEMENTATION.

  METHOD get_revenues.
    " 1. 取數：SFLIGHT INNER JOIN SCARR（跟 am08 的 AMDP 版本查同一份資料）
    SELECT f~carrid, c~carrname, f~connid, f~fldate, f~seatsocc, f~price, f~currency
      FROM sflight AS f
      INNER JOIN scarr AS c ON c~carrid = f~carrid
      WHERE f~carrid = @iv_carrid
      ORDER BY f~connid, f~fldate
      INTO CORRESPONDING FIELDS OF TABLE @rt_revenue.

    " 2. 篩選：不想看未售出（seatsocc = 0）的航班就刪掉
    IF iv_skip_unsold = abap_true.
      DELETE rt_revenue WHERE seatsocc = 0.
    ENDIF.

    " 3. 計算：逐筆算營收，這段迴圈就是這題要拿去跟 AMDP 版本對照的核心
    LOOP AT rt_revenue ASSIGNING FIELD-SYMBOL(<ls_revenue>).
      <ls_revenue>-revenue = <ls_revenue>-price * <ls_revenue>-seatsocc.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
