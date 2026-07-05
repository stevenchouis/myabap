# 練習 19：用 Debugger 抓出三個 bug

> 授課順序：接在練習 5 之後。講義見 [lec19](lectures/lec19_debugging.md)。

## 學習目標

- 會用 Session 中斷點 + F5/F6/F7/F8 追蹤程式
- 會在 Debugger 裡看變數、看 internal table、看 `sy-subrc`
- 會從 ST22 dump 紀錄找到案發行與變數值
- 建立除錯紀律：**先定位證據、再動手修**

## 事前準備

建立程式 `ZR_TR19_<你的姓名縮寫>`，套件 `$TMP`，把下方「有 bug 的程式」原封不動貼進去、啟用。

## 有 bug 的程式（照抄，先別修！）

```abap
REPORT zr_tr19_buggy.
* 需求：全班加 5 分後，計算「達門檻的學生」平均分數，再查詢指定學號
TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
       END OF ty_student.
DATA: gt_students TYPE STANDARD TABLE OF ty_student WITH NON-UNIQUE KEY id,
      gs_student  TYPE ty_student,
      gv_sum      TYPE i,
      gv_count    TYPE i,
      gv_avg      TYPE p LENGTH 6 DECIMALS 2.

PARAMETERS p_min TYPE i DEFAULT 60.

START-OF-SELECTION.
  gs_student-id = 'S0001'. gs_student-name = '王小明'. gs_student-score = 85.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0002'. gs_student-name = '李小美'. gs_student-score = 92.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0003'. gs_student-name = '陳大文'. gs_student-score = 67.
  APPEND gs_student TO gt_students.
  gs_student-id = 'S0004'. gs_student-name = '張三豐'. gs_student-score = 45.
  APPEND gs_student TO gt_students.

* 全班加 5 分
  LOOP AT gt_students INTO gs_student.
    gs_student-score = gs_student-score + 5.
  ENDLOOP.

* 達門檻的平均
  CLEAR: gv_sum, gv_count.
  LOOP AT gt_students INTO gs_student WHERE score >= p_min.
    gv_sum   = gv_sum + gs_student-score.
    gv_count = gv_count + 1.
  ENDLOOP.
  gv_avg = gv_sum / gv_count.
  WRITE: / '達門檻人數：', gv_count, '平均：', gv_avg.

* 查詢指定學號
  READ TABLE gt_students INTO gs_student WITH KEY id = 'S9999'.
  WRITE: / 'S9999 的成績：', gs_student-score.
```

## 題目需求

程式藏了 **3 個 bug**。規則：每個 bug 都要**先用 Debugger 拿到證據**（哪一行、哪個變數、什麼值），寫下來，然後才修正。

1. **Bug A（症狀）**：用預設 `p_min = 60` 執行，張三豐 45+5=50 沒達標是對的，但其他人的平均是 81.33——手算 (90+97+72)/3 應該是 86.33。加分好像沒生效？
   - 要求：在「加 5 分」迴圈的 ENDLOOP 後設中斷點，用 Table 檢視看 `gt_students` 的 score 欄——證明表格內容根本沒變，說出為什麼
2. **Bug B（症狀）**：把 `p_min` 改成 `999` 執行，程式直接 dump
   - 要求：先到 ST22 找這筆 dump，記下 Runtime Error 名稱與案發行；再用 Debugger 重跑，停在該行前看 `gv_count` 的值
3. **Bug C（症狀）**：最後一行輸出「S9999 的成績」永遠有值，但 S9999 根本不存在
   - 要求：在 READ TABLE 那行後設中斷點，看 `sy-subrc` 與 `gs_student` 的內容——解釋這個值是哪裡來的
4. 三個 bug 全修正後重跑：`p_min = 60` 輸出正確平均；`p_min = 999` 顯示「無人達門檻」不 dump；S9999 顯示「查無此學號」
5. 加碼（選做）：對 `gv_sum` 設 Watchpoint，重跑一次觀察它在哪幾行被改動

## 預期輸出（修正版，p_min = 60）

```
達門檻人數：          3 平均：      86.33
查無此學號 S9999
```

## 思考題

1. Bug A 的另一種修法是 `LOOP AT ... ASSIGNING`（講義 16 會教）——為什麼那樣寫連 MODIFY 都不用？
2. Bug B 這類「特定輸入才爆」的問題，為什麼測試時要刻意餵極端值（0、超大值、空值）？
3. Bug C 若當初宣告時就養成 READ 後檢查 sy-subrc 的反射動作，這個 bug 有機會存在嗎？

## 答案

見 `zr_tr19_debugging.prog.abap`（SAP 端程式 `ZR_TR19_DEBUGGING`，修正版，含每個 bug 的註解說明）。
