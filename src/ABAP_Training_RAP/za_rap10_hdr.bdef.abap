* Negative-result validation artifact (rap10) - this Abstract BDEF (without
* "with hierarchy") activates cleanly on this system, but two variants of
* this file were tried and rejected before landing here:
*
* 1. Adding "with hierarchy;" to the header:
*      abstract;
*      with hierarchy;
*    -> checkrun error: "BOPF | draft" expected, not "hierarchy".
*
* 2. Using this Abstract BDEF as a deep parameter on an Action
*    (in zi_rap10_log.bdef.abap):
*      static action X deep table parameter ZA_RAP10_HDR;
*    -> checkrun error: "; | external | parameter | result" expected, not "deep".
*
* Conclusion: Deep Parameter (Abstract Entity as Action's nested input) requires
* On-Premise ABAP release 7.56+ (see ABENRAP_FEATURE_TABLE); this system is 7.54
* and does not support it at the BDL level, even though the underlying CDS DDL
* composition (see za_rap10_hdr.ddls.abap / za_rap10_dtl.ddls.abap) compiles fine.
* rap10's actual lesson uses a flat parameter referencing an existing classic
* DDIC nested type instead (zi_rap10_log.bdef.abap) - see rap10 lecture.
abstract;

define behavior for ZA_RAP10_HDR alias Header
{
  association _Detail;
}

define behavior for ZA_RAP10_DTL alias Detail
{
  association _Header;
}
