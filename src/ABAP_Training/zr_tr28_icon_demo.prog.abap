REPORT zr_tr28_icon_demo NO STANDARD PAGE HEADING LINE-SIZE 120.

* 講義 28 §7.1：SAP 圖示的使用
*   1. 選擇畫面工具列按鈕加圖示（FUNCTION KEY ＋ SMP_DYNTXT）
*   2. 選擇畫面上的按鈕加圖示（PUSHBUTTON ＋ ICON_CREATE）
*   3. 清單輸出圖示（WRITE ... AS ICON）
*   4. 圖示＋文字＋提示一起組好再輸出（ICON_CREATE）
* 圖示常數（icon_xxx）來自 Type Group ICON，7.02 之後不必寫 TYPE-POOLS 也能直接用

TABLES sscrfields.                              " 選擇畫面功能鍵

DATA: gs_functxt TYPE smp_dyntxt,
      gv_icon    TYPE c LENGTH 60,               " ICON_CREATE 的輸出
      gv_len     TYPE i.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN PUSHBUTTON /1(20) b_run USER-COMMAND zrun.
PARAMETERS p_level TYPE c LENGTH 1 DEFAULT 'W'.  " S=正常 W=警告 E=錯誤

INITIALIZATION.
* 1. 工具列按鈕：圖示＋按鈕文字＋滑鼠提示
  gs_functxt-icon_id   = icon_tools.
  gs_functxt-icon_text = '工具'.
  gs_functxt-quickinfo = '開啟維護工具'.
  sscrfields-functxt_01 = gs_functxt.

* 2. 畫面上的按鈕：ICON_CREATE 組出「圖示＋文字＋提示」放進按鈕文字欄位
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name                  = icon_execute_object
      text                  = '執行檢查'
      info                  = '依等級顯示結果'
    IMPORTING
      result                = b_run
    EXCEPTIONS
      icon_not_found        = 1
      outputfield_too_short = 2
      OTHERS                = 3.
  IF sy-subrc <> 0.
    b_run = '執行檢查'.
  ENDIF.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      MESSAGE '按了工具列的「工具」按鈕' TYPE 'S'.
    WHEN 'ZRUN'.
      MESSAGE '按了畫面上的「執行檢查」按鈕' TYPE 'S'.
  ENDCASE.

START-OF-SELECTION.
* 圖示常數的內容：就是 4 個字元的內部代碼
  WRITE: / 'icon_tools 的內容：', icon_tools.
  gv_len = strlen( icon_tools ).
  WRITE: / 'icon_tools 的長度：', gv_len.
  SKIP.

* 3. 清單輸出圖示：加 AS ICON，畫面上顯示成圖，不是代碼
  WRITE: / icon_green_light  AS ICON, '正常',
         / icon_yellow_light AS ICON, '警告',
         / icon_red_light    AS ICON, '錯誤'.
  SKIP.

* 依資料決定顯示哪個燈號
  CASE p_level.
    WHEN 'S'.
      WRITE / icon_green_light AS ICON.
    WHEN 'W'.
      WRITE / icon_yellow_light AS ICON.
    WHEN OTHERS.
      WRITE / icon_red_light AS ICON.
  ENDCASE.
  WRITE '檢查結果'.
  SKIP.

* 4. ICON_CREATE：圖示＋文字＋滑鼠提示一起組好
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name                  = icon_okay
      text                  = '處理完成'
      info                  = '全部資料已處理'
    IMPORTING
      result                = gv_icon
    EXCEPTIONS
      icon_not_found        = 1
      outputfield_too_short = 2
      OTHERS                = 3.
  IF sy-subrc = 0.
    WRITE: / 'ICON_CREATE 的結果：', gv_icon.
    WRITE: / gv_icon AS ICON.
  ENDIF.
