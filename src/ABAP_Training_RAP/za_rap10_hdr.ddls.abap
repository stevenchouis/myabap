@EndUserText.label: 'RAP10 Abstract Entity - WHMS Header (test)'
define root abstract entity ZA_RAP10_HDR
{
  key zwhms_no   : zwhms_no;
  key zrt_no     : zrt_no;
      budat      : budat;
      bldat      : bldat;
      ztran_type : ztran_type;
      bktxt      : bktxt;

  _Detail : composition [0..*] of ZA_RAP10_DTL;
}
