@AbapCatalog.sqlViewName: 'ZCCDS11RANL'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Analytics.query: true
@EndUserText.label: 'CDS11: Route Revenue Analytics (Dimension/Measure)'
define view ZC_CDS11_ROUTE_ANALYTICS
  as select from ZI_CDS11_FLIGHT_REVENUE
{
      @Analytics.dimension: true
  key carrid,

      @Analytics.dimension: true
  key connid,

      @Analytics.dimension: true
      currency,

      @Analytics.measure: true
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'currency'
      sum( EstimatedRevenue )   as TotalRevenue,

      @Analytics.measure: true
      @DefaultAggregation: #SUM
      sum( seatsocc )            as TotalSeatsOccupied,

      @Analytics.measure: true
      @DefaultAggregation: #COUNT
      count(*)                   as FlightCount
}
group by carrid, connid, currency
