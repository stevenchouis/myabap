@EndUserText.label : 'ZRC06_ORDER_I table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zrc06_order_i {

  key client    : abap.clnt not null;
  key order_id  : abap.char(10) not null;
  key item_id   : abap.char(4) not null;
  material_desc : abap.char(40);
  quantity      : abap.dec(9,2);

}
