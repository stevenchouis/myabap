@AbapCatalog.sqlViewName: 'ZICDS03FJON'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS03: Flight Schedule with Direct INNER JOIN'
define view ZI_CDS03_FLIGHT_JOIN
  as select from spfli as Schedule
  inner join   scarr as Carrier
    on Carrier.carrid = Schedule.carrid
{
  key Schedule.carrid,
  key Schedule.connid,
      Schedule.cityfrom,
      Schedule.cityto,
      Schedule.deptime,
      Schedule.arrtime,

      Carrier.carrname   as CarrierName
}
