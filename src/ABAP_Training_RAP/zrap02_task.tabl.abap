@EndUserText.label : 'RAP02 Task Root Table'
@AbapCatalog.enhancementCategory : #EXTENSIBLE_ANY
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zrap02_task {
  key client  : mandt not null;
  key task_id : zrap02_taskid not null;
  description : text100;
  status      : zrap02_status;
  priority    : zrap02_priority;
  due_date    : zrap02_duedate;
  created_at  : timestampl;
  created_by  : syuname;

}
