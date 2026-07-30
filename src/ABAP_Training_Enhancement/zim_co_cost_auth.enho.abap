ENHANCEMENT 1  .
*
    FIELD-SYMBOLS: <fs_werks> TYPE any.
    DATA: lv_werks TYPE werks_d.

    ASSIGN ('(SAPLCOKO1)CAUFVD-WERKS') TO <fs_werks>.
    IF <fs_werks> IS ASSIGNED.
      lv_werks = <fs_werks>.
    ENDIF.

    AUTHORITY-CHECK OBJECT 'Z_EN08_COS'
      ID 'ACTVT' FIELD '03'
      ID 'WERKS' FIELD lv_werks.
    IF sy-subrc <> 0.
      MESSAGE e001(zen08) WITH lv_werks.
    ENDIF.
ENDENHANCEMENT.
