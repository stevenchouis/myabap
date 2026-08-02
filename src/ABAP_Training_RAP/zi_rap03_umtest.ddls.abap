@AbapCatalog.sqlViewName: 'ZIRAP03UMTEST'
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP03 Unmanaged Test View'
@ObjectModel.compositionRoot: true
define root view ZI_RAP03_UMTEST
  as select from zrap03_umtest
{
  key id,
  descr
}
