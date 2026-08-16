REPORT zr_rap05_demo.

"⚠️ Managed BDEF 的 CUD 在這系統一律 Dump（見 rap03 Part C）。
"這支程式只是 Managed Determination 的 EML 語法範例，不要嘗試執行。

MODIFY ENTITIES OF zi_rap02_task
  ENTITY Task
    CREATE FIELDS ( description status priority due_date )
    WITH VALUE #( ( %cid = 'C1' description = 'Managed Determination Demo' ) )
  FAILED   DATA(ls_failed)
  REPORTED DATA(ls_reported).

COMMIT ENTITIES.

WRITE: / 'If this line prints, the Managed Runtime whitelist restriction no longer applies.'.
