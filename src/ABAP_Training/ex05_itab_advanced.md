# 練習 5：Internal Table 進階

## 學習目標

- 會用 `SORT ... BY`（含 `DESCENDING`）排序
- 會在 `LOOP` 中修改資料並用 `MODIFY` 寫回（理解「不 MODIFY 改動就丟失」）
- 會用 `DELETE ... WHERE` 整批刪除
- 會用 `lines( )` 取得筆數

## 事前準備

建立程式 `ZR_TR05_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 學生結構加一個「等第」欄位（1 碼字元），建立 4 筆資料（成績：85、92、67、45，**故意不照大小順序**）
2. 輸出原始筆數（`lines( )`）
3. `SORT` 依成績由高到低，輸出全部
4. `LOOP` 逐筆依成績打等第（>=80 是 A、>=60 是 B、其餘 C），用 `MODIFY` 寫回，輸出全部
5. `DELETE ... WHERE` 刪除不及格（<60），輸出剩餘筆數與內容

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
```

## 補充：舊程式裡的 header line

翻舊程式（如本專案的 ZDQM 系列）會看到 `DATA: itab LIKE xxx OCCURS 0 WITH HEADER LINE.` 這種寫法——它讓 `itab` 同時是「表格」也是「work area」，`LOOP AT itab.` 不用 `INTO`。這是**過時語法**，看得懂就好，自己寫一律用「itab + 獨立 work area」的現代寫法。

## 思考題

1. 第 4 步如果拿掉 `MODIFY gt_students FROM gs_student.`，輸出會變怎樣？為什麼？
2. `DELETE gt_students WHERE score < 60.` 和在 LOOP 裡逐筆 `DELETE gt_students.`，哪個好？（提示：LOOP 中刪除當前筆會影響 sy-tabix，是經典陷阱）

## 答案

見 `zr_tr05_itab_advanced.prog.abap`（SAP 端程式 `ZR_TR05_ITAB_ADVANCED`）。
