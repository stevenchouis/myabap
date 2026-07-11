# SAP ABAP Classic REST API 課程

OOP 課程（`src/ABAP_Training_OOP/`，op01–op13）的續篇。課綱草案（2026-07-11），尚未出題。

## 課程定位

- **對象**：完成 OOP 課程的學員（會 Class/Interface/例外/ABAP Unit/cl_salv_table）
- **技術範圍**：Classic REST（`CL_REST_HTTP_HANDLER` + `CL_REST_RESOURCE`），非 RAP/CDS 那條線的現代 REST（那是另一階段候選主題）
- **結業標準**：能獨立設計一個小型 CRUD REST Service——Application/Resource 分工、URI 路由、JSON 序列化、狀態碼語意、統一錯誤格式、商業邏輯與 REST 轉接層分離並附 ABAP Unit 測試
- **本課程題號＝授課順序**，期末實作是最後一題

## 教材慣例

- 每題三件套：題目 `rsNN_主題.md` + PDF 講義（`node tools/md2pdf.js src/ABAP_Training_REST`）+ 答案快照
- 答案物件命名：`ZCL_RSnn_*`（Application / Resource / Service 類別）/ `ZCX_RSnn_*`（例外類別），套件 `$TMP`
- 資料模型：沿用 SCARR/SFLIGHT/SBOOK 航班訓練模型，與 OOP 課程一致，不額外建 DDIC 表
- **SICF 節點掛載無 ADT API**（跟 T-code、Search Help 一樣是 GUI-only，見 `.claude/rules/sap-adt-mcp.md` 第 9/12 節），每題若要在瀏覽器/Postman 實測，SICF 手動掛載步驟寫在題目 md 裡，由學員（你）在 SAP GUI 操作；Claude 負責 Handler/Resource/Service 類別的程式碼與 ADT 端啟用

## 課綱（草案，待逐題出題與驗收）

| # | 主題 | 內容重點 | 銜接 OOP 課程 | 狀態 |
|---|---|---|---|---|
| rs01 | 為什麼要 REST + 架構總覽 | HTTP 動詞語意（GET/POST/PUT/DELETE 與冪等性）、`CL_REST_HTTP_HANDLER`／`CL_REST_RESOURCE`／SICF 三者關係、最簡單的純文字 GET echo service | 對照 op01「為什麼要 OOP」的破題方式 | 已驗收 |
| rs02 | 第一個 REST Service：Application 與 Resource | `IF_REST_APPLICATION~GET_ROOT_HANDLER`、`CL_REST_ROUTER~ATTACH`、Resource Class 繼承 `CL_REST_RESOURCE` 覆寫 `IF_REST_RESOURCE~GET` | 承 op05 全域類別、op07 介面 | 已驗收 |
| rs03 | JSON 序列化與集合查詢 | `/ui2/cl_json`、SFLIGHT 查詢結果轉 JSON array、Content-Type 設定 | 對照 op11 cl_salv_table 的「標準 API 實戰」定位 | 未出題 |
| rs04 | URI 路徑參數與單筆查詢 | `GET_URI_ATTRIBUTES` 取路徑變數（如 `/flights/{carrid}/{connid}`）、集合 vs 單筆兩種 GET 邏輯 | — | 未出題 |
| rs05 | Query Parameter 篩選 | `GET_QUERY_PARAMETERS`、篩選條件動態組 WHERE、找不到資料回 404 | 承 op09 例外處理的錯誤情境設計 | 未出題 |
| rs06 | POST 建立資源 | Request body 讀取（`GET_ENTITY->GET_STRING_DATA`）+ JSON 反序列化、`201 Created` + Location Header | — | 未出題 |
| rs07 | PUT/DELETE 與統一錯誤格式 | PUT 更新、DELETE 刪除、狀態碼語意（200/204/400/404）、`ZCX_` 例外攔截轉標準 JSON error body，避免未捕捉例外變成 dump | 承 op09 自訂例外類別設計 | 未出題 |
| rs08 | REST Resource 的可測試性 | 商業邏輯搬進 `ZCL_RSnn_*_SERVICE`，Resource 只做「解析 request → 呼叫 Service → 組 response」的薄層轉接，Service Class 附 ABAP Unit 測試 | 兌現 op10 ABAP Unit + op12 重構精神 | 未出題 |
| rs09 | 期末整合：Flight Booking CRUD REST API | SBOOK 的完整 GET（集合+單筆+篩選）/POST/PUT/DELETE，Service/Resource 分層、統一錯誤格式、ABAP Unit 測試，SICF 掛載後用 Postman/瀏覽器實測全流程 | 對照 op12 期末報表重構的收斂角色 | 未出題 |

## 不碰的範圍（下一階段）

RAP（RESTful ABAP Programming Model）/ CDS 那條現代化路線、OAuth 等正式驗證機制（僅在深度選項提到但本輪課綱未收錄）、Design Pattern。

## 出題工作流程（比照 OOP 課程）

SAP 建物件（`sap_create_object`；MCP 不支援的物件類型見 `.claude/rules/sap-adt-mcp.md` 的 ADT API workaround）→ `sap_set_source` 寫入 → curl 啟用 + 語法檢查 → 若該題需要 SICF 才能實測，題目 md 附手動掛載步驟由使用者操作 → 使用者驗收 → 快照（curl 下載 active 版本）→ 題目 md → `node tools/md2pdf.js src/ABAP_Training_REST` 產 PDF → 更新本 README 狀態 → commit。每批 2–3 題、使用者驗收後再繼續。
