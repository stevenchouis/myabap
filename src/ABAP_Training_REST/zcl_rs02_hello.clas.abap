CLASS zcl_rs02_hello DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 2：第一個資源——沿用 rs01 的問候邏輯，這次改由 router 分流過來
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
ENDCLASS.

CLASS zcl_rs02_hello IMPLEMENTATION.
  METHOD if_rest_resource~get.
    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_string_data( |Hello REST! 現在伺服器時間是 { sy-uzeit TIME = ISO }| ).
    lo_entity->set_content_type( if_rest_media_type=>gc_text_plain ).
  ENDMETHOD.
ENDCLASS.
