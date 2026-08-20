@AbapCatalog.sqlViewName: 'ZCCDS08RRST'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS08: Route Revenue Statistics (Aggregated)'
define view ZC_CDS08_ROUTE_REVENUE_STATS
  with parameters
    p_carrid : s_carr_id
  as select from ZI_CDS08_ROUTE_REVENUE( p_carrid: $parameters.p_carrid )
{
  key carrid,
  key connid,

      cityfrom,
      cityto,
      CarrierName,

      count(*)                  as FlightCount,
      sum(EstimatedRevenue)      as TotalRevenue,
      avg(seatsocc)               as AvgSeatsOccupied
}
group by carrid, connid, cityfrom, cityto, CarrierName
