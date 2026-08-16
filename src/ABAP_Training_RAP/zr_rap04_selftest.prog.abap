REPORT zr_rap04_selftest.

PARAMETERS: p_srvb TYPE string DEFAULT 'ZRAP04_SB' LOWER CASE.

DATA: lo_client TYPE REF TO if_http_client,
      lv_code   TYPE i,
      lv_reason TYPE string,
      lv_body   TYPE string,
      lv_token  TYPE string,
      lv_new_id TYPE string,
      lv_payload TYPE string.

START-OF-SELECTION.

  cl_http_client=>create_by_destination(
    EXPORTING
      destination = 'NONE'
    IMPORTING
      client      = lo_client
    EXCEPTIONS
      OTHERS      = 1 ).

  IF sy-subrc <> 0.
    WRITE: / 'create_by_destination failed, sy-subrc =', sy-subrc.
    RETURN.
  ENDIF.

  " ---------- Part 1: GET Managed entity set (read works even though CUD would Dump) ----------
  lo_client->request->set_header_field( name = '~request_method' value = 'GET' ).
  lo_client->request->set_header_field( name = '~request_uri'
    value = |/sap/opu/odata/sap/{ p_srvb }/TaskManaged?$format=json&$top=5| ).
  lo_client->send( EXCEPTIONS OTHERS = 1 ).
  lo_client->receive( EXCEPTIONS OTHERS = 1 ).
  lo_client->response->get_status( IMPORTING code = lv_code reason = lv_reason ).
  lv_body = lo_client->response->get_cdata( ).
  WRITE: / 'GET TaskManaged (Managed, read-only demo) ->', lv_code, lv_reason.
  WRITE: / substring( val = lv_body len = nmin( val1 = strlen( lv_body ) val2 = 200 ) ).
  SKIP.

  " ---------- Part 2: GET Unmanaged entity set (before create) ----------
  lo_client->request->set_header_field( name = '~request_method' value = 'GET' ).
  lo_client->request->set_header_field( name = '~request_uri'
    value = |/sap/opu/odata/sap/{ p_srvb }/TestUnmanaged?$format=json| ).
  lo_client->send( EXCEPTIONS OTHERS = 1 ).
  lo_client->receive( EXCEPTIONS OTHERS = 1 ).
  lo_client->response->get_status( IMPORTING code = lv_code reason = lv_reason ).
  lv_body = lo_client->response->get_cdata( ).
  WRITE: / 'GET TestUnmanaged (before create) ->', lv_code, lv_reason.
  WRITE: / substring( val = lv_body len = nmin( val1 = strlen( lv_body ) val2 = 200 ) ).
  SKIP.

  " ---------- Part 3: fetch CSRF token (required for any OData write) ----------
  lo_client->request->set_header_field( name = '~request_method' value = 'GET' ).
  lo_client->request->set_header_field( name = '~request_uri'
    value = |/sap/opu/odata/sap/{ p_srvb }/TestUnmanaged| ).
  lo_client->request->set_header_field( name = 'X-CSRF-Token' value = 'Fetch' ).
  lo_client->send( EXCEPTIONS OTHERS = 1 ).
  lo_client->receive( EXCEPTIONS OTHERS = 1 ).
  lv_token = lo_client->response->get_header_field( name = 'x-csrf-token' ).
  WRITE: / 'CSRF token fetched:', lv_token.
  SKIP.

  " ---------- Part 4: real end-to-end Create via OData (Unmanaged path, should succeed) ----------
  lv_new_id = |SELF{ sy-uzeit }|.
  lv_payload = |\{ "id":"{ lv_new_id }", "descr":"Self Test via OData" \}|.

  lo_client->request->set_header_field( name = '~request_method' value = 'POST' ).
  lo_client->request->set_header_field( name = '~request_uri'
    value = |/sap/opu/odata/sap/{ p_srvb }/TestUnmanaged| ).
  lo_client->request->set_header_field( name = 'X-CSRF-Token' value = lv_token ).
  lo_client->request->set_header_field( name = 'Content-Type' value = 'application/json' ).
  lo_client->request->set_cdata( lv_payload ).
  lo_client->send( EXCEPTIONS OTHERS = 1 ).
  lo_client->receive( EXCEPTIONS OTHERS = 1 ).
  lo_client->response->get_status( IMPORTING code = lv_code reason = lv_reason ).
  lv_body = lo_client->response->get_cdata( ).
  WRITE: / 'POST TestUnmanaged Create (id =', lv_new_id, ') ->', lv_code, lv_reason.
  WRITE: / substring( val = lv_body len = nmin( val1 = strlen( lv_body ) val2 = 200 ) ).
  SKIP.

  lo_client->close( ).

  " ---------- Part 5: verify directly in the database ----------
  SELECT SINGLE id, descr FROM zrap03_umtest WHERE id = @lv_new_id INTO @DATA(ls_check).
  IF sy-subrc = 0.
    WRITE: / 'DB check OK, id =', ls_check-id, 'descr =', ls_check-descr.
  ELSE.
    WRITE: / 'DB check FAILED for id', lv_new_id.
  ENDIF.
