FUNCTION-POOL zfg_tr15.                     "MESSAGE-ID ..

* INCLUDE LZFG_TR15D...                      " Local class definition

*----------------------------------------------------------------------*
* 練習 15 Part 5：Function Group 的全域變數
*   寫在 TOP include 的 DATA 是「整個 Function Group 共用」的全域變數：
*   ZFG_TR15 裡所有 FM 看到的是同一份，值會保留到這次 session 結束
*   （Z_TR15_ADD_REVENUE 累加、Z_TR15_GET_TOTAL 讀取、Z_TR15_RESET_TOTAL 歸零）
*----------------------------------------------------------------------*
DATA: gv_total_revenue TYPE s_price,        " 累計營收
      gv_call_count    TYPE i.              " 累加了幾次
