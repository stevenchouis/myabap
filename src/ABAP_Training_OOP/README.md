# SAP ABAP OOP 課程

基礎課（`src/ABAP_Training/`，ex01–ex15）的續篇。本課綱已定稿（2026-07-03），出題進行中。

## 課程定位

- **對象**：完成基礎課的學員（會 FORM/FM、報表事件、internal table、SFLIGHT 模型）
- **結業標準**：能把基礎課 ex13 航班營收報表重構成「商業邏輯在 Class、程式只剩 UI 薄層」的架構，附 ABAP Unit 測試——即團隊風格規範（`.claude/rules/abap-style.md`）要求的新程式寫法
- **本課程題號＝授課順序**，期末實作是最後一題

## 教材慣例

- 每題三件套：題目 `opNN_主題.md` + PDF 講義（`node tools/md2pdf.js src/ABAP_Training_OOP`）+ 答案快照
- 答案物件命名：`ZCL_OOnn_*`（類別）/ `ZIF_OOnn_*`（介面）/ `ZCX_OOnn_*`（例外類別）/ `ZR_OOnn_*`（demo 程式），套件 `$TMP`
- 資料模型：續用 SCARR/SFLIGHT 航班訓練模型
- op01–op04 用 local class（SE38 可寫）；op05 起改用 ADT（Eclipse）開發全域類別

## 課綱

| # | 主題 | 內容重點 | 銜接基礎課 | 狀態 |
|---|---|---|---|---|
| op01 | 為什麼要 OOP + 第一個類別 | FORM/FM 的限制（全域變數、無封裝）；CLASS DEFINITION/IMPLEMENTATION、屬性、方法、`NEW` 建立物件 | ex08 的 FORM 痛點當引子 | 已出題（待驗收） |
| op02 | 方法與參數 | IMPORTING/EXPORTING/CHANGING/RETURNING、函數式呼叫、方法鏈；隨堂引入現代語法（`DATA(...)`、string template） | 把 ex15 的 FM 改寫成 method，FORM/FM/Method 三方對照 | 已出題（待驗收） |
| op03 | 建構子與封裝 | `constructor`、私有屬性 + 公開方法、`READ-ONLY`、`class_constructor` | — | 已出題（待驗收） |
| op04 | 靜態 vs 實例 | CLASS-DATA/CLASS-METHODS 使用時機、工具類 vs 有狀態物件 | ex08 已偷跑過 static method | 已出題（待驗收） |
| op05 | 全域類別 | local class 搬成 `ZCL_` 全域類別（ADT/SE24）、可見性、跨程式重用 | 對照 ex15「FM 跨程式共用」定位 | 已出題（待驗收） |
| op06 | 繼承 | `INHERITING FROM`、`REDEFINITION`、`super->`、abstract/final；艙等計價當例子 | 航班模型延續 | 已出題（待驗收） |
| op07 | 介面 | `ZIF_` 介面定義與實作、介面參考、「寫給介面不寫給實作」 | 命名慣例表的 ZIF_ 落地 | 規劃中 |
| op08 | 多型與轉型 | 向上/向下轉型、`CAST`、`IS INSTANCE OF`、多型迴圈 | 承 op06/07 | 規劃中 |
| op09 | 例外類別 | TRY/CATCH/CLEANUP、`RAISE EXCEPTION`、自訂 `ZCX_` 繼承 CX_STATIC_CHECK vs CX_DYNAMIC_CHECK 的選擇（團隊規範）；對照 ex15 classic EXCEPTIONS | 兌現 ex09「TRY/CATCH 之後教」 | 規劃中 |
| op10 | ABAP Unit 單元測試 | local test class、`FOR TESTING RISK LEVEL HARMLESS DURATION SHORT`、given-when-then、`cl_abap_unit_assert` | 團隊規範「新 Class 必附測試」落地 | 規劃中 |
| op11 | 標準 OO API 實戰：cl_salv_table | ex09 Functional ALV 改寫成 `cl_salv_table`、方法鏈實戰、ADT 導覽標準類別 | 兌現 ex09 的預告 | 規劃中 |
| op12 | 期末綜合：報表 OO 化重構 | ex13 全面重構——`ZCL_OO12_FLIGHT_REVENUE`（取數+計算+`ZCX_` 例外）+ ABAP Unit 測試 + `cl_salv_table` 輸出，報表剩 <30 行 UI 層；重構前後行為一致 | ex13 是輸入，團隊規範是驗收 | 規劃中 |

## 不碰的範圍（下一階段）

OO 事件（EVENTS/SET HANDLER）、Design Pattern、CDS/RAP。

## 出題工作流程（給接手的 session）

與基礎課相同：SAP 建物件（`sap_create_object`；MCP 不支援的物件類型見 `.claude/rules/sap-adt-mcp.md` 的 ADT API workaround）→ `sap_set_source` 寫入 → curl 啟用 + 語法檢查 → 使用者 SE38/ADT 測試 → 快照（curl 下載 active 版本）→ 題目 md → `node tools/md2pdf.js src/ABAP_Training_OOP` 產 PDF → 更新本 README 狀態 → commit + push。每批 2–3 題、使用者驗收後再繼續。
