*&---------------------------------------------------------------------*
*& Report  ZR_TR15_FG_SHARED
*& 練習 15 Part 5：同一個 Function Group 的多個 FM 共用全域變數
*& 前提：Function Group ZFG_TR15 的 TOP include（LZFG_TR15TOP）已宣告
*&       gv_total_revenue／gv_call_count，並建好三支 FM：
*&       Z_TR15_ADD_REVENUE（累加）、Z_TR15_GET_TOTAL（讀取）、Z_TR15_RESET_TOTAL（歸零）
*&---------------------------------------------------------------------*
REPORT zr_tr15_fg_shared.

DATA: gv_total TYPE s_price,
      gv_count TYPE i.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 1) 還沒累加任何東西就先讀：全域變數還是初始值
*    （Function Group 第一次被呼叫時才載入記憶體，全域變數從初始值開始）
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_GET_TOTAL'
    IMPORTING
      ev_total = gv_total
      ev_count = gv_count.
  WRITE / '=== 1) 尚未累加就先讀 ==='.
  WRITE: / '累計營收', gv_total, '／ 累加次數', gv_count.       " 輸出：0.00／0

*----------------------------------------------------------------------*
* 2) 呼叫 ADD_REVENUE 三次：每次只傳「這一筆」的營收，沒有任何變數帶回呼叫端
*    累加的結果存在 Function Group 的全域變數裡
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_ADD_REVENUE' EXPORTING iv_revenue = '50000.00'.
  CALL FUNCTION 'Z_TR15_ADD_REVENUE' EXPORTING iv_revenue = '40000.00'.
  CALL FUNCTION 'Z_TR15_ADD_REVENUE' EXPORTING iv_revenue = '36000.00'.

*----------------------------------------------------------------------*
* 3) 換另一支 FM（GET_TOTAL）讀：它自己沒有累加，卻讀得到前一支 FM 累加的結果
*    ——因為兩支 FM 同屬 ZFG_TR15，看到的是同一份全域變數
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_GET_TOTAL'
    IMPORTING
      ev_total = gv_total
      ev_count = gv_count.
  WRITE / '=== 2) 累加三筆後，由另一支 FM 讀出 ==='.
  WRITE: / '累計營收', gv_total, '／ 累加次數', gv_count.       " 輸出：126,000.00／3

*----------------------------------------------------------------------*
* 4) RESET 歸零後再讀
*----------------------------------------------------------------------*
  CALL FUNCTION 'Z_TR15_RESET_TOTAL'.
  CALL FUNCTION 'Z_TR15_GET_TOTAL'
    IMPORTING
      ev_total = gv_total
      ev_count = gv_count.
  WRITE / '=== 3) RESET 之後 ==='.
  WRITE: / '累計營收', gv_total, '／ 累加次數', gv_count.       " 輸出：0.00／0

* 注意：全域變數只活在「這次 session 的這個 Function Group」裡——
*   程式結束、或另開一個 session 就是全新的一份（同一個 session 內，
*   Function Group 還在記憶體時，值會一直保留，所以重複使用前要先 RESET）。
