@Metadata.layer: #CUSTOMER

@UI.headerInfo: {
  typeName: 'Note',
  typeNamePlural: 'Notes',
  title: { type: #STANDARD, value: 'title' }
}

annotate entity ZI_RC05_NOTE
    with
{
  @UI.facet: [
    { id: 'GeneralInfo', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General Information', position: 10 }
  ]

  @UI.selectionField: [ { position: 10 } ]
  @UI.lineItem: [ { position: 10 } ]
  @UI.identification: [ { position: 10 } ]
  note_id;

  @UI.lineItem: [ { position: 20 } ]
  @UI.identification: [ { position: 20 } ]
  title;

  @UI.lineItem: [ { position: 30 } ]
  @UI.identification: [ { position: 30 } ]
  content;

  @UI.lineItem: [ { position: 40 } ]
  @UI.identification: [ { position: 40 } ]
  changed_at;
}
