@AbapCatalog.sqlViewName: 'ZIRAP08ORDERI'
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'RAP08 Order Item View'
define view ZI_RAP08_ORDER_I
  as select from zrap08_order_i

  association to parent ZI_RAP08_ORDER as _Header
    on $projection.order_id = _Header.order_id
{
  key order_id,
  key item_id,
  material_desc,
  quantity,

  _Header
}
