# sap-adt MCP 已知限制與 Workaround

> 2026-07-03 實測（本機 ADT 代理 `http://127.0.0.1:8410`，sap-client=130）。
> 代理埠號可能因環境而異；MCP server 修正後請重新驗證並更新本檔。

## 1. `sap_get_source` / `sap_object_structure` 讀不到 INCLUDE（HTTP 404）

工具一律組 `programs/programs` 路徑，但 INCLUDE 的 ADT 資源路徑是 `programs/includes`。

**Workaround**：直接對代理呼叫正確路徑：

```bash
curl 'http://127.0.0.1:8410/sap/bc/adt/programs/includes/<include名>/source/main?sap-client=130&sap-language=EN'
```

## 2. `sap_search_object` 永遠回 0 筆

對已知存在的物件（如 ZDQM0001）也查無結果，工具的搜尋包裝有問題（ADT 本身正常）。

**Workaround**：直接打 ADT quickSearch API，回 XML（含物件 URI、類型、套件）：

```bash
curl 'http://127.0.0.1:8410/sap/bc/adt/repository/informationsystem/search?operation=quickSearch&query=ZDQM*&maxResults=100&sap-client=130'
```

## 3. `sap_sql_query` 回空結果

連 T000 都查不到資料（columns/rows 皆空），SQL 查詢失效或無權限，目前無 workaround，勿依賴此工具。

## 匯出 SAP 原始碼到 src/ 的慣例

- 檔名採 abapGit 格式：`<物件名小寫>.<類型>.abap`（如 `zdqm0001.prog.abap`；INCLUDE 也是 `.prog.abap`）。
- 主程式要連同其 INCLUDE 一起匯出；多支程式共用的 INCLUDE 只存一份。
- `src/` 是**單向快照**：SAP 端修改後需重新匯出；本地修改要用 `sap_set_source` 寫回系統才算數。
