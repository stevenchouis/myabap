@EndUserText.label : 'EN04 Lead Code Rule Master'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen04_rule {
  key mandt   : abap.clnt not null;
  key werks   : abap.char(4) not null;
  key auart   : abap.char(4) not null;
  key fevor   : abap.char(3) not null;
  key zgrtype : abap.char(10) not null;
  leadcode    : abap.char(2) not null;
  stnum       : abap.numc(4) not null;

}