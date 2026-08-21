implementation unmanaged in class zbp_i_rap10_log unique;

define behavior for ZI_RAP10_LOG alias Log
lock master
{
  static action SubmitWhmsRequest parameter ZTT_QM005_REQUEST result [1..*] ZSQM005_OUTBOUND;
}
