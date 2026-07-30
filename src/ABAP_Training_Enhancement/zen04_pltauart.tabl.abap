@EndUserText.label : 'EN04 Plant/Order Type Enablement'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen04_pltauart {
  key mandt : mandt not null;
  key werks : werks_d not null;
  key auart : aufart not null;

}