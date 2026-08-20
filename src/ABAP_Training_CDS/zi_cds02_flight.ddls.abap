@AbapCatalog.sqlViewName: 'ZICDS02FLGT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS02: Flight with Computed Fields'
define view ZI_CDS02_FLIGHT
  as select from sflight
{
  key carrid                                            as AirlineID,
  key connid                                             as ConnectionID,
  key fldate                                              as FlightDate,

      concat( carrid, connid )                            as FlightNumber,

      dats_days_between( cast( '20260101' as abap.dats ), fldate )  as DaysSinceYearStart,

      substring( cast( fldate as abap.char( 8 ) ), 1, 4 ) as FlightYear,

      cast( seatsocc as abap.decfloat34 )
        / cast( seatsmax as abap.decfloat34 )
        * 100                                              as OccupancyRatePercent,

      seatsmax                                            as SeatsMax,
      seatsocc                                            as SeatsOccupied,

      case
        when seatsocc >= seatsmax    then 'FULL'
        when seatsocc <= 10          then 'MOSTLY_EMPTY'
        else                               'AVAILABLE'
      end                                                  as OccupancyStatus,

      price                                                as Price,
      currency                                             as CurrencyCode,

      'CDS02'                                              as DataSource
}
