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
  upduser   : syuname;
  upddate   : sydatum;

}
