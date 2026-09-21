@EndUserText.label : 'ALE09 MIRO to AR mapping and safety gate'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zale09_ctrl {
  key mandt : mandt not null;
  key bukrs : bukrs not null;
  key lifnr : lifre not null;
  bukrs_ar  : bukrs;
  kunnr     : kunnr;
  saknr     : saknr;
  blart_ar  : blart;
  test_mode : xfeld;
  active    : xfeld;

}
