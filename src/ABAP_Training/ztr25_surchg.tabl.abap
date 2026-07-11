@EndUserText.label : 'Holiday surcharge config per airline'
@AbapCatalog.enhancementCategory : #EXTENSIBLE_CHARACTER_NUMERIC
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table ztr25_surchg {
  key mandt     : mandt not null;
  @AbapCatalog.foreignKey.label : 'Check Against Airline (Standard SCARR)'
  @AbapCatalog.foreignKey.screenCheck : true
  key carrid    : s_carr_id not null
    with foreign key [0..1,1] scarr
      where mandt = ztr25_surchg.mandt
        and carrid = ztr25_surchg.carrid;
  active        : ztr25_active not null;
  surcharge_pct : ztr25_surpct not null;
  upduser       : syuname not null;
  upddate       : sydatum not null;

}
