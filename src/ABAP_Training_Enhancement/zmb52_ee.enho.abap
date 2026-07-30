ENHANCEMENT 1  .
*
  SELECT-OPTIONS: dispo FOR marc-dispo.
ENDENHANCEMENT.
ENHANCEMENT 2  .
*
  DATA: lt_seltexts LIKE rsseltexts OCCURS 0 WITH HEADER LINE.
lt_seltexts-name = 'DISPO'.
lt_seltexts-kind = 'S'.
lt_seltexts-text = 'MRP Controller'.
APPEND lt_seltexts.
CALL FUNCTION 'SELECTION_TEXTS_MODIFY'
  EXPORTING
    program  = sy-repid
  TABLES
    seltexts = lt_seltexts.
ENDENHANCEMENT.
ENHANCEMENT 3  .

    "{ Begin ENHO MGV_LAMA_RM07MLBS LO-MD-MM MGV_LAMA }
    IF cl_immpn_cust=>check_mpn_active( ) = abap_true.
      SELECT mara~matnr, werks, xchar, mtart, matkl, meins, trame, umlmc,
         bwesb, glgmg,                       "AC0K020254  "n912093
       mara~lvorm AS lvorm_mara,
       marc~lvorm AS lvorm_marc,
       /cwm/valum,
       /cwm/xcwmat,
       /cwm/trame,
       /cwm/umlmc,
       /cwm/bwesb
       FROM mara INNER JOIN nsdm_e_marc as marc
       ON mara~matnr = marc~matnr
       FOR ALL ENTRIES IN @matnr
       WHERE mara~matnr = @matnr-low
         AND werks IN @werks
         AND mtart IN @matart
         AND matkl IN @matkla
* Modification for PIC-Supersession/MPN
         AND mfrpn IN @mfrpn
         AND ekgrp IN @ekgrup
* Modification for MRP Controller (EN08)
         AND dispo IN @dispo
       INTO CORRESPONDING FIELDS OF TABLE @t_mat
       CONNECTION (dbcon).                                   "1792036
    ELSE.
      SELECT mara~matnr, werks, xchar, mtart, matkl, meins, trame, umlmc,
             bwesb, glgmg,                       "AC0K020254  "n912093
           mara~lvorm AS lvorm_mara,
           marc~lvorm AS lvorm_marc,
           /cwm/valum,
           /cwm/xcwmat,
           /cwm/trame,
           /cwm/umlmc,
           /cwm/bwesb
           FROM mara INNER JOIN nsdm_e_marc as marc
           ON mara~matnr = marc~matnr
           FOR ALL ENTRIES IN @matnr
           WHERE mara~matnr = @matnr-low
             AND werks IN @werks
             AND mtart IN @matart
             AND matkl IN @matkla
             AND ekgrp IN @ekgrup
* Modification for MRP Controller (EN08)
             AND dispo IN @dispo
           INTO CORRESPONDING FIELDS OF TABLE @t_mat
           CONNECTION (dbcon).                               "1710852
    ENDIF.
    "{ End ENHO MGV_LAMA_RM07MLBS LO-MD-MM MGV_LAMA }

ENDENHANCEMENT.
