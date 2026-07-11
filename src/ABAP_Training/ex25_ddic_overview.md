# 練習 25：Data Dictionary 總覽與 Global Type

> 授課順序：接在練習 15（Function Module）之後、練習 21（Z 資料表）之前。講義見 [lec25](lectures/lec25_ddic_overview.md)。

## 學習目標

- 理解 **Global Type**：引用 DDIC 型別（而非寫死長度）能讓程式在標準系統升級時自動跟著調整
- 會判斷「重用標準 Data Element」vs「自建 Domain/Data Element」的時機
- 會建立 Check Table **指向標準表**（而非自建表）的外鍵
- 體會「重用已掛 Search Help 的標準 Data Element」可以**完全不用自己建** Search Help
- 會在程式中用三種寫法引用 DDIC 物件：`TYPE ztable`、`TYPE ztable-field`、`TYPE STANDARD TABLE OF ztable`
- 會建 **DDIC Table Type**：把講義 4 的區域表格型別升級成可跨程式共用的 SE11 物件
- 會建 SM30 維護畫面，並寫程式讀取它、應用在報表邏輯上

## 事前準備

物件都建在套件 `$TMP`。名稱請照下表（多人共用系統時，照課程慣例把 `TR25` 換成 `TR25_<縮寫>`，並同步調整程式中的表名）。SFLIGHT/SCARR 要有資料（`SAPBC_DATA_GENERATOR`，練習 6 應已跑過）。

## 第一部分：SE11 建 DDIC 物件

1. **Domain** `ZTR25_SURPCT`：Data Type `DEC`，Length `6`、Decimals `2`；Value Range 頁籤設 Interval `0`～`100`（**注意：固定值上下限要填整數，DEC 型別的值域邊界不接受小數點**）→ 啟用
2. **Data Element** `ZTR25_SURPCT`：參考上面的 Domain；Field Label 填「旺季加成百分比」（Short/Medium/Long 都填）→ 啟用
3. **Data Element** `ZTR25_ACTIVE`（**第三種 Global Type 模式**：重用標準 Domain，但自己補標籤）：Domain 填標準的 **`XFELD`**（SE11 F4 搜尋，這是 SAP 內建的通用「是/否」旗標值域，本身已經有 `X`＝是／空白＝否 兩個固定值，F4 選單免費附送）；Field Label 自己填「加成啟用」（Short/Medium/Long 都填，`XFELD` 這個標準 Data Element 本身故意不帶標籤，就是留給每張表自己命名）→ 啟用
4. **透明表** `ZTR25_SURCHG`：

| 欄位 | Key | 型別來源 | 說明 |
|---|---|---|---|
| MANDT | ✔ | Data Element `MANDT` | client（第一欄，必備） |
| CARRID | ✔ | **標準 Data Element `S_CARR_ID`**（SE11 F4 搜尋既有 Data Element，不要自己建！） | 航空公司代碼 |
| ACTIVE | | Data Element `ZTR25_ACTIVE`（第 3 步自建，重用標準 Domain `XFELD`） | 是否啟用加成 |
| SURCHARGE_PCT | | Data Element `ZTR25_SURPCT` | 加成百分比 |
| UPDUSER | | Data Element `SYUNAME` | 異動者 |
| UPDDATE | | Data Element `SYDATUM` | 異動日 |

   - `CARRID` 欄位的 **Foreign Key** 對話框：Check Table 填 **`SCARR`**（標準表）、Cardinality 選 `[0..1] : 1`、Foreign Key Fields 自動帶出 `CARRID = CARRID`，打開 **Screen Check**
   - Delivery Class `A`；Technical Settings：Data Class `APPL0`、Size Category `0`
   - 存檔啟用
5. **Table Type** `ZTR25_TT_SURCHG`：SE11 → Data Type → Create → 選 **Table Type**；Line Type 填 `ZTR25_SURCHG`（直接拿表格本身當 Line Type，不用重新定義欄位）；Access Mode 選 `Standard Table`，Key 用預設（Default Key）→ 啟用。這是把「表格型別」也升級成可跨程式共用的 DDIC 物件（對照講義 4 的 Local Type）。
6. **維護畫面**：Utilities → Table Maintenance Generator：Authorization Group `&NC&`、Function Group `ZFG_TR25`、one step → 產生
7. SM30 → `ZTR25_SURCHG` → 新增兩筆：`AA` / 啟用打勾 / `15.00`、`LH` / 啟用打勾 / `10.00`
8. **驗證重用標準型別的三個免費好處**（不用你多做任何事）：
   - `CARRID` 欄位按 F4：應該直接出現航空公司選單
   - 手動輸入一個 `SCARR` 沒有的代碼（如 `ZZ`）：畫面應該擋下來報錯
   - `ACTIVE` 欄位：應該有正確的中文欄位標題（不是通用符號 `+`），按 F4 應該出現「是／否」選單——這是重用標準 Domain `XFELD` 的固定值清單換來的

> **踩坑記錄**：如果 `ACTIVE` 圖方便直接用內建型別 `CHAR 1`（沒有掛任何 Data Element），SM30 畫面會發生兩件事：欄位標題顯示成通用符號 `+`（因為沒有 Data Element 可以提供標籤），而且完全沒有 F4 下拉選單（沒有 Domain 固定值清單）。改用「重用標準 Domain `XFELD`＋自建 Data Element 補標籤」兩個問題一次解決——這也是本講第三種 Global Type 模式：不是整個 Data Element 都重用（如 `S_CARR_ID`），也不是完全自建（如 `ZTR25_SURPCT`），而是**只重用 Domain 的技術屬性與固定值清單，自己補上符合語境的標籤**。

## 第二部分：程式 ZR_TR25_&lt;縮寫&gt;

依序完成：

1. 宣告示範用的 Global Type 變數：`gv_carrid_global TYPE s_carr_id`（直接引用標準 Data Element）與 `gv_carrid_hard TYPE c LENGTH 3`（反面教材：寫死長度）；各自填入 `'LH'` 後 WRITE 輸出，並用註解說明兩者的差異（見講義 25 第 2.1 節）
2. 寫一個 `FORM load_surchg_config CHANGING ct_surchg TYPE ztr25_tt_surchg.`——用第一部分建的 **DDIC Table Type** 當 CHANGING 參數型別，`SELECT * FROM ztr25_surchg INTO TABLE @ct_surchg.`；呼叫後 WRITE 輸出讀到的筆數
3. `SELECT` SFLIGHT INNER JOIN SCARR、**LEFT OUTER JOIN** `ZTR25_SURCHG`（依 CARRID），撈出：航空公司代碼/名稱、航線、日期、已售座位、票價、`ACTIVE`、`SURCHARGE_PCT`；`WHERE seatsocc > 0`
4. 逐筆計算：`revenue = price * seatsocc`；`active = 'X'` 時 `revenue_adj = revenue * (1 + surcharge_pct / 100)`，否則 `revenue_adj = revenue`
5. 輸出清單：航空公司、航線、日期、原始營收、加成後營收，並標明是否套用加成
6. **驗證外鍵只擋畫面、不擋 Open SQL（這次 Check Table 是標準表）**：
   - 先 `DELETE FROM ztr25_surchg WHERE carrid = 'ZZ'.` 防呆
   - `INSERT` 一筆 `CARRID = 'ZZ'`（`SCARR` 沒有這家航空公司）、`ACTIVE = 'X'`、`SURCHARGE_PCT = 20.00`
   - 輸出 `sy-subrc`，說明「即使 Check Table 換成標準表，結論不變」
   - 再次 `DELETE FROM ztr25_surchg WHERE carrid = 'ZZ'.` 清掉測試資料，不污染正式設定
7. 結尾 `COMMIT WORK.`

## 預期輸出（範例，數字依測試資料而異）

```
=== Global Type 示範 ===
lv_carrid_global（TYPE s_carr_id）：LH
  → 型別／長度／標籤／F4 全部繼承自標準 Data Element，SAP 升級調整它，這裡自動跟著變
lv_carrid_hard（TYPE c LENGTH 3）：LH
  → 看起來結果一樣，但長度是寫死的——S_CARR_ID 若改長，這裡不會自動變寬，是條隱藏地雷

讀到旺季加成設定：          2 筆（DDIC Table Type ZTR25_TT_SURCHG）

=== 航班加成營收 ===
AA American Airlines  0017  2026.01.03  原始營收      159,494.31  加成後      183,418.46（已加成 15%）
LH Lufthansa          0400  2026.02.10  原始營收       98,765.00  加成後      108,641.50（已加成 10%）
AF Air France         0800  2026.03.01  原始營收       75,000.00  加成後       75,000.00（未設定，維持原價）
...

=== 驗證：Check Table 換成標準表，Open SQL 依然不受外鍵約束 ===
INSERT CARRID=ZZ（SCARR 沒有這家航空公司）：sy-subrc = 0
  → 結論不變：外鍵只在畫面輸入生效，Open SQL 呼叫不受影響
```

## 思考題

1. 需求 1 的 `gv_carrid_hard` 現在跟 `gv_carrid_global` 內容一樣、行為看起來也一樣——這種「暫時沒問題」的寫法為什麼危險？什麼情況下差異才會浮現？
2. 如果本題的 `CARRID` 一開始就自建一個新的 Data Element（而不是重用 `S_CARR_ID`），第一部分事前準備第 6 步的「F4 直接出現選單」還會成立嗎？為什麼？
3. `LEFT OUTER JOIN ZTR25_SURCHG` 如果改成 `INNER JOIN`，需求 2 的報表會漏掉哪些資料？
4. 對照講義 21 的 `ZTR21_STUD-KLASSE`（Check Table 是自建的 `ZTR21_CLASS`）：兩種情境下，Search Help 的建置工作量差在哪裡？什麼時候你會遇到「Check Table 是標準表」、什麼時候會遇到「Check Table 也要自建」？
5. `ZTR25_ACTIVE` 跟 `ZTR25_SURPCT`／`S_CARR_ID` 都不一樣：它既不是整個重用標準 Data Element，也不是完全自建 Domain。這種「重用標準 Domain、自建標籤」的做法，跟直接自建一個全新的 Domain（如 `ZTR25_SURPCT` 那樣）相比，省下了什麼工作？
6. `ZTR25_TT_SURCHG` 的 Line Type 直接填 `ZTR25_SURCHG`（表格本身），而不是重新定義一份一模一樣的欄位——如果之後 `ZTR25_SURCHG` 多加一個欄位，`ZTR25_TT_SURCHG` 要跟著改嗎？這跟第 5 節「三種引用寫法」裡哪一種效果最像？
7. 如果 `load_surchg_config` 這個 FORM 只有你的程式在用，值得為它多跑一次 SE11 建 Table Type 嗎？什麼條件成立時才划算？

## 答案

見 `zr_tr25_ddic.prog.abap`（SAP 端程式 `ZR_TR25_DDIC`）；資料表定義以本題目第一部分為準，快照見 `ztr25_surchg.tabl.abap`。Domain／Data Element（`ZTR25_SURPCT`、`ZTR25_ACTIVE`）與 Table Type（`ZTR25_TT_SURCHG`）無程式碼快照（DDIC metadata 物件，非 source-based）。
