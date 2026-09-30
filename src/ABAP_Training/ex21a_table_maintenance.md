# 練習 21a：Maintenance View 與 JOIN 串 Z 表

> 授課順序：接在練習 12（列印排版）之後、練習 13（第一階段總整理）之前——總整理的傳票清單用到唯讀 Maintenance View（會計主管表 `ZFI0037` 的查詢按鈕），也要讀 Z 表。延續[練習 21](ex21_ztable.md) 建好的 `ZTR21_STUD`／`ZTR21_CLASS` 與 SM30 維護畫面；JOIN 要先學練習 11。講義見 [lec21a](lectures/lec21a_table_maintenance.md)。

## 學習目標

- 會建 Maintenance View，並用 `Read only` 做成查詢專用
- 會用 LEFT OUTER JOIN 串 Header／Detail 兩張 Z 表，並找出外鍵沒擋住的髒資料

## 事前準備

- 已完成練習 21：`ZTR21_STUD`、`ZTR21_CLASS`、Search Help `ZTR21_CLASSH`、Function Group `ZFG_TR21` 的 SM30 維護畫面都已完成，也跑過 `ZR_TR21_ZTABLE`（表裡有 `S0001`～`S0006`、`S9001` 與班級 `S101`）。
- 物件都建在套件 `$TMP`。多人共用系統時，照課程慣例把 `TR21` 換成 `TR21_<縮寫>`。

## 第一部分：唯讀的 Maintenance View

建一個「學生＋班級名稱」的查詢專用畫面：

1. SE11 → View → 輸入 `ZV_TR21_STUD` → Create → 選 **Maintenance view**
2. Table/Join Conditions：主表 `ZTR21_STUD` → **Relationships** → 勾 `ZTR21_CLASS`（系統依 `KLASSE` 外鍵帶出連接條件）
3. View Fields：`ZTR21_STUD` 的 `MANDT`、`ID`、`NAME`、`SCORE`、`KLASSE`，加上 `ZTR21_CLASS` 的 `KLNAME`
4. Maint. Status：Access 選 **`Read only`**
5. 啟用 → Utilities → Table Maintenance Generator（Function Group 同樣填 `ZFG_TR21`）→ 產生
6. SM30 輸入 `ZV_TR21_STUD` → 觀察：只能顯示，畫面上**沒有** Change／Display 切換按鈕；同一列看得到學生與班級名稱

> Maintenance View 是 INNER JOIN：班級代碼是 `ZZZZ`（不存在）或空白的學生，在這個 View 裡看不到。

## 第二部分：程式 ZR_TR21A_&lt;縮寫&gt;

1. 用 `LEFT OUTER JOIN` 把 `ZTR21_STUD`（別名 `s`）和 `ZTR21_CLASS`（別名 `c`）串起來，讀出「學號／姓名／班級代碼／班級名稱」，依學號排序
2. 逐筆輸出；如果班級代碼有值、班級名稱卻是空的，在後面標示「班級不存在」
3. 最後輸出「班級不存在」的筆數
4. `SELECT` 之後檢查 `sy-subrc`，查無資料時輸出提示

## 預期輸出（範例）

```
=== 學生 JOIN 班級（學號／姓名／班級代碼／班級名稱） ===
S0001 王小明
S0002 李小美
S0004 張三豐
S0005 林小華      S101 資訊一班
S0006 吳小芳      ZZZZ                  ← 班級不存在
S9001 測試員
班級不存在：         1 筆
```

> `S9001` 是練習 21 在 SM30 手動建的，班級欄位依你當時的輸入顯示（留空就是空白）。

## 思考題

1. 第一部分的 Maintenance View 看不到 `S0006`（班級 `ZZZZ`），第二部分的程式卻看得到。差別在哪裡？如果要做成 F4 選單、又希望所有學生都出現，該用哪一種 View？（提示：講義 21a 第 2 節 Help View）
2. 為什麼 `ON` 條件不能寫 `c~mandt = s~mandt`？
3. `S0006` 這種「班級不存在」的資料是怎麼進來的？練習 21 的 SM30 擋得住，還有哪些路徑會寫進這種資料？要從根本防止，程式寫入前該做什麼？

## 答案

- Maintenance View：GUI 操作，無程式碼快照。
- 程式：見 `zr_tr21a_join.prog.abap`（SAP 端程式 `ZR_TR21A_JOIN`）。
