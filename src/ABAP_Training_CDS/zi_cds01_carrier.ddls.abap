@AbapCatalog.sqlViewName: 'ZICDS01CARR'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS01: Airline Carrier Basic View'
define view ZI_CDS01_CARRIER
  as select from scarr
{
  key carrid,
  carrname,
  currcode,
  url
}
