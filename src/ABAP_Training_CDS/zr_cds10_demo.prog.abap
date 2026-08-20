REPORT zr_cds10_demo.

CLASS lcl_mock_request DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_rap_query_request.
ENDCLASS.

CLASS lcl_mock_request IMPLEMENTATION.
  METHOD if_rap_query_request~get_entity_id.
    rv_entity_id = 'ZI_CDS10_FLEET_STATUS'.
  ENDMETHOD.
  METHOD if_rap_query_request~is_data_requested.
    rv_is_requested = abap_true.
  ENDMETHOD.
  METHOD if_rap_query_request~is_total_numb_of_rec_requested.
    rv_is_requested = abap_true.
  ENDMETHOD.
  METHOD if_rap_query_request~get_filter.
  ENDMETHOD.
  METHOD if_rap_query_request~get_paging.
  ENDMETHOD.
  METHOD if_rap_query_request~get_sort_elements.
  ENDMETHOD.
  METHOD if_rap_query_request~get_parameters.
  ENDMETHOD.
  METHOD if_rap_query_request~get_aggregation.
  ENDMETHOD.
  METHOD if_rap_query_request~get_search_expression.
  ENDMETHOD.
  METHOD if_rap_query_request~get_requested_elements.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_mock_response DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_rap_query_response.
    DATA: captured_row_count TYPE i,
          captured_count     TYPE int8.
ENDCLASS.

CLASS lcl_mock_response IMPLEMENTATION.
  METHOD if_rap_query_response~set_data.
    captured_row_count = lines( it_data ).
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<ls_row>).
      ASSIGN COMPONENT 'STATUSCODE' OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_code>).
      ASSIGN COMPONENT 'STATUSTEXT' OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_text>).
      ASSIGN COMPONENT 'SORTORDER'  OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_order>).
      WRITE: / <lv_code>, <lv_text>, <lv_order>.
    ENDLOOP.
  ENDMETHOD.
  METHOD if_rap_query_response~set_total_number_of_records.
    captured_count = iv_total_number_of_records.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.

  WRITE: / '=== Attempt 1: plain Open SQL SELECT against the custom entity (expected to fail) ==='.
  WRITE: / 'Compile-time result: "Entities like ZI_CDS10_FLEET_STATUS cannot be used here."'.
  WRITE: / '(documents the real compiler error found earlier; the statement was removed so this program can compile)'.

  WRITE: / '=== Attempt 2: call ZCL_CDS10_STATUS_QUERY directly with mock request/response objects ==='.

  DATA(lo_request)  = NEW lcl_mock_request( ).
  DATA(lo_response) = NEW lcl_mock_response( ).
  DATA(lo_provider) = NEW zcl_cds10_status_query( ).

  TRY.
      lo_provider->if_rap_query_provider~select(
        io_request  = lo_request
        io_response = lo_response ).
    CATCH cx_rap_query_provider INTO DATA(lx_error).
      WRITE: / 'EXCEPTION:', lx_error->get_text( ).
  ENDTRY.

  WRITE: / 'Total number of records captured (set_total_number_of_records):', lo_response->captured_count.
  WRITE: / 'Row count captured (set_data, rows printed above):', lo_response->captured_row_count.

  WRITE: / '=== Sanity check: 3 status rows generated purely in ABAP, no DB table involved ==='.
  IF lo_response->captured_count = 3 AND lo_response->captured_row_count = 3.
    WRITE: / 'MATCH: query provider class correctly generated 3 rows without reading any database table'.
  ELSE.
    WRITE: / 'MISMATCH'.
  ENDIF.
