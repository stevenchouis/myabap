REPORT zr_cds02_demo.

SELECT carrid, connid, fldate, seatsmax, seatsocc, price, currency
  FROM sflight
  ORDER BY carrid, connid, fldate
  INTO TABLE @DATA(lt_raw)
  UP TO 5 ROWS.

WRITE: / '=== 1. Direct table SFLIGHT (Open SQL) ==='.
LOOP AT lt_raw INTO DATA(ls_raw).
  WRITE: / ls_raw-carrid, ls_raw-connid, ls_raw-fldate, ls_raw-seatsocc, '/', ls_raw-seatsmax.
ENDLOOP.

SELECT AirlineID, ConnectionID, FlightDate, FlightNumber, FlightYear,
       DaysSinceYearStart, OccupancyRatePercent, SeatsMax, SeatsOccupied,
       OccupancyStatus, Price, CurrencyCode, DataSource
  FROM zi_cds02_flight
  ORDER BY AirlineID, ConnectionID, FlightDate
  INTO TABLE @DATA(lt_cds)
  UP TO 5 ROWS.

WRITE: / '=== 2. CDS View ZI_CDS02_FLIGHT (computed fields) ==='.
LOOP AT lt_cds INTO DATA(ls_cds).
  WRITE: / ls_cds-flightnumber, ls_cds-flightyear, ls_cds-dayssinceyearstart,
           ls_cds-occupancyratepercent, ls_cds-occupancystatus, ls_cds-datasource.
ENDLOOP.

WRITE: / '=== 3. Row count match ==='.
IF lines( lt_raw ) = lines( lt_cds ).
  WRITE: / 'MATCH: row counts equal', lines( lt_raw ).
ELSE.
  WRITE: / 'MISMATCH'.
ENDIF.
