# SAP ABAP Smartform／Style 表單設計課程

基礎課（`src/ABAP_Training/`）ex12「列印排版」教的是 Classical List（`WRITE`/`LINE-SIZE`）的純文字報表；本課程接續同一條「列印輸出」主線，往下教正式單據（有 Logo、框線、精確版面）常用的 **Smartform** 工具。課綱已定稿，**sf01～sf06 全部出題完成，主課程結案**（2026-07-21）；**sf07 是結案後依實務需求加開的延伸題**（套表列印，見下方課綱表）。

**⚠️ 已實測確認的工具限制**（見 `.claude/rules/sap-adt-mcp.md` 第 19 節）：Smartform／Style／SE78 完全沒有 ADT REST API，Claude 沒辦法直接建立或修改 Smartform 本體，Form Painter 版面配置一律要在 SAP GUI 手動操作；Claude 能自動建立、語法檢查、驗證的只有**呼叫端 ABAP 程式**（`SSF_FUNCTION_MODULE_NAME` + 動態 `CALL FUNCTION`）。

## 課程定位

- **對象**：完成基礎課（至少 ex08 模組化、ex12 列印排版）的學員，會宣告 Internal Table 並串好資料即可，不要求先修 OOP。
- **技術範圍**：Smartform（`SMARTFORMS` Form Builder，⚠️不是 `SE71`——`SE71` 是前代 SAPscript「Layout Set」專用的交易碼，兩者是完全獨立的物件與工具，套件分別是 `STXD`／`SMART`，已用 ADT quickSearch 查證）＋ Style（`SMARTSTYLES`，同樣獨立於 SAPscript 的 `SE72`）＋ `SE78` 圖形管理（這支是 SAPscript／Smartform 共用的工具，不受上面「各自獨立」影響）；**不含** SAPscript（前代技術，僅在 sf01 帶一句定位對照）與 Adobe Forms（需要額外的 ADS 伺服器，這套系統未必有裝，列為下一階段候選）。
- **⚠️ 已知工具限制**（已實測確認，見 `.claude/rules/sap-adt-mcp.md` 第 19 節）：`SMARTFORMS`／`SMARTSTYLES`／`SE78` 圖形上傳都是傳統 Dynpro 工具，**完全沒有 ADT REST API**，`sap_create_object`/`sap_get_source`/`sap_set_source` 的 objectType enum 沒有對應項目。也就是說 Claude **沒辦法**直接建立或修改 Smartform 本體——教材只能教操作步驟＋提供「呼叫端」ABAP 程式碼（`SSF_FUNCTION_MODULE_NAME` 取得動態函式模組名稱 → `CALL FUNCTION`），Form Builder 內的版面配置需要使用者在 SAP GUI 手動操作，Claude 從旁指導與核對結果。這點已在 sf01 開頭說清楚，避免預期落差。
- **結業標準（草案）**：能獨立用 `SMARTFORMS` 從空白建出一張含 Logo、外框線、Header/明細表格、頁碼的正式單據，並寫出正確呼叫該表單的 ABAP 程式（含動態取得函式模組名稱、傳入 Internal Table）。

## 教材慣例（比照 OOP/REST/AMDP 課程）

- 每題三件套：題目 `sfNN_主題.md` + PDF 講義（`node tools/md2pdf.js src/ABAP_Training_Forms`）+ 答案快照（Smartform 本體若無法快照，至少快照呼叫端程式 `zr_sfNN_*.prog.abap`）
- 每題 md 開頭（`## 學習目標` 之前）要有 `## Lecture` 完整背景知識講解
- 答案物件命名：呼叫端程式沿用 `ZR_SFnn_*`，Smartform 本體命名 `ZSF_nn_*`
- 資料模型：sf05 用 `SCARR` 航班模型；sf06 用 `MARD`（庫存資料表，呼應 `Z_INVENTORY_COST_REPORT`／ex13 的資料來源，但只取單一張真實表，不重做多表 JOIN）

## 課綱（sf01～sf06 已全部出題）

| # | 主題 | 內容重點 | 銜接前面課程 | 狀態 |
|---|---|---|---|---|
| sf01 | 為什麼要用 Smartform | 列印輸出技術演進：SAPscript（舊，純文字定位）→ Smartform（圖形化 Form Painter，本課主軸）→ Adobe Forms（需 ADS，下一階段候選）；`SMARTFORMS` 建立第一個空白表單，`Form Attributes` 節點的 `General Attributes`／`Output Options` 兩個分頁（⚠️不是三個平行分頁，已依使用者實測畫面更正，Page Format／Style 都在 `Output Options`）；⚠️**Style 欄位是強制項目**（已查證 SAP 官方文件《Smart Styles》："You must assign a Smart Style to each Smart Form"），且**必須先用 `SMARTSTYLES` 獨立建好、啟用**再回表單引用（⚠️不會像原先誤以為的那樣在欄位裡打名字就跳出建立提示，已依使用者實測畫面更正）；⚠️**Smart Style 本身的 Header Data 也有強制必填的 Standard Paragraph 欄位**，要先建至少一個 Paragraph Format（代碼固定兩個字元）才能填、才能存檔（已查證官方文件《Header Data of a Smart Style》並依使用者實測畫面更正），sf01 建一個最陽春的 `P1` 佔位滿足這個規定，完整的 Smart Style 教學留給 sf02；呼叫端骨架 `SSF_FUNCTION_MODULE_NAME` 取動態函式模組名稱 → `CALL FUNCTION` | 對照 ex12 Classical List 列印排版 | 已出題（呼叫端 `ZR_SF01_DEMO` 已建立、語法檢查通過；Smartform 本體 `ZSF_01_HELLO` 與 Smart Style `ZSTY_01_HELLO` 待使用者於 `SMARTFORMS`／`SMARTSTYLES` 手動建立） |
| sf02 | 版面元件、量測與 Smart Style | Smart Forms 真實階層是 **Page → Window 兩層**（已查證官方文件《Node Types: Overview》，根節點是 Global Settings／Pages and Windows，沒有獨立的「Page Window」——那是 SAPscript 專屬，見 sf01/sf02 的教訓記錄）；Window Types：Main（僅一個，溢出自動換頁）vs Secondary（可多個，溢出截斷不換頁）vs Copies／Final（Secondary 的子類型）；節點型別總覽：Text／Template（固定列數欄數）／Table（動態列數，官方 FAQ 已查證兩者差異）；**Smart Style 深入教學**——建立含 `P1`/`P2` 兩個自訂 Paragraph Format 的 Smart Style，取代 sf01 的最小佔位版本；**量測練習**——用數字精確輸入 Window 的 Position／Size（cm，原點左上角），實作一個「內部備忘錄」靜態版面（頁首 Secondary Window + 正文 Template） | 承 sf01 的 Smart Style／Window 基礎 | 已出題（呼叫端 `ZR_SF02_DEMO` 已建立、語法檢查通過；Smartform 本體 `ZSF_02_LAYOUT` 與 Smart Style `ZSTY_02_LAYOUT` 待使用者於 `SMARTFORMS`／`SMARTSTYLES` 手動建立） |
| sf03 | Logo 置入 | 兩段流程：`SE78` 匯入圖檔（存進 BDS）→ `SMARTFORMS` 建 Graphic 節點（`Object`／`ID`／`Name` 用 F4 帶出）；Graphic 節點放在 Page 底下 vs Window 底下的顯示時機差異；⚠️圖形不能跟文字重疊，官方文件證實用 **Template 節點可以讓圖形與文字並排**；解析度設定與常見踩雷（圖模糊/位置跑掉多半是解析度換算錯誤）；示範 Smart Style 跨表單重複指派（沿用 sf02 的 `ZSTY_02_LAYOUT`） | 承 sf02 的量測基礎 | 已出題（呼叫端 `ZR_SF03_DEMO` 已建立、語法檢查通過；`ZSF_03_LOGO` 與圖檔 `ZLOGO_SF03` 待使用者於 `SE78`／`SMARTFORMS` 手動建立） |
| sf04 | 畫框線（Box and Shading／Line Type） | ⚠️更正課綱草案用詞：Window 沒有叫「Frame」的屬性，正確是所有輸出節點共用的 **Box and Shading**（官方文件查證）；Window 整體框線／網底 vs Template／Table 的 **Line Type**（Table Painter 的 Pattern 功能畫格線與外框，個別儲存格設框線要關掉 Draw Mode）；`No Break` 這個 Line Type 屬性的用途（防止表格列被換頁硬切斷，先建立觀念，sf05/sf06 才看得到實際效果） | 承 sf02/sf03 | 已出題（呼叫端 `ZR_SF04_DEMO` 已建立、語法檢查通過；`ZSF_04_BORDERS` 待使用者於 `SMARTFORMS` 手動建立） |
| sf05 | 資料傳遞與動態內容 | Form Interface（Import／Export／Tables 三種參數，⚠️沒有 Changing；動態呼叫時參數名稱打錯語法檢查抓不到）；Global Definitions（Data／Types）；`Loop` 節點逐筆讀內部表格到工作區；`Alternative` 節點 TRUE/FALSE 條件分支；系統欄位 `&SFSY-PAGE&`／`&SFSY-FORMPAGES&` 做頁碼；資料模型改用 `SCARR`（航空公司主檔），呼叫端要先 `SELECT` 資料再傳參數 | 承基礎課 ex08 模組化的參數傳遞觀念 | 已出題（呼叫端 `ZR_SF05_DEMO` 已建立、語法檢查通過，內含 `SELECT FROM SCARR`；`ZSF_05_FLIGHTS` 待使用者於 `SMARTFORMS` 手動建立） |
| sf06 | 期末綜合實作 | 模擬一張「庫存盤點單」（資料來源改用真實表 `MARD`，呼應 `Z_INVENTORY_COST_REPORT`／ex13 的資料來源，但只取單一張表不重做多表 JOIN）：Logo＋標題並排（sf03）、Box and Shading 框線（sf04）、**正式的 `Table` 節點**（自動產生 Header／Main Area／Footer 三個子節點，換頁會自動重印表頭，跟 `Loop` 的關鍵差異）、Alternative 缺貨判斷與頁碼（sf05），並在共用的 `ZSTY_02_LAYOUT` 新增第三個段落格式 `P3`，示範修改共用 Smart Style 對其他既有表單的影響範圍，整合 sf01～sf05 全部技巧 | 呼應 ex13 期末實作、`Z_INVENTORY_COST_REPORT` | 已出題（呼叫端 `ZR_SF06_CAPSTONE` 已建立、語法檢查通過，內含 `SELECT FROM MARD`；`ZSF_06_CAPSTONE` 與 `ZSTY_02_LAYOUT` 的 `P3` 新增段落格式待使用者於 `SMARTFORMS`／`SMARTSTYLES` 手動建立） |
| sf07（延伸題） | 套表列印（中一刀連續紙套版） | ⚠️跟 sf01～sf06「從零設計版面」相反的技術取向——客戶已有印好格線/欄位名稱的制式紙本（中一刀連續紙複寫套表），Smartform 只需精準定位資料、**不畫任何框線/標題**；先釐清「三聯複寫是印表機物理壓力/複寫紙結構，跟 sf02 教過的 Copies Window（邏輯上的重複列印）完全是兩回事」；新引入 `SPAD`（Spool Administration，交易碼，**Basis 領域、完全沒有 ADT API**）的 Page Format／Format／Device Type Format 三個關聯物件（官方文件《Creating Page Formats》查證），目標尺寸 5.5 吋連續紙中一刀＝9.5"×5.5"（24.13cm×13.97cm，呼應基礎課 ex12 提過的同一種紙）；反覆試印比對校準的實務流程 | 承 sf02 量測、sf04 框線觀念（這題刻意不用框線）、sf01 的 Page Format 欄位 | 已出題（呼叫端 `ZR_SF07_DEMO` 已建立、語法檢查通過；`ZSF_07_OVERLAY` 與 `SPAD` 的中一刀 Page Format 待使用者於 `SMARTFORMS`／`SPAD` 手動建立） |

> Smartform 相關 ADT API 的真實可用範圍已實測確認（第 19 節：完全沒有），出題時務必用 ADT quickSearch／SAP 官方文件交叉查證交易碼與物件層級用語，不要憑記憶或直覺寫——這門課總共踩過六次這類錯誤（sf01 誤植 `SE71`；sf02 草稿誤用 SAPscript 專屬的「Page Window」；sf01 操作教學漏教強制的 Smart Style 欄位；規劃階段的「Window Frame 屬性」用詞在 sf04 出題時發現是錯的，正確叫 Box and Shading；sf01 誤以為在表單 Style 欄位打新名稱會跳出建立提示，實測發現只會報錯、要先到 `SMARTSTYLES` 獨立建好；sf01 誤以為 Smart Style 可以完全不客製化就存檔，實測發現 Header Data 的 Standard Paragraph 是強制必填、要先建至少一個 Paragraph Format），每次都是查證或使用者實測後才發現並修正，記錄於 `.claude/rules/sap-adt-mcp.md` 第 19 節與 Claude 的 [[feedback-verify-tcodes]] 記憶。
