class ZCL_RAP10_RESOURCE definition
  public
  inheriting from CL_REST_RESOURCE
  final
  create public .

public section.

  class-methods HANDLE_REQUEST
    importing
      !IV_JSON_IN type STRING
    returning
      value(RV_JSON_OUT) type STRING .
  methods IF_REST_RESOURCE~POST
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_RAP10_RESOURCE IMPLEMENTATION.

  METHOD handle_request.
    " Same JSON contract as the production Classic REST interface (ZCL_QM_05_RESOURCE) -
    " this class only differs in HOW it routes to the business logic: via a RAP Action
    " (EML) instead of a direct class-method call. ZCL_QM_05_SERVICE is still the one
    " and only place the six checks / posting / logging logic lives.
    DATA: ls_inbound  TYPE zsqm005_inbound,
          ls_envelope TYPE zsqm005_inbound.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json        = iv_json_in
                    pretty_name = /ui2/cl_json=>pretty_mode-none
          CHANGING  data        = ls_inbound ).
      CATCH cx_root INTO DATA(lx_parse_error).
        rv_json_out = |Invalid JSON request body: { lx_parse_error->get_text( ) }|.
        RETURN.
    ENDTRY.

    MODIFY ENTITIES OF zi_rap10_log
      ENTITY Log
      EXECUTE SubmitWhmsRequest
      FROM VALUE #( ( %cid   = 'C1'
                       %param = ls_inbound-request ) )
      RESULT DATA(lt_result)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    COMMIT ENTITIES.

    DATA: BEGIN OF ls_out,
            response TYPE ztt_qm005_outbound,
          END OF ls_out.
    ls_out-response = VALUE #( FOR ls_res IN lt_result ( ls_res-%param ) ).

    rv_json_out = /ui2/cl_json=>serialize(
      data        = ls_out
      pretty_name = /ui2/cl_json=>pretty_mode-none
      compress    = abap_true ).
  ENDMETHOD.


  METHOD if_rest_resource~post.
    DATA: lv_json_in  TYPE string,
          lv_json_out TYPE string,
          lo_entity   TYPE REF TO if_rest_entity.

    lv_json_in = io_entity->get_string_data( ).

    lv_json_out = handle_request( lv_json_in ).

    lo_entity = mo_response->create_entity( ).
    lo_entity->set_content_type( 'application/json' ).
    lo_entity->set_string_data( lv_json_out ).
    mo_response->set_status( cl_rest_status_code=>gc_success_ok ).
  ENDMETHOD.

ENDCLASS.
