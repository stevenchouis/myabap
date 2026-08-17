@EndUserText.label: 'RAP08 Order Service Definition'
define service ZRAP08_SD {
  expose ZI_RAP08_ORDER as Orders;
  expose ZI_RAP08_ORDER_I as Items;
}
