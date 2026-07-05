@EndUserText.label : 'Training ex21: classes (header)'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table ztr21_class {
  key mandt  : mandt not null;
  key klasse : ztr21_klasse not null;
  klname     : ztr21_klname;

}
