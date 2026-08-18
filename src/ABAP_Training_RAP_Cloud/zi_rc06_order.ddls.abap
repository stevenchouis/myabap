@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZI_RC06_ORDER CDS VIEW'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_RC06_ORDER as select from zrc06_order
composition [0..*] of ZI_RC06_ORDER_I as _Item
{
  key order_id,
  description,
  created_at,
  created_by,

  _Item
}
