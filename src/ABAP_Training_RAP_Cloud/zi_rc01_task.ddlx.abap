@Metadata.layer: #CUSTOMER

@UI.headerInfo: {
  typeName: 'Task',
  typeNamePlural: 'Tasks',
  title: { type: #STANDARD, value: 'description' }
}

annotate entity ZI_RC01_TASK
    with
{
  @UI.facet: [
    { id: 'GeneralInfo', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General Information', position: 10 }
  ]

  @UI.selectionField: [ { position: 10 } ]
  @UI.lineItem: [ { position: 10 } ]
  @UI.identification: [ { position: 10 } ]
  task_id;

  @UI.lineItem: [ { position: 20 } ]
  @UI.identification: [ { position: 20 } ]
  description;

  @UI.selectionField: [ { position: 20 } ]
  @UI.lineItem: [
    { position: 30 },
    { type: #FOR_ACTION, dataAction: 'markDone', label: 'Mark Done' }
  ]
  @UI.identification: [
    { position: 30 },
    { type: #FOR_ACTION, dataAction: 'markDone', label: 'Mark Done' }
  ]
  @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_RC08_STATUS_VH', element: 'status' } } ]
  status;

  @UI.lineItem: [ { position: 40 } ]
  @UI.identification: [ { position: 40 } ]
  priority;

  @UI.lineItem: [ { position: 50 } ]
  @UI.identification: [ { position: 50 } ]
  due_date;

  @UI.lineItem: [ { position: 60 } ]
  @UI.identification: [ { position: 60 } ]
  created_at;

  @UI.lineItem: [ { position: 70 } ]
  @UI.identification: [ { position: 70 } ]
  created_by;
}
