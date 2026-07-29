class ZCL_EN06_GREETING2 definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces ZIF_EN05_FLIGHT_GREETING .
protected section.
private section.
ENDCLASS.



CLASS ZCL_EN06_GREETING2 IMPLEMENTATION.

  method ZIF_EN05_FLIGHT_GREETING~GET_GREETING.
    " 第二個 Implementation：示範 Multi Use 依序執行，在前一個 Implementation 的結果後面追加文字
    cv_text = cv_text && | + safe travels, { iv_carrid }! (2nd implementation ZCL_EN06_GREETING2 also fired)|.
  endmethod.
ENDCLASS.