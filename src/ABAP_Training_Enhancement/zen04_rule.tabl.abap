@EndUserText.label : 'EN04 Lead Code Rule Master'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen04_rule {
  key mandt   : mandt not null;
  key werks   : werks_d not null;
  key auart   : aufart not null;
  key fevor   : fevor not null;
  key zgrtype : zen04_zgrtype not null;
  leadcode    : zen04_leadcod not null;
  stnum       : zen04_stnum not null;

}