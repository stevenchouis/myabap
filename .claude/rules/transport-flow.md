---
paths:
  - "**/*.abap"
---

# 傳輸請求（Transport Request）工作流程

- 每個獨立功能 / 修正對應一個 Transport Request，不與其他任務共用。
- Request 描述請包含：功能簡述 + 關聯需求單號（若有）。

## 釋放前檢查清單

1. 是否已完成語法檢查（syntax check）且無錯誤。
2. 是否已執行 ATC 檢查，並排除嚴重（Error / Priority 1）項目。
3. 是否已補上／更新測試類別。
4. 是否有殘留的除錯用程式碼（`BREAK-POINT`、多餘 `WRITE` 輸出）需清除。

## 規則

- 除非我明確說「釋放」或「release」，否則不要自動執行傳輸請求釋放動作。
- 若使用 MCP 工具（例如 `transportRelease`）執行釋放，動作前務必先列出即將釋放的 Request 內容給我確認。
- 建立新物件（`createObject`）或修改現有物件的傳輸歸屬前，先確認要放入哪個 Transport Request，不要用預設值帶過。

## 未來若導入 abapGit

- 建議套件層級對應一個 Git repository，避免跨套件混合版控。
- `.abapgit.xml` 設定檔需納入版控；忽略清單可參考本專案的 `.gitignore`。
- 導入後請更新 `CLAUDE.md` 的「版控狀態」欄位。
