REPORT zr_en07_explicit_demo.

DATA: lv_carrid TYPE s_carr_id VALUE 'LH',
      lv_text   TYPE string.

lv_text = |Standard: processing carrier { lv_carrid }|.
WRITE: / lv_text.

ENHANCEMENT-POINT EP_EN07_AFTER_INIT SPOTS ZES_EN07_V3 .


WRITE: / lv_text.