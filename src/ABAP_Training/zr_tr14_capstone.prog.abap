*&---------------------------------------------------------------------*
*& Report  ZR_TR14_CAPSTONE
*& 練習 14：INCLUDE 拆檔——主程式只剩「骨架」（答案程式）
*&---------------------------------------------------------------------*
* 實務慣例：
*   <程式名>_TOP：全域宣告（TYPES / DATA / 選擇畫面）
*   <程式名>_F01：FORM 副程式（依功能可再拆 F02、F03...）
* 主程式只留 INCLUDE 與事件流程，一眼看懂整支程式的結構
* 本專案實例：ZDQM0001 + ZDQM0001F01
*
* 注意：INCLUDE 只是「原地展開」的程式碼片段，
*       跟直接寫在主程式裡完全等價——拆檔是為了「人」好維護
*&---------------------------------------------------------------------*
REPORT zr_tr14_capstone.

INCLUDE zr_tr14_top.        " 全域宣告

INITIALIZATION.
  t_b1 = '查詢條件'.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display_data.

* FORM 的 INCLUDE 放最後：避免 FORM 定義插在事件中間造成
* 「statement not accessible」錯誤
INCLUDE zr_tr14_f01.        " FORM 副程式