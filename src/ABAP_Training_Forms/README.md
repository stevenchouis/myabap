# SAP ABAP Smartform／Style 表單設計課程

基礎課（`src/ABAP_Training/`）ex12「列印排版」教的是 Classical List（`WRITE`/`LINE-SIZE`）的純文字報表；本課程接續同一條「列印輸出」主線，往下教正式單據（有 Logo、框線、精確版面）常用的 **Smartform** 工具。課綱為草案，尚未逐題出題與驗收。

## 課程定位

- **對象**：完成基礎課（至少 ex08 模組化、ex12 列印排版）的學員，會宣告 Internal Table 並串好資料即可，不要求先修 OOP。
- **技術範圍**：Smartform（SE71 Form Builder）＋ Style（SE72，共用格式樣式）＋ SE78 圖形管理；**不含** SAPscript（前代技術，僅在 sf01 帶一句定位對照）與 Adobe Forms（需要額外的 ADS 伺服器，這套系統未必有裝，列為下一階段候選）。
- **⚠️ 已知工具限制（比照 `.claude/rules/sap-adt-mcp.md` 第 10／12 節 Search Help／T-code 的先例，待逐題出題時實測確認）**：Smartform／Style／SE78 圖形上傳都是傳統 Dynpro 工具，**極可能沒有 ADT REST API**，`sap_create_object`/`sap_get_source`/`sap_set_source` 的 objectType enum 目前也没有對應項目。也就是說 Claude 大概率**沒辦法**直接建立或修改 Smartform 本體——教材只能教操作步驟＋提供「呼叫端」ABAP 程式碼（`SSF_FUNCTION_MODULE_NAME` 取得動態函式模組名稱 → `CALL FUNCTION`），Form Builder 內的版面配置需要使用者在 SAP GUI 手動操作，Claude 從旁指導與核對結果。這點要在 sf01 一開始就跟學員說清楚，避免預期落差。
- **結業標準（草案）**：能獨立用 SE71 從空白建出一張含 Logo、外框線、Header/明細表格、頁碼的正式單據，並寫出正確呼叫該表單的 ABAP 程式（含動態取得函式模組名稱、傳入 Internal Table）。

## 教材慣例（比照 OOP/REST/AMDP 課程）

- 每題三件套：題目 `sfNN_主題.md` + PDF 講義（`node tools/md2pdf.js src/ABAP_Training_Forms`）+ 答案快照（Smartform 本體若無法快照，至少快照呼叫端程式 `zr_sfNN_*.prog.abap`）
- 每題 md 開頭（`## 學習目標` 之前）要有 `## Lecture` 完整背景知識講解
- 答案物件命名：呼叫端程式沿用 `ZR_SFnn_*`，Smartform 本體命名 `ZSF_nn_*`
- 資料模型：優先沿用 SCARR/SFLIGHT 航班模型或 `Z_INVENTORY_COST_REPORT`／ex13 的庫存/營收模型，讓 sf06 期末實作能直接呼應既有教材

## 課綱（草案，待確認與逐題出題）

| # | 主題 | 內容重點 | 銜接前面課程 | 狀態 |
|---|---|---|---|---|
| sf01 | 為什麼要用 Smartform | 列印輸出技術演進：SAPscript（舊，純文字定位）→ Smartform（圖形化 Form Painter，本課主軸）→ Adobe Forms（需 ADS，下一階段候選）；SE71 建立第一個空白表單，Global Settings（Form Attributes／Page Format／Output Options）；呼叫端骨架 `SSF_FUNCTION_MODULE_NAME` 取動態函式模組名稱 → `CALL FUNCTION` | 對照 ex12 Classical List 列印排版 | 待出題 |
| sf02 | 版面元件與量測 | Page／Window／Page Window 三層觀念；MAIN window（可跨頁流動）vs 一般 window（固定位置）；Text／Table／Template 元件基礎；**如何量測表單尺寸**——比對現有紙本表單量出頁緣與欄寬、cm/inch 換算、Form Painter 座標定位方法（絕對定位 vs Container 內相對定位） | — | 待出題 |
| sf03 | Logo 置入 | SE78 圖形管理（Graphic Management，BMAP 物件，格式限制）；Window 類型選 Graphic，或在 Text Element 插入 Graphic；置中／靠左對齊與尺寸調整；常見踩雷（圖片模糊或位置跑掉多半是解析度或量測單位換算錯誤） | 承 sf02 的量測基礎 | 待出題 |
| sf04 | 畫框線（Table／Template／Frame） | Table 元件的 Line Type（線寬）與 Cell Border；Template 的 Cell 框線；Window 的 Frame（外框）屬性；跨頁框線注意事項（MAIN window 分頁時框線斷裂的處理） | 承 sf02/sf03 | 待出題 |
| sf05 | 資料傳遞與動態內容 | Form Interface（Import／Export／Tables 參數）；Global Definition（Data／Types）；`LOOP` element 輸出明細列；`Alternative` element 條件式顯示；系統欄位（`&SFSY-PAGE&` 等）做頁碼／總頁數 | 承基礎課 ex08 模組化的參數傳遞觀念 | 待出題 |
| sf06 | 期末綜合實作 | 模擬一張正式出貨單／庫存盤點單（呼應 `Z_INVENTORY_COST_REPORT`／ex13 的資料模型）：公司抬頭＋Logo、外框線、Header／明細表格、頁碼，整合 sf01～sf05 全部技巧 | 呼應 ex13 期末實作、`Z_INVENTORY_COST_REPORT` | 待出題 |

> 課綱為草案，出題前建議先實測確認 Smartform 相關 ADT API 的真實可用範圍（比照本檔規劃時的推測），並視實測結果調整「Claude 可自動化 vs 需使用者手動操作」的分工說明。
