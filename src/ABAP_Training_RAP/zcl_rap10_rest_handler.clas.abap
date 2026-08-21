class ZCL_RAP10_REST_HANDLER definition
  public
  inheriting from CL_REST_HTTP_HANDLER
  final
  create public .

public section.

  methods IF_REST_APPLICATION~GET_ROOT_HANDLER
    redefinition .
protected section.

  methods HANDLE_CSRF_TOKEN
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_RAP10_REST_HANDLER IMPLEMENTATION.

  method IF_REST_APPLICATION~GET_ROOT_HANDLER.
    ro_root_handler = NEW zcl_rap10_resource( ).
  endmethod.

  METHOD handle_csrf_token.
  ENDMETHOD.

ENDCLASS.
