@EndUserText.label : 'EN06 WORKORDER_UPDATE AT_SAVE audit log'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen06_atsave_log {
  key mandt   : abap.clnt not null;
  key logno   : abap.numc(10) not null;
  werks       : abap.char(4) not null;
  auart       : abap.char(4) not null;
  aufnr       : abap.char(12) not null;
  logdate     : abap.dats;
  logtime     : abap.tims;

}