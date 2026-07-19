@EndUserText.label: 'AM09 capstone: carrier-level stats table function'
define table function ZTF_AM09_CARRIER_STATS
  returns {
    mandt           : abap.clnt;
    carrid          : s_carr_id;
    carrname        : s_carrname;
    route_cnt       : abap.int4;
    total_flights   : abap.int4;
    total_seats_occ : abap.int4;
    total_seats_max : abap.int4;
    load_pct        : abap.dec(5,1);
    total_revenue   : abap.dec(15,2);
  }
  implemented by method zcl_am09_carrier_stats=>get_data;
