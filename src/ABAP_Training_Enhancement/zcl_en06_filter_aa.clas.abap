class ZCL_EN06_FILTER_AA definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces ZIF_EN06_FILTER_GREETING .
protected section.
private section.
ENDCLASS.



CLASS ZCL_EN06_FILTER_AA IMPLEMENTATION.


  method ZIF_EN06_FILTER_GREETING~GET_GREETING.
    cv_text = |AA 專屬問候語：American Airlines greets carrier { iv_carrid }|.
  endmethod.
ENDCLASS.
