REPORT zr_en04_seed_1011_pp71.

* 登錄 Plant 1011 / Order Type PP71 的自訂編號主檔（FEVOR/ZGRTYPE 皆用 '*' 代表不限）
DELETE FROM zen04_pltauart WHERE werks = '1011' AND auart = 'PP71'.
DELETE FROM zen04_rule     WHERE werks = '1011' AND auart = 'PP71'.
COMMIT WORK.

INSERT zen04_pltauart FROM @( VALUE #(
  mandt = sy-mandt werks = '1011' auart = 'PP71' ) ).

INSERT zen04_rule FROM @( VALUE #(
  mandt    = sy-mandt
  werks    = '1011'
  auart    = 'PP71'
  fevor    = '*'
  zgrtype  = '*'
  leadcode = 'PP'
  stnum    = '0001' ) ).
COMMIT WORK.

WRITE: / 'ZEN04_PLTAUART / ZEN04_RULE 已登錄 Plant 1011 / Order Type PP71（FEVOR=*／ZGRTYPE=*／LEADCODE=PP／STNUM=0001）'.