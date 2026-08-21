@EndUserText.label : 'RAP10 WHMS submission log (training)'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zrap10_log {
  key mandt  : mandt not null;
  key log_id : sysuuid_x16 not null;
  zwhms_no   : zwhms_no;
  zrt_no     : zrt_no;
  budat      : budat;
  bldat      : bldat;
  ztran_type : ztran_type;
  bktxt      : bktxt;
  msgty      : msgty;
  message    : bapi_msg;
  created_at : timestampl;

}
