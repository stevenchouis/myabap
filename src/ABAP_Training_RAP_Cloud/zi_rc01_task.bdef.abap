managed implementation in class zbp_i_rc01_task unique;
strict ( 2 );

define behavior for ZI_RC01_TASK alias Task
persistent table zrc01_task
lock master
authorization master ( none )
etag master created_at
{
  create;
  update;
  delete;

  action markDone result [1] $self;

  field ( readonly : update ) task_id;
  field ( readonly )          created_at, created_by;
  field ( mandatory )         description;

  determination setCreationInfo on save { create; }
  validation validateStatus on save { field status; }
}
