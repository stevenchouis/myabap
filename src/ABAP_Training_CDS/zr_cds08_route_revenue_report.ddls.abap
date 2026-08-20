@AbapCatalog.sqlViewName: 'ZRCDS08RTRP'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS08: Route Revenue Report (Final Layer)'
define view ZR_CDS08_ROUTE_REVENUE_REPORT
  with parameters
    p_carrid : s_carr_id
  as select from ZC_CDS08_ROUTE_REVENUE_STATS( p_carrid: $parameters.p_carrid )
{
  key carrid,
  key connid,
      cityfrom,
      cityto,
      CarrierName,
      FlightCount,
      TotalRevenue,
      AvgSeatsOccupied,

      case
        when TotalRevenue >= 2000000    then 'HIGH'
        when TotalRevenue >= 1000000    then 'MEDIUM'
        else                                  'LOW'
      end                                     as RevenueTier
}
