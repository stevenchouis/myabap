CLASS zcl_rs05_flights DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 5：Query Parameter 篩選——carrid/connid/fromdate 皆為可選，動態組合 WHERE 條件
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
ENDCLASS.

CLASS zcl_rs05_flights IMPLEMENTATION.
  METHOD if_rest_resource~get.
    DATA(lv_has_carrid)   = mo_request->has_uri_query_parameter( 'carrid' ).
    DATA(lv_has_connid)   = mo_request->has_uri_query_parameter( 'connid' ).
    DATA(lv_has_fromdate) = mo_request->has_uri_query_parameter( 'fromdate' ).

    DATA(lv_carrid) = COND string( WHEN lv_has_carrid = abap_true
                                    THEN mo_request->get_uri_query_parameter( 'carrid' )
                                    ELSE `` ).
    DATA(lv_connid) = COND string( WHEN lv_has_connid = abap_true
                                    THEN mo_request->get_uri_query_parameter( 'connid' )
                                    ELSE `` ).
    DATA(lv_fromdate) = COND dats( WHEN lv_has_fromdate = abap_true
                                    THEN CONV dats( mo_request->get_uri_query_parameter( 'fromdate' ) )
                                    ELSE '00000000' ).

    IF lv_has_carrid = abap_true.
      SELECT SINGLE carrid
        FROM scarr
        WHERE carrid = @lv_carrid
        INTO @DATA(lv_carrid_check).

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_rest_resource_exception
          EXPORTING
            status_code    = cl_rest_status_code=>gc_client_error_not_found
            request_method = if_rest_message=>gc_method_get
            textid         = cx_rest_resource_exception=>resource_not_found.
      ENDIF.
    ENDIF.

    SELECT carrid, connid, fldate, price, currency
      FROM sflight
      WHERE ( carrid = @lv_carrid     OR @lv_has_carrid   = @abap_false )
        AND ( connid = @lv_connid     OR @lv_has_connid   = @abap_false )
        AND ( fldate >= @lv_fromdate  OR @lv_has_fromdate = @abap_false )
      ORDER BY carrid, connid, fldate
      INTO TABLE @DATA(lt_flight)
      UP TO 20 ROWS.

    DATA(lv_json) = /ui2/cl_json=>serialize(
      data        = lt_flight
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_string_data( lv_json ).
    lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
  ENDMETHOD.
ENDCLASS.
