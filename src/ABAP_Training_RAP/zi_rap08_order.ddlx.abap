@Metadata.layer: #CUSTOMER
@UI: {
  headerInfo: {
    typeName: 'Order',
    typeNamePlural: 'Orders',
    title: { type: #STANDARD, value: 'order_id' }
  }
}

annotate view ZI_RAP08_ORDER with
{
  @UI.facet: [
    { id: 'GeneralInformation', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General Information', position: 10 },
    { id: 'Items', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Order Items', targetElement: '_Item', position: 20 }
  ]

  @UI: {
    lineItem: [{ position: 10 }],
    selectionField: [{ position: 10 }],
    identification: [
      { position: 10 },
      { type: #FOR_ACTION, dataAction: 'confirmOrder', label: 'Confirm Order' },
      { type: #FOR_ACTION, dataAction: 'addItem', label: 'Add Item' }
    ]
  }
  order_id;

  @UI.lineItem: [{ position: 20 }]
  @UI.identification: [{ position: 20 }]
  description;

  @UI.lineItem: [{ position: 30 }]
  @UI.identification: [{ position: 30 }]
  status;

  @UI.lineItem: [{ position: 40 }]
  @UI.identification: [{ position: 40 }]
  created_at;

  @UI.lineItem: [{ position: 50 }]
  @UI.identification: [{ position: 50 }]
  created_by;
}
