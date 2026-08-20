@AbapCatalog.sqlViewName: 'ZICDS07FLGT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS07: Flight Interface View with Default Aggregation Hints'
define view ZI_CDS07_FLIGHT
  as select from sflight
{
  key carrid,
  key connid,
  key fldate,

      @DefaultAggregation: #SUM
      seatsocc,

      @DefaultAggregation: #AVG
      price,

      currency
}
