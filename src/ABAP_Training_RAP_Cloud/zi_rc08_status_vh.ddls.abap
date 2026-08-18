@EndUserText.label: 'Value help for status'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_RC08_STATUS_VH'
define custom entity ZI_RC08_STATUS_VH
{
  @EndUserText.label: 'Status'
  key status      : abap.char(1);

  @EndUserText.label: 'Status Text'
      status_text : abap.string;
}
