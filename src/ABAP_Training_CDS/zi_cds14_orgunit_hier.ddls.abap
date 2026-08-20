@EndUserText.label: 'CDS14: Org Unit Hierarchy'
@ObjectModel: { dataCategory: #HIERARCHY }
@ObjectModel.representativeKey: 'OrgUnitId'
@AbapCatalog.sqlViewName: 'ZICDS14ORGH'
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
define view ZI_CDS14_ORGUNIT_HIER
  as select from ztcds14_orgunit
{
  key orgunit_id    as OrgUnitId,
      parent_id     as ParentId,
      orgunit_name  as OrgUnitName,
      seq_number    as SeqNumber
}
