REPORT zr_en07_section_demo.

DATA: lv_carrid TYPE s_carr_id VALUE 'LH',
      lv_text   TYPE string.

WRITE: / 'EN07 Explicit Enhancement Section demo'.
WRITE: / '=============================================================='.

ENHANCEMENT-SECTION ES_MYTEST SPOTS ZES_EN07_SECTION_V1 .
  " --------------------------------------------------
  " 系統預設會執行的程式碼 (Default Logic)
  " 若未來沒有建立 Implementation，系統就會執行這一段
  " --------------------------------------------------
  DATA: lv_amount TYPE i.
  lv_amount = 100.
  WRITE: / '預設金額:', lv_amount.
END-ENHANCEMENT-SECTION.

*ENHANCEMENT-SECTION es_en07_greeting SPOTS zes_en07_section_v1.
*lv_text = |Standard: greeting for { lv_carrid }|.
*END-ENHANCEMENT-SECTION.

WRITE: / lv_text.
