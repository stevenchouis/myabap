@AbapCatalog.sqlViewName: 'ZICDS08RREV'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS08: Route Revenue Interface View'
define view ZI_CDS08_ROUTE_REVENUE
  with parameters
    p_carrid : s_carr_id
  as select from sflight as Flight
  association [1..1] to spfli as _Schedule
    on  _Schedule.carrid = Flight.carrid
    and _Schedule.connid = Flight.connid
  association [1..1] to scarr as _Carrier
    on _Carrier.carrid = Flight.carrid
{
  key Flight.carrid,
  key Flight.connid,
  key Flight.fldate,

      Flight.price,
      Flight.currency,
      Flight.seatsmax,
      Flight.seatsocc,

      Flight.price * Flight.seatsocc   as EstimatedRevenue,

      _Schedule.cityfrom,
      _Schedule.cityto,
      _Carrier.carrname   as CarrierName
}
where Flight.carrid = $parameters.p_carrid
