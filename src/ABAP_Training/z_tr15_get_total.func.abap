FUNCTION z_tr15_get_total
  EXPORTING
    VALUE(ev_total) TYPE s_price
    VALUE(ev_count) TYPE i.

* 練習 15 Part 5：讀出 Z_TR15_ADD_REVENUE 累加的結果
*   這支 FM 自己沒有做任何累加，只是讀同一個 Function Group 的全域變數

  ev_total = gv_total_revenue.
  ev_count = gv_call_count.

ENDFUNCTION.
