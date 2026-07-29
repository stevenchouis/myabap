CLASS zcl_en05_flight_greeting_fb DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_en05_flight_greeting.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_en05_flight_greeting_fb IMPLEMENTATION.

  METHOD zif_en05_flight_greeting~get_greeting.
    " Fallback 行為：沒有任何 Active Implementation 時，系統只會呼叫這裡一次
    cv_text = |Welcome aboard { iv_carrid }! (fallback greeting, no customer implementation active)|.
  ENDMETHOD.

ENDCLASS.