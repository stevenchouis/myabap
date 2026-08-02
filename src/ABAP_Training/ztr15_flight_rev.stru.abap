@EndUserText.label : 'TR15 Part4: flight revenue row type'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
define structure ztr15_flight_rev {
  carrid   : s_carr_id;
  connid   : s_conn_id;
  @Semantics.amount.currencyCode : 'ztr15_flight_rev.currency'
  price    : s_price;
  seatsocc : s_seatsocc;
  @Semantics.amount.currencyCode : 'ztr15_flight_rev.currency'
  revenue  : s_price;
  currency : s_currcode;

}
