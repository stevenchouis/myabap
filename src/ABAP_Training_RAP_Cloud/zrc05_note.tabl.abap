@EndUserText.label : 'ZRC05_NOTE Table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zrc05_note {

  key client       : abap.clnt not null;
  key note_id      : abap.char(10) not null;
  title            : abap.char(40);
  content          : abap.char(100);
  changed_at       : abap.utclong;
  local_changed_at : abap.utclong;

}
