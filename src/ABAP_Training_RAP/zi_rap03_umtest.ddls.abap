@AbapCatalog.sqlViewName: 'ZIRAP03UMTEST'
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP03 Unmanaged Test View'
@ObjectModel.compositionRoot: true
@Metadata.allowExtensions: true
define root view ZI_RAP03_UMTEST
  as select from zrap03_umtest
{
  @EndUserText.label: 'ID'
  key id,

  @EndUserText.label: 'Description'
  descr,

  @EndUserText.label: 'Created At'
  created_at,

  @EndUserText.label: 'Created By'
  created_by
}
