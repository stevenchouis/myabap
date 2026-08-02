# 練習 5：Internal Table 進階

## 學習目標

- 會用 `SORT ... BY`（含 `DESCENDING`）排序
- 會在 `LOOP` 中修改資料並用 `MODIFY` 寫回（理解「不 MODIFY 改動就丟失」）
- 會用 `DELETE ... WHERE` 整批刪除
- 會用 `lines( )` 取得筆數
- 會宣告並操作 **Deep Structure**（結構欄位是一整張表）與巢狀 `LOOP`

## 事前準備

建立程式 `ZR_TR05_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 學生結構加一個「等第」欄位（1 碼字元），建立 4 筆資料（成績：85、92、67、45，**故意不照大小順序**）
2. 輸出原始筆數（`lines( )`）
3. `SORT` 依成績由高到低，輸出全部
4. `LOOP` 逐筆依成績打等第（>=80 是 A、>=60 是 B、其餘 C），用 `MODIFY` 寫回，輸出全部
5. `DELETE ... WHERE` 刪除不及格（<60），輸出剩餘筆數與內容
6. **Deep Structure 練習**：另外宣告一個「學生（含多次小考成績）」的巢狀資料——每位學生的 `EXAMS` 欄位是一整張表（不是另開一張獨立的小考表），建 2 位學生、各 3 次小考成績，用巢狀 `LOOP`（外層學生、內層小考）計算平均分數並輸出

## 預期輸出（範例）

```
原始筆數：          4
=== 依成績由高到低 ===
         1 S0002 李小美         92
         2 S0001 王小明         85
         3 S0003 陳大文         67
         4 S0004 張三豐         45
=== 打上等第 ===
         1 S0002 李小美         92 A
         2 S0001 王小明         85 A
         3 S0003 陳大文         67 B
         4 S0004 張三豐         45 C
=== 刪除不及格後剩          3 筆 ===
         1 S0002 李小美         92 A
         2 S0001 王小明         85 A
         3 S0003 陳大文         67 B
=== Deep Structure：每位學生的小考成績與平均 ===
林小華 第 1 次小考： 78
林小華 第 2 次小考： 85
林小華 第 3 次小考： 90
林小華 平均： 84.3
黃小芳 第 1 次小考： 60
黃小芳 第 2 次小考： 72
黃小芳 第 3 次小考： 55
黃小芳 平均： 62.3
```

## 補充：舊程式裡的 header line

翻舊程式（如本專案的 ZDQM 系列）會看到 `DATA: itab LIKE xxx OCCURS 0 WITH HEADER LINE.` 這種寫法——它讓 `itab` 同時是「表格」也是「work area」，`LOOP AT itab.` 不用 `INTO`。這是**過時語法**，看得懂就好，自己寫一律用「itab + 獨立 work area」的現代寫法。完整說明（`itab[]` 消歧義機制、為什麼是隱藏 bug 來源）見 [lec05](lectures/lec05_itab_advanced.md) 第 8 節。

## 補充：Deep Structure（結構包一整張表）

第 6 題用到的「結構欄位是一整張表」技巧，完整說明（跟講義 3 巢狀結構的差別、常見用途、限制與踩坑）見 [lec05](lectures/lec05_itab_advanced.md) 第 9 節。

## 思考題

1. 第 4 步如果拿掉 `MODIFY gt_students FROM gs_student.`，輸出會變怎樣？為什麼？
2. `DELETE gt_students WHERE score < 60.` 和在 LOOP 裡逐筆 `DELETE gt_students.`，哪個好？（提示：LOOP 中刪除當前筆會影響 sy-tabix，是經典陷阱）
3. 第 6 題的 `ty_student_deep` 是 Deep Structure；如果要把這份資料直接 `INSERT` 進資料庫表，會遇到什麼問題？該怎麼處理？

## 答案

見 `zr_tr05_itab_advanced.prog.abap`（SAP 端程式 `ZR_TR05_ITAB_ADVANCED`）。
