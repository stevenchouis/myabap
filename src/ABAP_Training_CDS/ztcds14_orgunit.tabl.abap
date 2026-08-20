@EndUserText.label : 'CDS14 Org Unit Hierarchy Table'
@AbapCatalog.enhancementCategory : #EXTENSIBLE_CHARACTER_NUMERIC
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table ztcds14_orgunit {
  key client     : abap.clnt not null;
  key orgunit_id : abap.char(10) not null;
  parent_id      : abap.char(10);
  orgunit_name   : abap.char(40);
  seq_number     : abap.numc(4);

}
