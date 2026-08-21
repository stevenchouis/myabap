@EndUserText.label: 'RAP10 Abstract Entity - WHMS Detail (test)'
define abstract entity ZA_RAP10_DTL
{
  key zwhms_no  : zwhms_no;
  key zrt_no    : zrt_no;
      zwhms_itm : zwhms_itm;
      rt_item   : zeile;

      @Semantics.quantity.unitOfMeasure: 'ZA_RAP10_DTL.uom'
      quantity  : menge_d;
      uom       : meins;

  _Header : association to parent ZA_RAP10_HDR
    on  _Header.zwhms_no = $projection.zwhms_no
    and _Header.zrt_no   = $projection.zrt_no;
}
