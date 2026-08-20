@AbapCatalog.sqlViewName: 'ZCCDS03FCAR'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS03: Consumption View Exposing Carrier via Association'
define view ZC_CDS03_FLIGHT_WITH_CARRIER
  as select from ZI_CDS03_FLIGHT_SCHEDULE
{
  key carrid,
  key connid,
      cityfrom,
      cityto,
      deptime,
      arrtime,

      _Carrier.carrname   as CarrierName
}
