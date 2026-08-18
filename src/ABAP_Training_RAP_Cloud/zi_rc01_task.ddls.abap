@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RC01 Task Interface View'
@Metadata.allowExtensions: true
define root view entity ZI_RC01_TASK
  as select from zrc01_task
{
  key task_id,
  description,
  status,
  priority,
  due_date,
  created_at,
  created_by
}
