@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZI_RC06_ORDER_Item CDS View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_RC06_ORDER_I as select from zrc06_order_i
association to parent ZI_RC06_ORDER as _Header
    on $projection.order_id = _Header.order_id
{
  key order_id,
  key item_id,
  material_desc,
  quantity,

  _Header
}
