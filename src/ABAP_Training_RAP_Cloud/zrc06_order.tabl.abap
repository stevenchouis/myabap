@EndUserText.label : 'ZRC06_ORDER Table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zrc06_order {

  key client   : abap.clnt not null;
  key order_id : abap.char(10) not null;
  description  : abap.char(100);
  created_at   : abap.utclong;
  created_by   : abap.char(12);

}
