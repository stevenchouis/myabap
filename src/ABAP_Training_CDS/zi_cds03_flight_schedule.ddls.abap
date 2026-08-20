@AbapCatalog.sqlViewName: 'ZICDS03FSCH'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS03: Flight Schedule with Carrier Association'
define view ZI_CDS03_FLIGHT_SCHEDULE
  as select from spfli as Schedule
  association [1..1] to scarr as _Carrier
    on _Carrier.carrid = Schedule.carrid
{
  key Schedule.carrid,
  key Schedule.connid,
      Schedule.cityfrom,
      Schedule.cityto,
      Schedule.deptime,
      Schedule.arrtime,

      _Carrier
}
