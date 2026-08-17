implementation unmanaged in class zbp_i_rap08_order unique;

define behavior for ZI_RAP08_ORDER alias Header
lock master
{
  create;
  update;
  delete;

  association _Item { create; }

  action confirmOrder result [1] $self;
  action addItem parameter ZI_RAP08_ADDITEM result [1] $self;

  field ( readonly ) created_at, created_by, status;
  field ( features : instance ) order_id;
}

define behavior for ZI_RAP08_ORDER_I alias Item
lock dependent ( order_id = order_id )
{
  update;
  delete;

  field ( readonly ) order_id;
  field ( features : instance ) item_id;

  association _Header;
}
