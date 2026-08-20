@AbapCatalog.sqlViewName: 'ZICDS13FLGT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS13: Flight with Value Help + Text Association'
define view ZI_CDS13_FLIGHT_VH
  as select from sflight as Flight
  association [1..1] to ZI_CDS01_CARRIER as _Carrier
    on _Carrier.carrid = Flight.carrid
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_CDS01_CARRIER', element: 'carrid' } }]
      @ObjectModel.text.association: '_Carrier'
  key Flight.carrid,
  key Flight.connid,
  key Flight.fldate,

      _Carrier.carrname   as CarrierName
}
