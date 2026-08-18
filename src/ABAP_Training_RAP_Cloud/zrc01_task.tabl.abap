@EndUserText.label : 'RC01 Task Root Table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zrc01_task {

  key client  : abap.clnt not null;
  key task_id : abap.char(10) not null;
  description : abap.char(100);
  status      : abap.char(1);
  priority    : abap.char(1);
  due_date    : abap.dats;
  created_at  : abap.utclong;
  created_by  : abap.char(12);

}
