@AbapCatalog.sqlViewName: 'ZIRAP02TASK'
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP02 Task Interface View'
@ObjectModel.compositionRoot: true
@Metadata.allowExtensions: true
define root view ZI_RAP02_TASK
  as select from zrap02_task
{
  key task_id,
  description,
  status,
  priority,
  due_date,
  created_at,
  created_by
}
