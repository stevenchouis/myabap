@EndUserText.label: 'CDS10: Fleet Status (Custom Entity, non-DB source)'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CDS10_STATUS_QUERY'
define custom entity ZI_CDS10_FLEET_STATUS
{
  key StatusCode : abap.char(10);
      StatusText : abap.char(40);
      SortOrder  : abap.int4;
}
