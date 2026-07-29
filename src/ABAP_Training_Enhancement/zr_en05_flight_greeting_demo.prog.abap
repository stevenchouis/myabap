REPORT zr_en05_flight_greeting_demo LINE-SIZE 250.

DATA go_badi TYPE REF TO zes_en05_greeting.
DATA lv_text TYPE string.

WRITE: / 'EN05 Enhancement Spot / BAdI Definition + Fallback Class 驗證'.
WRITE: / '=============================================================='.
WRITE: / ''.

GET BADI go_badi.

CLEAR lv_text.
CALL BADI go_badi->get_greeting
  EXPORTING
    iv_carrid = 'LH'
  CHANGING
    cv_text   = lv_text.
WRITE: / 'CARRID=LH  =>'.
WRITE: / lv_text.
WRITE: / ''.

CLEAR lv_text.
CALL BADI go_badi->get_greeting
  EXPORTING
    iv_carrid = 'AA'
  CHANGING
    cv_text   = lv_text.
WRITE: / 'CARRID=AA  =>'.
WRITE: / lv_text.