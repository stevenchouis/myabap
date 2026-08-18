managed implementation in class zbp_i_rc05_note unique;
strict ( 2 );
with draft;

define behavior for ZI_RC05_NOTE alias Note
persistent table zrc05_note
draft table zrc05_note_d
lock master
total etag changed_at
etag master local_changed_at
authorization master ( none )
{
  create;
  update;
  delete;

  field ( readonly : update ) note_id;
  field ( readonly )          changed_at, local_changed_at;
  field ( mandatory )         title;

  draft action Activate optimized;
  draft action Discard;
  draft action Edit;
  draft action Resume;
  draft determine action Prepare;
}
