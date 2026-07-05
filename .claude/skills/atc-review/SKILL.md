---
name: atc-review
description: 執行 ABAP Test Cockpit (ATC) 檢查並將結果整理成可讀報告。當使用者要求「跑 ATC」「檢查程式碼品質」或類似需求時使用。
---

# ATC 檢查與報告整理

1. 確認要檢查的物件範圍（單一物件 / 整個 Package / 整個 Transport Request）。
2. 使用團隊指定的 Check Variant 執行 ATC 檢查（若尚未在 `CLAUDE.md` 中指定，先詢問使用者要用哪個 Variant）。
3. 將檢查結果依嚴重程度分類整理：
   - **Error（必須修）**
   - **Warning（建議修）**
   - **Info（可忽略）**
4. 針對每個 Error/Warning，用一句話說明問題原因，並在可能的情況下附上修正建議，但**不要自動修改程式碼**，先跟使用者確認要不要修。
5. 輸出格式：物件名稱 → 問題行號 → 問題說明 → 建議修法，方便使用者逐項檢視。

> `sap-adt` MCP 工具的實際名稱與已知限制（含 ATC 相關工具）見 `.claude/rules/sap-adt-mcp.md`。
