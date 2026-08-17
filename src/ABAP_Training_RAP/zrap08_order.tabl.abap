@EndUserText.label : 'RAP08 Order Header Table'
@AbapCatalog.enhancementCategory : #EXTENSIBLE_ANY
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zrap08_order {
  key client   : mandt not null;
  key order_id : zrap08_orderid not null;
  description  : text100;
  status       : zrap09_ordstatus;
  created_at   : timestampl;
  created_by   : syuname;

}
