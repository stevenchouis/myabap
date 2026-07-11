# 專案說明

- 專案類型：純 ABAP 後端開發（Class / Program / Function Module）
- 命名空間：Z 前綴（標準客戶命名空間）
- 版控狀態：**未使用 abapGit**；SAP 原始碼以 git 做**單向快照**，放在 `src/`，檔名採 abapGit 慣例（`<物件名小寫>.<類型>.abap`）。快照由 `sap-adt` MCP 匯出，SAP 端修改後需重新匯出；本地修改要用 `sap_set_source` 寫回系統才算數
- Repo 結構：
  - `src/`：正式程式快照（ZDQM 系列、Z_INVENTORY_COST_REPORT 等）
  - `src/ABAP_Training/`：基礎 ABAP 教育訓練教材——題目 md + PDF 講義 + 答案程式快照（SAP 端 `ZR_TRnn_*`），見該目錄 README 的題目索引與授課順序
  - `src/ABAP_Training_OOP/`：OOP 課程（op01–op12，答案物件 `ZCL_OOnn_*` 等），課綱已定稿、出題中，見該目錄 README
  - `tools/`：輔助腳本，如 `md2pdf.js`（教材 md 改後重產 PDF 講義，`node tools/md2pdf.js [目錄]`）
- SAP 系統資訊：請填入 System ID / Client / 語言
  - DEV: <補上>
  - QAS: <補上>
  - PRD: <補上>

> 這份檔案是 Claude Code 每次啟動都會讀取的專案記憶，請盡量保持精簡、只放「Claude 猜不到」的資訊（業務規則、團隊慣例、為什麼這樣做），不要放它能自己從程式碼推斷出來的東西。

## 命名慣例

| 物件類型 | 前綴/規則 |
|---|---|
| Class | `ZCL_xxx` |
| Interface | `ZIF_xxx` |
| Program (Report) | `ZR_xxx`（請依團隊實際慣例調整） |
| Function Group | `ZFG_xxx` |
| Function Module | `Z_xxx` |
| 測試類別 | `FOR TESTING RISK LEVEL HARMLESS DURATION SHORT` |
| Package | `ZPKG_xxx`，請依模組再細分子套件 |

## 開發流程

1. 新增物件前，先用 `sap_search_object` 確認是否已有相同用途的 Z 物件，避免重複建置。
2. 每個功能變更對應**一個獨立的 Transport Request**，不要混用多個任務。
3. 修改或新增程式碼後，一律先跑語法檢查（syntax check）沒問題才算完成。
4. **不要自動釋放（Release）傳輸請求**，除非我明確說「釋放」或「release」。
5. 詳細的傳輸請求檢查清單見 `.claude/rules/transport-flow.md`。

## 風格規範

- 詳見 `.claude/rules/abap-style.md`（會依修改到的 `*.abap` 檔案自動載入）。
- 不可修改 SAP 標準物件（S 開頭 / SAP 命名空間），只能透過 Enhancement / BAdI / User-Exit。
- 商業邏輯盡量寫在 Class 方法中，避免大量邏輯塞進 Program 主體。

## MCP / 系統連線

- `sap-adt`：透過 ADT (ABAP Development Tools) 協定讀寫 SAP 系統物件，HTTP transport，Project scope（設定在根目錄 `.mcp.json`，隨版控分享給團隊）。
- `sap-docs`：SAP 相關文件查詢用，唯讀性質，同樣是 Project scope。
- `sap-adt` 目前指向內網 IP（`192.168.68.56`，區網固定 IP），只有連得到這個網段的人才能用；不同網路環境的隊友需要各自調整，見 README.md。這個位址是 Eclipse Plugin「SAP ADT MCP Server for Claude Code」的位址，它再透過本機的 `adt-rfc-bridge`（Python 橋接程式，監聽 `127.0.0.1:8410`）轉 RFC 連進 SAP Host——兩層架構細節見 README.md「架構說明」與 `.claude/rules/sap-adt-mcp.md`。
- 建立物件（`sap_create_object`）與寫入原始碼（`sap_set_source`）一律先列出內容給我確認，不要靜默執行；啟用/鎖定/解鎖（`sap_activate`/`sap_lock`/`sap_unlock`）2026-07-12 起改為自動允許——這三個在正常開發流程裡幾乎每次寫完都要跑一次，且都是可逆操作（重新啟用、重新鎖定都行），要求逐次確認只會拖慢節奏而不會多攔到什麼風險；刪除物件與釋放/刪除傳輸請求在 `.claude/settings.json` 已直接鎖死（deny）。

## 待補充（請依實際專案填寫）

- [ ] SAP 系統 ID / Client / 語言
- [ ] 團隊程式碼風格細節（縮排慣例、關鍵字大小寫）
- [ ] ATC 檢查變式（Check Variant）名稱
- [ ] 常用套件清單與對應模組
- [x] 確認 `sap-adt` 實際暴露的工具名稱是否跟 `.claude/settings.json` 裡列的一致——2026-07-05 已校正（實際是底線式 `sap_xxx`，非駝峰式），詳見 `.claude/rules/sap-adt-mcp.md` 第 9 節；若之後 MCP server 版本更新，仍要重新核對。

## Claude Code 設定總覽

本專案用到的 CLAUDE.md / rules / skills / MCP 完整清單、各自的用途說明，以及**若要在新目錄複製同一套 sap-adt MCP 開發環境**該複製哪些檔案、改哪些地方，整理在 [`docs/claude-code-tooling-reference.md`](docs/claude-code-tooling-reference.md)。
