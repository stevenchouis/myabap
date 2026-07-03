---
paths:
  - "**/*.abap"
  - "**/*.clas.abap"
  - "**/*.prog.abap"
  - "**/*.fugr.abap"
---

# ABAP 程式風格細則

- 縮排：使用 2 個空白。
- 關鍵字：建議小寫（依 Pretty Printer 預設），除非團隊另有規定，請在此補充。

## 變數命名

| 用途 | 前綴 |
|---|---|
| 區域變數 / 表格 / 結構 / 物件參考 | `lv_`, `lt_`, `ls_`, `lo_` |
| 全域屬性 | `gv_`, `gt_`, `gs_`, `go_` |
| Import 參數 | `iv_`, `it_`, `is_`, `io_` |
| Export 參數 | `ev_`, `et_`, `es_`, `eo_` |
| Return 參數 | `rv_`, `rt_`, `rs_`, `ro_` |

## 程式碼品質

- 每個 Class 方法盡量保持單一職責，避免超過約 60 行；太長時拆分私有方法。
- 自訂例外類別統一繼承 `CX_STATIC_CHECK` 或 `CX_DYNAMIC_CHECK`（依情境），並附上有意義的錯誤訊息。
- 避免過時語法（如 `MOVE`、舊式 `PERFORM ... TABLES` 呼叫），優先使用現代 ABAP 語法（Inline Declaration、Method Chaining、`VALUE` / `REDUCE` / `COND`）。
- 所有新建 Class 必須附上對應測試類別（Local Test Class），涵蓋主要邏輯分支。
- 不要留下除錯用程式碼（`BREAK-POINT`、多餘的 `WRITE` 除錯輸出）。
