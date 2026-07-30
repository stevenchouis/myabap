@EndUserText.label : 'EN06 WORKORDER_UPDATE AT_SAVE audit log'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zen06_atsave_log {
  key mandt : mandt not null;
  key logno : abap.numc(10) not null;
  werks     : werks_d not null;
  auart     : aufart not null;
  aufnr     : aufnr not null;
  logdate   : updat;
  logtime   : uptim;

}