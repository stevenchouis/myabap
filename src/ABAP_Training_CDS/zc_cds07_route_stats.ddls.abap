@AbapCatalog.sqlViewName: 'ZCCDS07RTST'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS07: Route Statistics (Aggregated)'
define view ZC_CDS07_ROUTE_STATS
  as select from ZI_CDS07_FLIGHT
{
  key carrid,

      count(*)           as FlightCount,
      sum(seatsocc)       as TotalSeatsOccupied,
      avg(price)          as AvgPrice
}
group by carrid
