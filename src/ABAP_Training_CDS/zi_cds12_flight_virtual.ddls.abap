@AbapCatalog.sqlViewName: 'ZICDS12FVRT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS12: Flight with Virtual Element (SADL Exit)'
define view ZI_CDS12_FLIGHT_VIRTUAL
  as select from sflight
{
  key carrid,
  key connid,
  key fldate,

      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_CDS12_DAYS_CALC'
      cast( 0 as abap.int4 )   as DaysUntilDeparture
}
