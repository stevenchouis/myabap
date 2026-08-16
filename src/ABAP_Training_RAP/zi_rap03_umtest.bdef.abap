implementation unmanaged in class zbp_i_rap03_um4 unique;

define behavior for ZI_RAP03_UMTEST alias Test
lock master
{
  create;

  field ( readonly ) created_at, created_by;
}
