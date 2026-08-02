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

## DDIC 欄位型別選擇（Table／CDS View／Structure）

- **⚠️ 硬性規則：新建的 Table／CDS View／Structure，若某個欄位在語意上對應到標準表的既有欄位（例如物料號碼對應 `MATNR`、廠別對應 `WERKS_D`、客戶對應 `KUNNR`），一律要直接引用標準表使用的那個 Data Element，不可以另外用 `abap.char(...)` 這類內建型別自己重新定義一個長度/型別剛好相同的版本，也不可以自建一個新的 Domain/DE 去平行複製。**
  - **為什麼**：標準 Data Element 已經跟系統既有的 Domain 固定值、Check Table／外鍵、Value Help、標準文字說明綁定好了，直接引用可以免費拿到這些（F4 下拉、跟其他標準表的型別 100% 相容、欄位標籤不用自己翻譯維護）；自己另外定義一個「長得很像」的型別，日後串接標準表（JOIN、Foreign Key、BAPI 呼叫）時容易因為型別技術上不同（即使長度/型別看起來一樣）而要額外做轉換，也違背「不要重造輪子」的原則。
  - **只有在真的找不到對應標準 Data Element、或欄位是這個專案/課程獨有的業務概念時**（例如 rap02 的 `status`／`priority` 這種課程自訂的固定值欄位），才自己建 Domain/DE 或用內建型別。
  - **查證方法**：不要憑記憶猜標準 Data Element 名稱，用 ADT quickSearch（`.claude/rules/sap-adt-mcp.md` 第 2 節）或讀一張已知有這個欄位的標準表（如 `MARA` 有 `MATNR`）的欄位定義，確認實際的 Data Element 名稱後再引用。
