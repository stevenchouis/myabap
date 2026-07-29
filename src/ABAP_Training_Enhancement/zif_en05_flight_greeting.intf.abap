INTERFACE zif_en05_flight_greeting
  PUBLIC.

  INTERFACES if_badi_interface.

  METHODS get_greeting
    IMPORTING
      iv_carrid TYPE s_carr_id
    CHANGING
      cv_text   TYPE string.

ENDINTERFACE.