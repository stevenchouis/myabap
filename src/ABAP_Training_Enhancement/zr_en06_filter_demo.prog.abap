REPORT zr_en06_filter_demo LINE-SIZE 250.

DATA go_badi   TYPE REF TO zes_en06_filter_demo.
DATA lv_carrid TYPE s_carr_id.
DATA lv_text   TYPE string.

WRITE: / 'EN06 Filter-dependent BAdI 驗證'.
WRITE: / '=============================================================='.
WRITE: / ''.

lv_carrid = 'LH'.
lv_text   = 'UNCHANGED'.
GET BADI go_badi
  FILTERS
    carrid = lv_carrid.
CALL BADI go_badi->get_greeting
  EXPORTING
    iv_carrid = lv_carrid
  CHANGING
    cv_text   = lv_text.
WRITE: / 'CARRID=LH  =>'.
WRITE: / lv_text.
WRITE: / ''.

lv_carrid = 'AA'.
lv_text   = 'UNCHANGED'.
GET BADI go_badi
  FILTERS
    carrid = lv_carrid.
CALL BADI go_badi->get_greeting
  EXPORTING
    iv_carrid = lv_carrid
  CHANGING
    cv_text   = lv_text.
WRITE: / 'CARRID=AA  =>'.
WRITE: / lv_text.
WRITE: / ''.

lv_carrid = 'UA'.
lv_text   = 'UNCHANGED'.
GET BADI go_badi
  FILTERS
    carrid = lv_carrid.
CALL BADI go_badi->get_greeting
  EXPORTING
    iv_carrid = lv_carrid
  CHANGING
    cv_text   = lv_text.
WRITE: / 'CARRID=UA (無 Implementation) =>'.
WRITE: / lv_text.
