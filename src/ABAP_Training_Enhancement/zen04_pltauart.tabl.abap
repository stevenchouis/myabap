@EndUserText.label : 'EN04 Plant/Order Type Enablement'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen04_pltauart {
  key mandt : abap.clnt not null;
  key werks : abap.char(4) not null;
  key auart : abap.char(4) not null;

}