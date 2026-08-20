@AbapCatalog.sqlViewName: 'ZICDS04FLGT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS04: Flight with Parameters and Session Variables'
define view ZI_CDS04_FLIGHT
  with parameters
    p_carrid : s_carr_id
  as select from sflight
{
  key carrid,
  key connid,
  key fldate,
      price,
      currency,
      seatsmax,
      seatsocc,

      dats_days_between( cast( $session.system_date as abap.dats ), fldate )   as DaysFromToday,

      $session.user                                        as QueriedByUser,

      case
        when fldate < $session.system_date then 'PAST'
        when fldate = $session.system_date then 'TODAY'
        else                                     'FUTURE'
      end                                                    as TimeStatus
}
where carrid = $parameters.p_carrid
