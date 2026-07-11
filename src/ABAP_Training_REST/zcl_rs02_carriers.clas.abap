CLASS zcl_rs02_carriers DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 2：第二個資源——查 SCARR 回傳純文字清單
*   （JSON 序列化留到 rs03，這題先把「一個 service、多個資源」練熟）
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
ENDCLASS.

CLASS zcl_rs02_carriers IMPLEMENTATION.
  METHOD if_rest_resource~get.
    SELECT carrid, carrname
      FROM scarr
      ORDER BY carrid
      INTO TABLE @DATA(lt_carrier).

    DATA(lv_text) = REDUCE string(
      INIT text = ``
      FOR ls_carrier IN lt_carrier
      NEXT text = text && |{ ls_carrier-carrid }\t{ ls_carrier-carrname }\n| ).

    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_string_data( lv_text ).
    lo_entity->set_content_type( if_rest_media_type=>gc_text_plain ).
  ENDMETHOD.
ENDCLASS.
