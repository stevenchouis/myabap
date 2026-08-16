@Metadata.layer: #CUSTOMER
@UI.headerInfo: {
  typeName: 'Test',
  typeNamePlural: 'Tests',
  title: { type: #STANDARD, value: 'descr' }
}

annotate view ZI_RAP03_UMTEST with
{
  @UI.facet: [
    {
      id: 'GeneralInformation',
      purpose: #STANDARD,
      type: #IDENTIFICATION_REFERENCE,
      label: 'General Information',
      position: 10
    }
  ]

  @UI.lineItem: [{ position: 10 }]
  @UI.selectionField: [{ position: 10 }]
  @UI.identification: [{ position: 10 }]
  id;

  @UI.lineItem: [{ position: 20 }]
  @UI.identification: [{ position: 20 }]
  descr;

  @UI.lineItem: [{ position: 30 }]
  @UI.identification: [{ position: 30 }]
  created_at;

  @UI.lineItem: [{ position: 40 }]
  @UI.identification: [{ position: 40 }]
  created_by;
}
