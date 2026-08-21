@EndUserText.label: 'RAP10: WHMS Submission Log (training)'
@AbapCatalog.sqlViewName: 'ZIRAP10LOG'
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.compositionRoot: true
define root view ZI_RAP10_LOG
  as select from zrap10_log
{
  key log_id      as LogId,
      zwhms_no    as ZwhmsNo,
      zrt_no      as ZrtNo,
      budat       as Budat,
      bldat       as Bldat,
      ztran_type  as ZtranType,
      bktxt       as Bktxt,
      msgty       as Msgty,
      message     as Message,
      created_at  as CreatedAt
}
