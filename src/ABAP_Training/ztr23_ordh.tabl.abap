@EndUserText.label : 'Training ex23: order header'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table ztr23_ordh {
  key mandt : mandt not null;
  key ordno : ztr23_ordno not null;
  customer  : ztr23_customer;
  orddate   : abap.dats;
  status    : ztr23_status;
  upduser   : syuname;
  upddate   : sydatum;

}
