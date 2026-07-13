CLASS zcl_rs03_flights DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 3：查 SFLIGHT 回傳 JSON 陣列，改用 /UI2/CL_JSON 序列化
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
ENDCLASS.

CLASS zcl_rs03_flights IMPLEMENTATION.
  METHOD if_rest_resource~get.
    SELECT carrid, connid, fldate, price, currency
      FROM sflight
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
