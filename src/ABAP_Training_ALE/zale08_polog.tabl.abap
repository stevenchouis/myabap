@EndUserText.label : 'ALE08 ZALE06 inbound receive log'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #LIMITED
define table zale08_polog {
  key mandt  : mandt not null;
  key docnum : edi_docnum not null;
  key ebeln  : ebeln not null;
  key ebelp  : ebelp not null;
  matnr      : matnr;
  bukrs      : bukrs;
  lifnr      : elifn;
  erdat      : erdat;
  erzet      : erzet;

}
