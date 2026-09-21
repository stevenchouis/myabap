@EndUserText.label : 'ALE09 MIRO outbound pending queue'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zale09_queue {
  key mandt : mandt not null;
  key belnr : re_belnr not null;
  key gjahr : gjahr not null;
  bukrs     : bukrs;
  lifnr     : lifre;
  docnum    : edi_docnum;
  sent      : xfeld;
  errmsg    : bapi_msg;
  erdat     : erdat;
  erzet     : erzet;

}
