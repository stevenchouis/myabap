# 練習 21：建立 Z 資料表與 Open SQL 寫入

> 授課順序：接在練習 15（Function Module）之後、期末實作之前。講義見 [lec21](lectures/lec21_ztable.md)。

## 學習目標

- 會在 SE11 建 Domain、Data Element、透明表（含 Technical Settings、啟用）
- 會產生 Table Maintenance Generator，用 SM30 維護資料
- 會用 `INSERT` / `UPDATE` / `MODIFY` / `DELETE` 寫資料庫，並檢查 `sy-subrc`
- 理解 `COMMIT WORK` / `ROLLBACK WORK` 與 LUW

## 事前準備

物件都建在套件 `$TMP`。名稱請照下表（多人共用系統時，照課程慣例把 `TR21` 換成 `TR21_<縮寫>`，並同步調整程式中的表名）。

## 第一部分：SE11 建 DDIC 物件

1. **Domain** `ZTR21_SCORE`：Data Type `INT4`；Value Range 頁籤設 Interval `0`～`999`（體驗值域檢核）→ 啟用
2. **Data Element** `ZTR21_SCORE`：參考上面的 Domain；Field Label 填「學生成績」（Short/Medium/Long 都填）→ 啟用
3. **透明表** `ZTR21_STUD`：
   - Delivery Class `A`；Data Browser/Table View Maint. 選 `Display/Maintenance Allowed`
   - 欄位（Key 欄勾選 Key + Initial Values）：

| 欄位 | Key | 型別來源 | 說明 |
|---|---|---|---|
| MANDT | ✔ | Data Element `MANDT` | client（第一欄，必備） |
| ID | ✔ | 內建型別 `CHAR` 5 | 學號 |
| NAME | | 內建型別 `CHAR` 40 | 姓名 |
| SCORE | | Data Element `ZTR21_SCORE` | 成績（自建三層件） |
| UPDUSER | | Data Element `SYUNAME` | 異動者（標準 DE） |
| UPDDATE | | Data Element `SYDATUM` | 異動日（標準 DE） |

   - Technical Settings：Data Class `APPL0`、Size Category `0`
   - 啟用後用 SE16N 確認表存在（0 筆）
4. **維護畫面**：Utilities → Table Maintenance Generator：Authorization Group `&NC&`、Function Group `ZFG_TR21`、one step → 產生；到 SM30 手動新增一筆 `S9001 測試員 50`，再回 SE16N 確認
5. 觀察三層件的效果：SE16N 裡 SCORE 欄位標籤顯示「學生成績」；SM30 輸入 1000 會被 Domain 值域擋下

## 第二部分：程式寫入 ZR_TR21_&lt;縮寫&gt;

依序完成（**每一步都檢查 `sy-subrc` 並輸出結果**）：

1. 開場防呆：`DELETE FROM ztr21_stud WHERE id LIKE 'S00%'.`（清掉本程式的舊測試資料，讓程式可重跑；不要刪到 SM30 手動建的 S9001）
2. `INSERT` 單筆 `S0001 王小明 85`（帶 `UPDUSER = sy-uname`、`UPDDATE = sy-datum`）
3. 再 `INSERT` 一次同一筆——觀察 `sy-subrc = 4`（主鍵重複不會蓋掉）
4. 用 `INSERT ... FROM TABLE` 批次新增 `S0002 李小美 92`、`S0003 陳大文 67`（加 `ACCEPTING DUPLICATE KEYS`）
5. `UPDATE ... SET score = 90 WHERE id = 'S0001'`
6. `MODIFY`：對 `S0004 張三豐 45`（不存在 → 變新增）、再對 `S0004` 改成 75（存在 → 變修改），各印 sy-subrc
7. `DELETE FROM ... WHERE id = 'S0003'`
8. 最後 `SELECT ... INTO TABLE` 把全表撈出來 LOOP 輸出，跟 SE16N 對照
9. 結尾 `COMMIT WORK.`，並在任一步 sy-subrc 異常時示範 `ROLLBACK WORK.` 的寫法（可用註解說明）

## 預期輸出（範例）

```
清除舊測試資料：        2 筆
INSERT S0001：成功
再 INSERT S0001：sy-subrc =          4 （主鍵重複）
批次 INSERT：完成
UPDATE S0001 成績 90：成功
MODIFY S0004（新增）：成功
MODIFY S0004（修改為 75）：成功
DELETE S0003：成功
=== 目前表內容 ===
S0001 王小明             90
S0002 李小美             92
S0004 張三豐             75
S9001 測試員             50
```

## 思考題

1. SCORE 欄位如果直接用內建 `INT4` 不建 Domain/Data Element，會少掉哪些東西？（欄位標籤、F1、值域檢核）
2. `MODIFY` 和「先 READ 再決定 INSERT 或 UPDATE」相比，什麼情況下不能用 MODIFY？（提示：要區分「新增」與「修改」走不同邏輯時）
3. 如果程式在第 5 步之後 dump，前面寫入的資料還在嗎？跟 COMMIT WORK 的位置有什麼關係？

## 答案

見 `zr_tr21_ztable.prog.abap`（SAP 端程式 `ZR_TR21_ZTABLE`；資料表定義以本題目第一部分為準，DDIC 物件無程式碼快照）。
