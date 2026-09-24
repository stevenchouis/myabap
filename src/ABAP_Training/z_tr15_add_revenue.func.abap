FUNCTION z_tr15_add_revenue
  IMPORTING
    VALUE(iv_revenue) TYPE s_price.

* 練習 15 Part 5：把一筆營收累加進 Function Group 的全域變數
*   gv_total_revenue／gv_call_count 定義在 TOP include（LZFG_TR15TOP），
*   同一個 Function Group 的其他 FM 讀到的是同一份資料

  gv_total_revenue = gv_total_revenue + iv_revenue.
  gv_call_count    = gv_call_count + 1.

ENDFUNCTION.
