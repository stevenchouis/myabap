@AbapCatalog.sqlViewName: 'ZICDS05FLGT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS05: Flight Interface View (Layer 1)'
define view ZI_CDS05_FLIGHT
  with parameters
    p_carrid : s_carr_id
  as select from sflight as Flight
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

      cast( Flight.seatsocc as abap.decfloat34 )
        / cast( Flight.seatsmax as abap.decfloat34 )
        * 100                                              as OccupancyRatePercent,

      _Carrier
}
where Flight.carrid = $parameters.p_carrid
