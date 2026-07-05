# 練習 21：建立 Z 資料表與 Open SQL 寫入

> 授課順序：接在練習 15（Function Module）之後、期末實作之前。講義見 [lec21](lectures/lec21_ztable.md)。

## 學習目標

- 會在 SE11 建 Domain、Data Element、透明表（含 Technical Settings、啟用）
- 會產生 Table Maintenance Generator，用 SM30 維護資料
- 會用 `INSERT` / `UPDATE` / `MODIFY` / `DELETE` 寫資料庫，並檢查 `sy-subrc`
- 理解 `COMMIT WORK` / `ROLLBACK WORK` 與 LUW
- 會在 SE11 幫欄位設定**外鍵（Foreign Key／Check Table）**，理解 Header／Detail 兩表關聯
- 會建立 **Search Help** 並掛到 Data Element，理解它跟外鍵的差別（一個是「選」、一個是「擋」）
- 理解外鍵檢查只在**畫面輸入層級**生效，Open SQL 呼叫不受外鍵約束

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

## 第二部分：Header/Detail 關聯——外鍵與 Search Help

`ZTR21_STUD`（Detail，明細：一個學生屬於一個班級）要跟一張新的班級主檔（Header：一個班級有多個學生）串起來。

1. **Domain** `ZTR21_KLASSE`：Data Type `CHAR`，Length `4`（不用設 Value Range，這題重點是外鍵不是值域檢核）→ 啟用
2. **Data Element** `ZTR21_KLASSE`：參考上面的 Domain；Field Label 填「班級代碼」（Short/Medium/Long/Heading 都填）→ 啟用
3. **Domain** `ZTR21_KLNAME`：Data Type `CHAR`，Length `40` → 啟用
4. **Data Element** `ZTR21_KLNAME`：參考上面的 Domain；Field Label 填「班級名稱」→ 啟用
5. **新透明表** `ZTR21_CLASS`（Header／班級主檔）：

| 欄位 | Key | 型別來源 | 說明 |
|---|---|---|---|
| MANDT | ✔ | Data Element `MANDT` | client |
| KLASSE | ✔ | Data Element `ZTR21_KLASSE` | 班級代碼 |
| KLNAME | | Data Element `ZTR21_KLNAME` | 班級名稱 |

   - Delivery Class `A`；Technical Settings 同 `ZTR21_STUD`（Data Class `APPL0`、Size Category `0`）→ 啟用
   - **注意**：`KLNAME` 一定要引用 Data Element（不能直接用內建型別 `CHAR(40)`）——Search Help 的 Parameter 要對應到有 Data Element 的欄位才能正確解析語意，欄位只有內建型別會導致 Search Help **無法 Activate**（實測踩過這個坑，見第 6 點）
6. **`ZTR21_STUD` 加一個欄位 `KLASSE`**（型別 Data Element `ZTR21_KLASSE`，放在 SCORE 之後、UPDUSER 之前）：
   - 在 Fields 頁籤該欄位的 **Foreign Key** 對話框：Check Table 填 `ZTR21_CLASS`，Cardinality 選 `Many : 1`（多個學生對應一個班級），Foreign Key Fields 讓系統自動帶出 `KLASSE = KLASSE`
   - 打開 **Screen Check** 開關（讓畫面輸入時真的會擋不存在的班級代碼）
   - 存檔啟用
7. **Search Help** `ZTR21_CLASSH`（SE11 → Search Help → Elementary Search Help）：
   - Selection Method：`ZTR21_CLASS`
   - Search Help Parameters：`KLASSE`（勾 Import Parameter + Export Parameter + SelOnScr，設為 SH field／LPos 1）、`KLNAME`（只勾 Export Parameter，LPos 2，純顯示用）
   - 存檔啟用，套件 `$TMP`——若 Activate 失敗報錯跟欄位語意/Data Element 有關，回頭檢查 `ZTR21_CLASS` 的欄位是不是都掛了 Data Element（見第 5 點）
   - 回到 Data Element `ZTR21_KLASSE` → Change → **Further Characteristics** 頁籤 → Search Help 欄位填 `ZTR21_CLASSH` → 存檔啟用
   - 到 SM30 或任一輸入 KLASSE 的畫面按 F4，應該能選出班級清單
8. 觀察差異：SM30 輸入一個 `ZTR21_CLASS` 沒有的班級代碼 → **外鍵**會擋下來報錯；按 F4 選班級 → **Search Help** 讓你用選的不用背代碼。兩者可以疊加，但意義不同。

## 第三部分：程式寫入 ZR_TR21_&lt;縮寫&gt;

依序完成（**每一步都檢查 `sy-subrc` 並輸出結果**）：

1. 開場防呆：`DELETE FROM ztr21_stud WHERE id LIKE 'S00%'.`（清掉本程式的舊測試資料，讓程式可重跑；不要刪到 SM30 手動建的 S9001）
2. `INSERT` 單筆 `S0001 王小明 85`（帶 `UPDUSER = sy-uname`、`UPDDATE = sy-datum`）
3. 再 `INSERT` 一次同一筆——觀察 `sy-subrc = 4`（主鍵重複不會蓋掉）
4. 用 `INSERT ... FROM TABLE` 批次新增 `S0002 李小美 92`、`S0003 陳大文 67`（加 `ACCEPTING DUPLICATE KEYS`）
5. `UPDATE ... SET score = 90 WHERE id = 'S0001'`
6. `MODIFY`：對 `S0004 張三豐 45`（不存在 → 變新增）、再對 `S0004` 改成 75（存在 → 變修改），各印 sy-subrc
7. `DELETE FROM ... WHERE id = 'S0003'`
8. 最後 `SELECT ... INTO TABLE` 把全表撈出來 LOOP 輸出，跟 SE16N 對照
9. 準備 Header 測試資料：`INSERT` 一筆 `ZTR21_CLASS`（`S101` / 資訊一班）
10. `INSERT` 一筆帶合法 `KLASSE = 'S101'` 的學生（`S0005`）——正常成功
11. **重點**：`INSERT` 一筆帶**不存在**的 `KLASSE`（如 `'ZZZZ'`）的學生（`S0006`）——觀察 `sy-subrc` 是否仍是 0，並想清楚為什麼（外鍵是畫面層防呆，不是資料庫 constraint）
12. 用 `LEFT OUTER JOIN` 把 `ZTR21_STUD` 和 `ZTR21_CLASS` 串起來，印出「學號／姓名／班級代碼／班級名稱」（用 LEFT OUTER 是因為第 11 步的 `ZZZZ` 在 `ZTR21_CLASS` 查不到，INNER JOIN 會漏掉這筆）
13. 結尾 `COMMIT WORK.`，並在任一步 sy-subrc 異常時示範 `ROLLBACK WORK.` 的寫法（可用註解說明）

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
INSERT 班級 S101（資訊一班）：sy-subrc = 0
INSERT S0005（KLASSE=S101，合法班級）：sy-subrc = 0
INSERT S0006（KLASSE=ZZZZ，班級不存在）：sy-subrc = 0
  → 對比：sy-subrc = 0，程式端 INSERT 依然成功！
  → DDIC 外鍵是「畫面層防呆」（SM30/Dynpro 才會擋），不是「資料庫層 constraint」，
     Open SQL 呼叫不會被擋下來，資料正確性仍要靠程式自行檢查。
=== 學生 JOIN 班級（學號／姓名／班級代碼／班級名稱） ===
S0001 王小明
S0002 李小美
S0004 張三豐
S0005 林小華      S101 資訊一班
S0006 吳小芳      ZZZZ
S9001 測試員
```

## 思考題

1. SCORE 欄位如果直接用內建 `INT4` 不建 Domain/Data Element，會少掉哪些東西？（欄位標籤、F1、值域檢核）
2. `MODIFY` 和「先 READ 再決定 INSERT 或 UPDATE」相比，什麼情況下不能用 MODIFY？（提示：要區分「新增」與「修改」走不同邏輯時）
3. 如果程式在第 5 步之後 dump，前面寫入的資料還在嗎？跟 COMMIT WORK 的位置有什麼關係？
4. 外鍵設定了 Screen Check，為什麼 `ZR_TR21_ZTABLE` 用 `INSERT` 寫入不存在的班級代碼還是成功？如果要讓程式也擋下這種資料，該怎麼做？（提示：程式要自己 `SELECT SINGLE` 檢查 `ZTR21_CLASS` 存不存在該筆）
5. 外鍵（Foreign Key）跟 Search Help 都跟 KLASSE 欄位有關，兩者分別解決什麼問題？只設 Search Help 不設外鍵、或只設外鍵不設 Search Help，各會發生什麼使用體驗上的問題？

## 答案

見 `zr_tr21_ztable.prog.abap`（SAP 端程式 `ZR_TR21_ZTABLE`）；資料表定義以本題目第一、二部分為準，快照見 `ztr21_stud.tabl.abap`、`ztr21_class.tabl.abap`。Domain／Data Element／Search Help 無程式碼快照（DDIC metadata 物件，非 source-based）。

