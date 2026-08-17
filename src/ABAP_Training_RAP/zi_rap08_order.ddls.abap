@AbapCatalog.sqlViewName: 'ZIRAP08ORDER'
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP08 Order Header View'
@ObjectModel.compositionRoot: true
@Metadata.allowExtensions: true
define root view ZI_RAP08_ORDER
  as select from zrap08_order

  composition [0..*] of ZI_RAP08_ORDER_I as _Item
{
  key order_id,
  description,
  status,
  created_at,
  created_by,

  _Item
}
