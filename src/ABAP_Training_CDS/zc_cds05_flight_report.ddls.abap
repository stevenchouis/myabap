@AbapCatalog.sqlViewName: 'ZCCDS05FRPT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS05: Flight Report Composite View (Layer 2)'
define view ZC_CDS05_FLIGHT_REPORT
  with parameters
    p_carrid : s_carr_id
  as select from ZI_CDS05_FLIGHT( p_carrid: $parameters.p_carrid )
{
  key carrid,
  key connid,
  key fldate,
      price,
      currency,
      OccupancyRatePercent,

      case
        when OccupancyRatePercent >= 95    then 'FULL'
        when OccupancyRatePercent >= 80    then 'NEARLY_FULL'
        else                                     'AVAILABLE'
      end                                                    as OccupancyStatus,

      _Carrier.carrname   as CarrierName
}
