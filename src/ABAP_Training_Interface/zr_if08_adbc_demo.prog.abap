REPORT zr_if08_adbc_demo.

TYPES: BEGIN OF ty_carrier,
         carrid   TYPE s_carr_id,
         carrname TYPE s_carrname,
       END OF ty_carrier.

START-OF-SELECTION.

  WRITE: / '① ADBC 讀取 SCARR（成功情境，示範 CL_SQL_CONNECTION/CL_SQL_STATEMENT/CL_SQL_RESULT_SET）'.
  ULINE.

  DATA(lo_connection) = cl_sql_connection=>get_connection( ).
  DATA(lo_statement)  = lo_connection->create_statement( ).

  TRY.
      DATA(lo_result) = lo_statement->execute_query(
        |SELECT carrid, carrname FROM scarr WHERE mandt = '{ sy-mandt }' ORDER BY carrid| ).

      DATA ls_carrier TYPE ty_carrier.
      lo_result->set_param_struct( REF #( ls_carrier ) ).

      WHILE lo_result->next( ) > 0.
        WRITE: / ls_carrier-carrid, ls_carrier-carrname.
      ENDWHILE.

      lo_result->close( ).

    CATCH cx_sql_exception INTO DATA(lx_sql_ok).
      WRITE: / '非預期錯誤：', lx_sql_ok->get_text( ).
  ENDTRY.

  SKIP.
  WRITE: / '② 故意查詢不存在的資料表，示範 CX_SQL_EXCEPTION 錯誤處理'.
  ULINE.

  TRY.
      DATA(lo_bad_result) = lo_statement->execute_query(
        |SELECT * FROM ztable_not_exist_9999| ).
      lo_bad_result->close( ).

      WRITE: / '（不應該執行到這裡——上面那句應該要拋例外）'.

    CATCH cx_sql_exception INTO DATA(lx_sql_err).
      WRITE: / '預期中的錯誤，CX_SQL_EXCEPTION 訊息：'.
      WRITE: / lx_sql_err->get_text( ).
  ENDTRY.
