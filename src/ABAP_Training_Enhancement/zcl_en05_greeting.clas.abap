class ZCL_EN05_GREETING definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces ZIF_EN05_FLIGHT_GREETING .
protected section.
private section.
ENDCLASS.



CLASS ZCL_EN05_GREETING IMPLEMENTATION.


  method ZIF_EN05_FLIGHT_GREETING~GET_GREETING.
    " 真實 Implementation：跟 Fallback Class 的文字明顯不同，方便驗證是否真的呼叫到這裡
    cv_text = |Bon voyage on { iv_carrid }! (real implementation ZCL_EN05_GREETING is active)|.
  endmethod.
ENDCLASS.