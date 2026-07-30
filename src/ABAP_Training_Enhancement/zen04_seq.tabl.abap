@EndUserText.label : 'EN04 Order Number Running Sequence'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen04_seq {
  key mandt    : mandt not null;
  key werks    : werks_d not null;
  key auart    : aufart not null;
  key fevor    : fevor not null;
  key zgrtype  : zen04_zgrtype not null;
  key leadcode : zen04_leadcod not null;
  key zyear    : zen04_zyear not null;
  key zmonth   : zen04_zmonth not null;
  numno        : zen04_numno not null;
  aufnr        : aufnr not null;

}