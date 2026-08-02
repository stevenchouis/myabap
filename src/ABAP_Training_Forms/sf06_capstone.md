# 表單設計練習 6：期末綜合實作 - 庫存盤點單

## Lecture

這題整合 sf01～sf05 全部技巧，做一張模擬的「庫存盤點單」，資料來源呼應 `Z_INVENTORY_COST_REPORT`（基礎課期末實作 ex13 的同一份程式）——`Z_INVENTORY_COST_REPORT` 的核心資料來自 `MARD`（儲存地點庫存資料表，欄位含 `MATNR`／`WERKS`／`LGORT`／`LABST`）＋`MAKT`／`MBEW` 等表 JOIN 出來的成本明細。這題**只取 `MARD` 單一張真實 DDIC 表**當資料來源（已用 ADT 查證 `MARD` 的 `MATNR`／`WERKS`／`LGORT` 是主鍵欄位，`LABST` 透過 `include emard` 併入），不做多表 JOIN——重點是整合 Smartform 技巧，不是重寫一次 ex13 的 JOIN 邏輯。

**這題會用到、也是最後一次複習的技巧清單**：

| 技巧 | 出自哪一題 | 這題怎麼用 |
|---|---|---|
| `SSF_FUNCTION_MODULE_NAME` + 動態 `CALL FUNCTION` | sf01 | 呼叫端骨架，跟前五題完全一樣的模式 |
| Smart Style 強制指派、可跨表單重複使用 | sf01／sf03 | 沿用 `ZSTY_02_LAYOUT`，這題**再新增一個段落格式 `P3`**（表格欄位標題用）——這是 sf03 思考題 3 問過的情境的實際示範：修改共用 Style，新增格式不影響既有的 `P1`/`P2`，`ZSF_02_LAYOUT`／`ZSF_03_LOGO` 等表單的既有內容不會跑版 |
| Page → Window 兩層階層、Main／Secondary Window | sf02 | HEADER／FOOTER 用 Secondary Window，明細用 MAIN |
| Logo 與文字並排（Template） | sf03 | 沿用 sf03 匯入的 `ZLOGO_SF03` |
| Box and Shading（框線網底） | sf04 | HEADER／表格都加框線 |
| Form Interface／Alternative／系統欄位頁碼 | sf05 | `IT_STOCK` 傳入庫存資料、缺貨判斷、頁碼 |

**這題新引入一個技巧：正式的 `Table` 節點（動態版面），取代前面用的 `Loop`**——sf04 思考題 3 已經預告過這個機制，這裡正式使用。官方文件《Node Types: Overview》查證：**`Table` 節點建立時會自動產生三個子節點：`Header`／`Main Area`／`Footer`**——`Header` 只在表格開頭（或換頁後）印一次，`Main Area` 對應資料逐行輸出（跟 `Loop` 一樣要在 `Data` 分頁指定內部表格），`Footer` 在換頁前印一次。這個機制正是「明細很長、需要跨頁，但每一頁都要看得到欄位標題」這個需求的標準做法——`Loop` 節點本身沒有這個「自動重印表頭」的能力，這是 `Table` 節點跟 `Loop` 節點的關鍵差異。

## 學習目標

- 能整合前五題學到的所有技巧，做出一張版面完整的正式單據
- 能講出 `Table` 節點跟 `Loop` 節點的差異：`Table` 有自動產生的 `Header`／`Main Area`／`Footer`，適合「換頁要重印表頭」的情境
- 能修改一個多張表單共用的 Smart Style（新增格式），並理解這個修改對既有表單的影響範圍
- 能講出這門課六題分別對應 Smartform 的哪些核心概念，形成完整的心智地圖

## 事前準備

沿用 sf02 的 `ZSTY_02_LAYOUT`（這題會編輯它、新增 `P3`）與 sf03 匯入的圖檔 `ZLOGO_SF03`。

## 題目需求

1. **編輯既有的 Smart Style `ZSTY_02_LAYOUT`**，新增段落格式 `P3`（用途：表格欄位標題，建議粗體、底色或加大字距，跟 `P1`/`P2` 有明顯區隔），重新啟用。

2. **建立新表單 `ZSF_06_CAPSTONE`**，Style 指派 `ZSTY_02_LAYOUT`，Page Format `DINA4`。

3. **Form Interface** 新增 Import 參數：`IT_STOCK TYPE STANDARD TABLE OF MARD`。

4. **HEADER Secondary Window**（Position/Size 比照前幾題：X `2`cm／Y `2`cm，Width `17`cm／Height `2`cm），套用 Box and Shading（框線＋淺色網底，比照 sf04），裡面放 Template 1 列 2 欄：
   - 左欄：Graphic 節點，沿用 `ZLOGO_SF03`
   - 右欄：Text 節點（`P1`），內容 `庫存盤點單 - ZSF_06_CAPSTONE`

5. **MAIN Window 裡建立一個 `Table` 節點**，`Data` 分頁指到 `IT_STOCK`，工作區自訂（例如 `WA_STOCK`）：
   - **Header** 子節點：一個 Template（1 列 4 欄），四個 Text 節點（`P3`）分別輸出欄位標題 `料號`／`廠別`／`儲存地點`／`庫存量`，並設定 Box and Shading 畫格線
   - **Main Area** 子節點：對應每一筆資料，也用 Template（1 列 4 欄）輸出 `&WA_STOCK-MATNR&`／`&WA_STOCK-WERKS&`／`&WA_STOCK-LGORT&`，第四欄用 **Alternative 節點**判斷：
     - 條件 `WA_STOCK-LABST = 0`：`TRUE` 印 `⚠ 缺貨`
     - `FALSE` 印 `&WA_STOCK-LABST&`
   - 這個 Line Type 記得比照 sf04 勾選 **`No Break`**，避免明細列被硬切斷
   - **Footer** 子節點：可以留空或放一條分隔線，這題不強制要求內容

6. **FOOTER Secondary Window**（Position 例如 Y-Origin `27`cm）：Text 節點顯示 `第 &SFSY-PAGE& 頁，共 &SFSY-FORMPAGES& 頁`。

7. **啟用**整組物件（`ZSTY_02_LAYOUT` 的修改 → `ZSF_06_CAPSTONE`）。

8. **呼叫端程式**：Claude 建立 `ZR_SF06_CAPSTONE`，`SELECT * FROM MARD INTO TABLE lt_stock UP TO 10 ROWS`，傳給 `it_stock` 參數。

9. **驗證**：Print Preview 或執行 `ZR_SF06_CAPSTONE`，確認：
   - Logo 與標題並排顯示在 HEADER
   - 表格欄位標題（`P3`）跟明細列（`P1`/`P2`）字體風格有明顯差異
   - 庫存量為 0 的料號顯示 `⚠ 缺貨`
   - 頁尾看得到頁次
   - 回頭打開 `ZSF_02_LAYOUT`／`ZSF_03_LOGO` 的 Print Preview，確認新增 `P3` 沒有讓它們既有的內容跑版（呼應學習目標最後一項）

## 思考題

1. 如果 `IT_STOCK` 傳進來的資料超過一頁能放的行數，`Table` 節點的 `Header`（欄位標題列）會在第二頁重新出現嗎？如果用 sf05 那種 `Loop` 節點做同樣的事，欄位標題列會自動出現在第二頁嗎？（提示：這正是 Lecture 強調的 `Table` vs `Loop` 差異）
2. 這六題總共建立了幾個 Smart Style 物件？分別被哪些表單使用？這個「共用」的設計對「多張表單想要統一視覺風格」這個真實需求有什麼幫助？
3. 回顧六題整體，如果現在要你用一句話跟同事介紹「Smartform 是什麼、跟 Classical List 差在哪」，你會怎麼說（呼應 sf01 Lecture 一開始的問題，這次換你自己回答）？

## 答案

`ZR_SF06_CAPSTONE` 快照見 `zr_sf06_capstone.prog.abap`（已建立、語法檢查通過，內含 `SELECT FROM MARD` 邏輯）。`ZSF_06_CAPSTONE` 表單本體（含 Form Interface／Table 節點／Alternative／頁碼）與 `ZSTY_02_LAYOUT` 的 `P3` 新增段落格式，都需要你在 `SMARTFORMS`／`SMARTSTYLES` 手動建立（原因見 sf01／`.claude/rules/sap-adt-mcp.md` 第 19 節）。完成後請回報結果，或執行 `ZR_SF06_CAPSTONE` 搭配 Print Preview 驗證整張單據。

至此 sf01～sf06 全部出題完成，`ABAP_Training_Forms` 主課程結案。
