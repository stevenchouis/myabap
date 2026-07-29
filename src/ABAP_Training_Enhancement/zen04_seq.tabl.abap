@EndUserText.label : 'EN04 Order Number Running Sequence'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen04_seq {
  key mandt    : abap.clnt not null;
  key werks    : abap.char(4) not null;
  key auart    : abap.char(4) not null;
  key fevor    : abap.char(3) not null;
  key zgrtype  : abap.char(10) not null;
  key leadcode : abap.char(2) not null;
  key zyear    : abap.char(2) not null;
  key zmonth   : abap.char(1) not null;
  numno        : abap.numc(4) not null;
  aufnr        : abap.char(12) not null;

}