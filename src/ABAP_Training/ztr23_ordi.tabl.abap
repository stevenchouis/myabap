@EndUserText.label : 'Training ex23: order items'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table ztr23_ordi {
  key mandt  : mandt not null;
  @AbapCatalog.foreignKey.label : 'Check Against Order Header'
  @AbapCatalog.foreignKey.screenCheck : true
  key ordno  : ztr23_ordno not null
    with foreign key [0..*,1] ztr23_ordh
      where mandt = ztr23_ordi.mandt
        and ordno = ztr23_ordi.ordno;
  key itemno : abap.numc(3) not null;
  product    : abap.char(20);
  qty        : abap.int4;
  price      : abap.dec(9,2);
  upduser    : syuname;
  upddate    : sydatum;

}
