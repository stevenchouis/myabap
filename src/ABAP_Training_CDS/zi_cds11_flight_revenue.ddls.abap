@AbapCatalog.sqlViewName: 'ZICDS11FREV'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS11: Flight Interface View with Computed Revenue'
define view ZI_CDS11_FLIGHT_REVENUE
  as select from sflight as Flight
{
  key Flight.carrid,
  key Flight.connid,
  key Flight.fldate,
      Flight.currency,
      Flight.seatsocc,
      Flight.price * Flight.seatsocc   as EstimatedRevenue
}
