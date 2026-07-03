# 練習 3：Local Type 與 Structure

## 學習目標

- 會用 `TYPES: BEGIN OF ... END OF` 定義自訂結構型別
- 理解 `TYPES`（藍圖，不佔記憶體）與 `DATA`（實際變數，佔記憶體）的差別
- 會用 `-` 存取結構欄位
- 會做結構整筆複製，並理解複製後是兩份獨立資料
- 延續練習 2：對結構變數同樣可以用 `LIKE`

## 事前準備

建立程式 `ZR_TR03_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 用 `TYPES: BEGIN OF ty_student ... END OF ty_student.` 定義學生結構：學號（5 碼字元）、姓名（字串）、期中成績（整數）、期末成績（整數）、平均（小數 1 位）
2. 用 `TYPE ty_student` 宣告結構變數 `gs_student`，再用 `LIKE gs_student` 宣告 `gs_backup`
3. 給 `gs_student` 各欄位填值，平均由期中期末計算
4. 把 `gs_student` 整筆複製給 `gs_backup`
5. **複製後**修改 `gs_student` 的姓名，然後把 `gs_backup` 全部欄位輸出、再輸出 `gs_student` 的姓名——觀察備份有沒有被影響

## 預期輸出（範例）

```
=== 備份結構（複製後不受原結構修改影響）===
學號： S0001
姓名： 王小明
期中：         78
期末：         91
平均：       84.5
=== 原結構（姓名已被修改）===
姓名： 此欄已被改掉
```

## 思考題

1. 把第 1 步的 `TYPES` 改成 `DATA: BEGIN OF ... END OF ...`（舊寫法）也能跑，兩者差在哪？為什麼團隊要求用 `TYPES`？
2. 如果要 10 個學生，用 10 個結構變數顯然不對——這就是下一課 Internal Table 要解決的問題

## 提示

- 結構欄位存取：`gs_student-name = '王小明'.`（連字號，不是點）
- 整筆複製就是一個等號：`gs_backup = gs_student.`

## 答案

見 `zr_tr03_structures.prog.abap`（SAP 端程式 `ZR_TR03_STRUCTURES`）。
