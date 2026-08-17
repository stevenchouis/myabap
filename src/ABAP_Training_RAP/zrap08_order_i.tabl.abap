@EndUserText.label : 'RAP08 Order Item Table'
@AbapCatalog.enhancementCategory : #EXTENSIBLE_ANY
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zrap08_order_i {
  key client    : mandt not null;
  key order_id  : zrap08_orderid not null;
  key item_id   : zrap08_itemid not null;
  material_desc : text100;
  quantity      : zrap08_quantity;

}
