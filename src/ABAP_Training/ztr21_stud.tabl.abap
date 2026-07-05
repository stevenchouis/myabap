@EndUserText.label : 'Training ex21: students'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table ztr21_stud {
  key mandt : mandt not null;
  key id    : abap.char(5) not null;
  name      : abap.char(40);
  score     : ztr21_score;
  @AbapCatalog.foreignKey.label : 'Check Against Class'
  @AbapCatalog.foreignKey.screenCheck : true
  klasse    : ztr21_klasse
    with foreign key [0..*,1] ztr21_class
      where mandt = ztr21_stud.mandt
        and klasse = ztr21_stud.klasse;
  upduser   : syuname;
  upddate   : sydatum;

}
