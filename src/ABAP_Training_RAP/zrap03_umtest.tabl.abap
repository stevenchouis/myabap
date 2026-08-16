@EndUserText.label : 'RAP03 Unmanaged Test Table'
@AbapCatalog.enhancementCategory : #EXTENSIBLE_ANY
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zrap03_umtest {
  key client : mandt not null;
  key id     : abap.char(10) not null;
  descr      : abap.char(40);
  created_at : timestampl;
  created_by : syuname;

}
