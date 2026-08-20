CLASS zcl_cds10_status_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cds10_status_query IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    TYPES: BEGIN OF ty_status,
             statuscode TYPE c LENGTH 10,
             statustext TYPE c LENGTH 40,
             sortorder  TYPE i,
           END OF ty_status.
    DATA lt_data TYPE STANDARD TABLE OF ty_status WITH EMPTY KEY.

    " No data comes from any database table - it is generated purely in ABAP.
    lt_data = VALUE #(
      ( statuscode = 'ACTIVE'      statustext = 'Aircraft in active service'        sortorder = 1 )
      ( statuscode = 'MAINTENANCE' statustext = 'Aircraft undergoing maintenance'   sortorder = 2 )
      ( statuscode = 'RETIRED'     statustext = 'Aircraft retired from service'     sortorder = 3 )
    ).

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_data ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_data ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
