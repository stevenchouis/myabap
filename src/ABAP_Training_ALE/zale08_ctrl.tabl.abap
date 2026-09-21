@EndUserText.label : 'ALE08 allowed company codes for ZALE06 inbound'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zale08_ctrl {
  key mandt : mandt not null;
  key bukrs : bukrs not null;

}
