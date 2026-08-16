managed implementation in class zbp_i_rap02_task unique;

define behavior for ZI_RAP02_TASK alias Task
persistent table zrap02_task
etag created_at
lock master
{
  create;
  update;
  delete;

  field ( mandatory ) description;

  determination setCreationInfo on save { create; }
  validation validateStatus on save { field status; }
}
