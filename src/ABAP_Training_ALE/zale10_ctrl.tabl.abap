@EndUserText.label : 'ALE10 INVOIC review threshold by sales org'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zale10_ctrl {
  key mandt : mandt not null;
  key vkorg : vkorg not null;
  @Semantics.amount.currencyCode : 'zale10_ctrl.waerk'
  netwr     : netwr;
  waerk     : waerk;
  active    : xfeld;

}
