@Metadata.layer: #CUSTOMER
@UI: {
  headerInfo: {
    typeName: 'Task',
    typeNamePlural: 'Tasks',
    title: { type: #STANDARD, value: 'description' }
  }
}

annotate view ZI_RAP02_TASK with
{
  @UI.lineItem: [{ position: 10 }]
  @UI.selectionField: [{ position: 10 }]
  task_id;

  @UI.lineItem: [{ position: 20 }]
  description;

  @UI.lineItem: [{ position: 30 }]
  @UI.selectionField: [{ position: 20 }]
  status;

  @UI.lineItem: [{ position: 40 }]
  priority;

  @UI.lineItem: [{ position: 50 }]
  due_date;
}
