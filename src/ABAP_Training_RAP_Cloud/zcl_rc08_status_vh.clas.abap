CLASS zcl_rc08_status_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_rc08_status_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA lt_result TYPE STANDARD TABLE OF zi_rc08_status_vh.

    lt_result = VALUE #(
      ( status = 'O' status_text = 'Open' )
      ( status = 'D' status_text = 'Done' )
    ).

    " RAP runtime requires every query capability the caller touches to be acknowledged,
    " even for this small, unpaged/unsorted/unfiltered result set
    io_request->get_paging( )->get_page_size( ).
    io_request->get_paging( )->get_offset( ).
    io_request->get_sort_elements( ).
    TRY.
        io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_result ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_result ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
