@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZI_RC05_NOTE CDS'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_RC05_NOTE
  as select from zrc05_note
{
  key note_id,
  title,
  content,
  @Semantics.systemDateTime.lastChangedAt: true
  changed_at,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_changed_at
}
