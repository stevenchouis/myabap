# 練習 13：期末綜合實作——航班營收報表

> **本題最後做**：建議授課順序是 ex01–ex12 → ex14 → ex15 → 本題（題號因 SAP 物件已命名而未重編，見 README）。

## 前置條件

已完成 ex14（INCLUDE 拆檔）與 ex15（Function Module）。

## 目標

整合 ex01～ex12 所有技能，獨立寫出一支結構完整的傳統報表。完成後對照真實程式 `Z_INVENTORY_COST_REPORT`（`src/z_inventory_cost_report.prog.abap`），**能看懂它的每一行**即為結業標準。

| 本題（航班營收） | 對照 Z_INVENTORY_COST_REPORT |
|---|---|
| SFLIGHT join SCARR | MARD join MARA/T001K/MAKT/MBEW/T001 |
| 營收 = 票價 × 已售座位 | 總價 = 庫存 ÷ 價格單位 × 標準價 |
| 排除 seatsocc = 0 | 排除零庫存（p_zero） |
| 頁次 x/### 回填 | 同樣的 READ/MODIFY LINE 技巧 |

## 事前準備

建立程式 `ZR_TR13_<你的姓名縮寫>`，套件 `$TMP`；確認 SFLIGHT 有資料。

## 需求規格（試著只看規格寫，卡住再看答案）

1. **頁面**：寬機點矩陣＋11 吋連續紙 → `NO STANDARD PAGE HEADING LINE-SIZE 132 LINE-COUNT 65(3)`
2. **選擇畫面**：航空公司範圍、航班日期範圍（`TABLES sflight` + `FOR sflight-欄位`）、「排除未售出航班」checkbox 預設勾選；BLOCK 標題在 `INITIALIZATION` 給值
3. **取數**（FORM `get_data`）：SFLIGHT INNER JOIN SCARR 取公司名稱；依 checkbox 刪除 `seatsocc = 0`；LOOP 計算 `revenue = price × seatsocc` 後 `MODIFY` 寫回
4. **輸出**（FORM `display_data`）：`|` 表格線對齊（公司/名稱/航線/日期/已售/票價/營收/幣別），金額欄 `CURRENCY gs_rev-currency`；查無資料要有訊息；結尾輸出合計筆數
5. **頁首**（`TOP-OF-PAGE`）：程式名/使用者/置中標題/日期/時間/頁次 `x/###` + 欄位標題列
6. **頁尾**（`END-OF-PAGE`）：橫線 + 「製表：財務部／主管簽核」
7. **總頁數回填**（`END-OF-SELECTION` → FORM `update_total_pages`）：`DO sy-pagno TIMES` → `READ LINE 2 OF PAGE sy-index` → `REPLACE '###'` → `MODIFY LINE`

## List Buffer 觀念（本題的核心）

所有 `WRITE` 都是先寫進 **List Buffer**，`END-OF-SELECTION` 結束後才輸出到畫面。所以：

- 印每一頁「當下」不可能知道總頁數（後面還沒跑完）
- 但 `END-OF-SELECTION` 時全部內容已在 Buffer 裡，`sy-pagno` 就是總頁數
- `READ LINE n OF PAGE p` 把 Buffer 中某頁某行讀進 `sy-lisel` → 改字 → `MODIFY LINE` 寫回
- 這就是報表能印出「頁次 2/7」的原理

## 驗收清單

- [ ] 不輸入條件執行：全部航班、分頁正常、每頁頁首頁尾齊全
- [ ] 頁次顯示 `1/n`、`2/n`……最後一頁 `n/n`（n 為實際總頁數，不是 ###）
- [ ] 條件縮小到查無資料：顯示訊息、不噴錯
- [ ] 取消 checkbox：seatsocc = 0 的航班出現、營收為 0
- [ ] 讀 `Z_INVENTORY_COST_REPORT` 原始碼，逐段說出對應本題的哪一部分

## 結業要求（整合 ex14 / ex15）

基本版寫完並通過驗收清單後，重構成「實務結構」：

1. **拆檔**（ex14 技能）：拆成 `_TOP`（宣告）與 `_F01`（FORM），主程式只留 INCLUDE 與事件——結構參考答案 `zr_tr14_capstone.prog.abap`
2. **改呼叫 FM**（ex15 技能）：`get_data` 中的 `revenue = price × seatsocc` 改成 `CALL FUNCTION 'Z_TR15_CALC_REVENUE'`，並處理 `invalid_input` 例外（把該筆記到錯誤清單而不是讓程式 dump）

重構後執行結果必須與基本版完全相同——「重構不改行為」是實務鐵律。

## 延伸挑戰

1. 頁尾加「本頁小計」（提示：END-OF-PAGE 可以用全域變數累計）
2. 把明細輸出改成 ex09 的 Functional ALV 版本，比較兩種輸出的取捨
3. 營收是「各幣別混在一起」的——怎麼依幣別分組小計？（提示：SORT + AT END OF，自學關鍵字）

## 答案

見 `zr_tr13_capstone.prog.abap`（SAP 端程式 `ZR_TR13_CAPSTONE`）。
