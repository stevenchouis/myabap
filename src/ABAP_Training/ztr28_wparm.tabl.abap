@EndUserText.label : 'TR28 Plant Parameter Master'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table ztr28_wparm {
  key mandt : mandt not null;
  @AbapCatalog.foreignKey.label : 'Check Against Plant Master'
  @AbapCatalog.foreignKey.screenCheck : true
  key werks : werks_d not null
    with foreign key [0..*,1] t001w
      where mandt = ztr28_wparm.mandt
        and werks = ztr28_wparm.werks;
  key param : ztr28_pcode not null;
  parval    : ztr28_parval;
  partxt    : text40;
  upduser   : syuname;
  upddate   : sydatum;

}
