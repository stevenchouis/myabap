@EndUserText.label: 'CDS16: Org Unit Hierarchy - Final Integration'
@ObjectModel: { dataCategory: #HIERARCHY }
@ObjectModel.representativeKey: 'OrgUnitId'
@Analytics.query: true
@AbapCatalog.sqlViewName: 'ZICDS16ORGF'
@hierarchy.parentChild:
{
  recurse:
    {
        parent: 'ParentId',
        child:  'OrgUnitId'
     },
  siblingsOrder:
    {
        by: 'SeqNumber',
        direction: 'ASC'
    }
  }
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view ZI_CDS16_ORGUNIT_FINAL
  as select from ztcds14_orgunit
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_CDS16_ORGUNIT_FINAL', element: 'OrgUnitId' } }]
  key orgunit_id    as OrgUnitId,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_CDS16_ORGUNIT_FINAL', element: 'OrgUnitId' } }]
      parent_id     as ParentId,

      @Analytics.dimension: true
      orgunit_name  as OrgUnitName,

      seq_number    as SeqNumber,

      @Analytics.measure: true
      @DefaultAggregation: #SUM
      headcount     as HeadCount,

      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_CDS16_LABEL_CALC'
      cast( '' as abap.char(60) )   as DisplayLabel
}
