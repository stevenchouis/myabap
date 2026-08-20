@AbapCatalog.sqlViewName: 'ZICDS06FLGT'
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'CDS06: Flight with Access Control (#CHECK)'
define view ZI_CDS06_FLIGHT
  as select from sflight
{
  key carrid,
  key connid,
  key fldate,
      price,
      currency,
      seatsmax,
      seatsocc
}
