*&---------------------------------------------------------------------*
*& Subroutine Pool  ZR_TR08_POOL
*& 練習 8 選修：Subroutine Pool（副程式池）——只放 FORM、給別的程式呼叫
*&---------------------------------------------------------------------*
* 建立方式（GUI-only，ADT 無法設定程式類型）：
*   SE38 → 輸入 ZR_TR08_POOL → Create → Type 選「Subroutine Pool」
*   （已建好的程式改類型：Goto → Attributes → Type 改成 Subroutine Pool）
* Subroutine Pool 的特性：
*   - 第一行用 PROGRAM，不是 REPORT（沒有選擇畫面、沒有事件、不能 F8 直接執行）
*   - 只放 FORM 定義，由別的程式用 PERFORM ... IN PROGRAM 呼叫
*   - 呼叫時才被載入記憶體（載入時會觸發 LOAD-OF-PROGRAM 事件）
*&---------------------------------------------------------------------*
PROGRAM zr_tr08_pool.

*&---------------------------------------------------------------------*
*&      Form  calc_grade
*&      USING    ：輸入成績
*&      CHANGING ：輸出等第（>=80 A、>=60 B、其餘 C）
*&      注意：呼叫端的參數個數、順序、型別，編譯時完全不會被檢查——
*&            介面寫錯要到執行期才爆（這是跨程式 FORM 被列為過時的主因）
*&---------------------------------------------------------------------*
FORM calc_grade USING    iv_score TYPE i
                CHANGING cv_grade TYPE c.
  IF iv_score >= 80.
    cv_grade = 'A'.
  ELSEIF iv_score >= 60.
    cv_grade = 'B'.
  ELSE.
    cv_grade = 'C'.
  ENDIF.
ENDFORM.
