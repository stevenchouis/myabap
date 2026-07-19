@EndUserText.label: 'AM07: route load stats table function'
define table function ZTF_AM07_ROUTE_STATS
  returns {
    mandt      : abap.clnt;
    carrid     : s_carr_id;
    carrname   : s_carrname;
    connid     : s_conn_id;
    flight_cnt : abap.int4;
    seats_occ  : abap.int4;
    seats_max  : abap.int4;
    load_pct   : abap.dec(5,1);
  }
  implemented by method zcl_am07_route_stats=>get_data;
