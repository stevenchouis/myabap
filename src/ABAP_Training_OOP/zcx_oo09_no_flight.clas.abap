CLASS zcx_oo09_no_flight DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

* OOP 練習 9：自訂例外——查無航班
*   繼承 CX_STATIC_CHECK：呼叫端「不宣告也不處理就編譯不過」（團隊規範預設）
*   例外物件可以帶資料（mv_carrid）——比 sy-subrc 只有一個數字強得多
  PUBLIC SECTION.
    DATA mv_carrid TYPE s_carr_id READ-ONLY.

    METHODS:
      constructor IMPORTING iv_carrid TYPE s_carr_id
                            previous  LIKE previous OPTIONAL,
      get_text REDEFINITION.
ENDCLASS.

CLASS zcx_oo09_no_flight IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_carrid = iv_carrid.
  ENDMETHOD.

  METHOD get_text.
    result = |航空公司 { mv_carrid } 查無航班資料|.
  ENDMETHOD.
ENDCLASS.
