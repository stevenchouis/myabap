@EndUserText.label : 'EN08 Component Change Log'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen08_complog {
  key mandt  : mandt not null;
  key aufnr  : aufnr not null;
  key artnr  : artnr not null;
  key updat  : updat not null;
  key uptim  : uptim not null;
  key rsnum  : rsnum not null;
  key rspos  : rspos not null;
  key rsart  : rsart not null;
  key seq    : zen08_seq not null;
  chngind    : cdchngind;
  fname      : fieldname;
  fname_dscr : text30;
  value_old  : cdfldvalo;
  value_new  : cdfldvaln;
  id         : uname;
  name       : text80;
  tcode      : tcode;

}
