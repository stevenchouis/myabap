managed implementation in class zbp_i_rc06_order unique;
strict ( 2 );

define behavior for ZI_RC06_ORDER alias Header
persistent table zrc06_order
lock master
authorization master ( none )
{
  create;
  update;
  delete;

  association _Item { create; }

  field ( readonly : update ) order_id;
  field ( readonly )          created_at, created_by;
  field ( mandatory )         description;
}

define behavior for ZI_RC06_ORDER_I alias Item
persistent table zrc06_order_i
lock dependent by _Header
authorization dependent by _Header
{
  update;
  delete;

  association _Header;

  field ( readonly )  order_id;
  field ( mandatory )  material_desc, quantity;
}
