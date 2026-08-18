@EndUserText.label : 'ZRC05_NOTE_D table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zrc05_note_d {

  key client       : abap.clnt not null;
  key note_id      : abap.char(10) not null;
  title            : abap.char(40);
  content          : abap.char(100);
  changed_at       : abap.utclong;
  local_changed_at : abap.utclong;
  "%admin"         : include sych_bdl_draft_admin_inc;

}
