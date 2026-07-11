CLASS zcl_rs01_hello DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cl_rest_resource.

* REST 練習 1：Resource Class——只覆寫 GET，其餘 HTTP 動詞
*   沿用父類別 CL_REST_RESOURCE 的預設實作（回 405 Method Not Allowed）
  PUBLIC SECTION.
    METHODS if_rest_resource~get REDEFINITION.
ENDCLASS.

CLASS zcl_rs01_hello IMPLEMENTATION.
  METHOD if_rest_resource~get.
    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_string_data( |Hello REST! 現在伺服器時間是 { sy-uzeit TIME = ISO }| ).
    lo_entity->set_content_type( if_rest_media_type=>gc_text_plain ).
  ENDMETHOD.
ENDCLASS.
