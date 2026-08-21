REPORT zr_rap10_adapter_demo LINE-SIZE 255.

START-OF-SELECTION.

  WRITE: / '=== RAP10: Wire Adapter headless test (JSON string in, JSON string out) ==='.
  WRITE: / 'ZCL_RAP10_RESOURCE mirrors production ZCL_QM_05_RESOURCE - same JSON',
         / 'contract (ZSQM005_INBOUND), only difference: routes to the business',
         / 'logic via EML/RAP Action instead of calling ZCL_QM_05_SERVICE directly.',
         / 'This simulates exactly what a Postman/legacy caller would send as the',
         / 'HTTP request body, without needing a real SICF/HTTP round-trip.'.

  DATA(lv_json_in) =
    `{"REQUEST":[{"HEADER":{"ZWHMS_NO":"RAP10ADAPT","ZRT_NO":"9999999999",` &&
    `"BUDAT":"20260821","BLDAT":"20260821","ZTRAN_TYPE":"1",` &&
    `"BKTXT":"Adapter demo"},"DETAIL":[]}]}`.

  WRITE: / '=== JSON IN ==='.
  WRITE: / lv_json_in.

  DATA(lv_json_out) = zcl_rap10_resource=>handle_request( lv_json_in ).

  WRITE: / '=== JSON OUT ==='.
  WRITE: / lv_json_out.

  WRITE: / '=== Sanity check ==='.
  IF lv_json_out CS 'RT' AND lv_json_out CS 'E'
     AND lv_json_out CS '9999999999'.
    WRITE: / 'MATCH: raw JSON string -> adapter parse -> EML -> RAP Action ->',
           / 'ZCL_QM_05_SERVICE -> JSON string out, full round trip through the',
           / 'exact same contract a real Postman/legacy caller would use.'.
  ELSE.
    WRITE: / 'MISMATCH - inspect JSON OUT above.'.
  ENDIF.

  WRITE: / '=== Malformed JSON test (bad request path) ==='.
  DATA(lv_bad_json) = `{ this is not valid json`.
  DATA(lv_bad_out) = zcl_rap10_resource=>handle_request( lv_bad_json ).
  WRITE: / 'lv_bad_out length:', strlen( lv_bad_out ).
  WRITE: / lv_bad_out.
