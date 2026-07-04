# OOP 練習 11：標準 OO API 實戰——cl_salv_table

## 學習目標

- 會用 `cl_salv_table=>factory( )` 把 internal table 變成 ALV——不用建 fieldcat
- 會沿著方法鏈設定 ALV：工具列、欄寬、標題、斑馬紋、單一欄位顯示/隱藏
- 會處理 SALV 的類別型例外（`cx_salv_msg`、`cx_salv_not_found`）——op09 實戰
- 會在 ADT 用 `F3` 導覽進 SAP 標準類別，自己找可用的方法
- 能對照 ex09 的 `REUSE_ALV_GRID_DISPLAY`，說出 OO API 的差異

## 事前準備

ADT 建立程式 `ZR_OO11_<你的姓名縮寫>`，套件 `$TMP`；SCARR 要有資料（同 ex09）。

## 題目需求

情境：把 ex09 的航空公司清單 ALV 改寫成 `cl_salv_table` 版——這是 ex09 講義結尾預告的「OO 寫法」。

1. `SELECT * FROM scarr` 進 internal table（inline declaration），沒資料就 `MESSAGE ... TYPE 'S' DISPLAY LIKE 'E'` 後 `RETURN`
2. `TRY` 區塊內：
   - `cl_salv_table=>factory( IMPORTING r_salv_table = DATA(go_alv) CHANGING t_table = ... )`
   - 方法鏈設定：`get_functions( )->set_all( )`（工具列全開）、`get_columns( )->set_optimize( )`（欄寬自動）、`get_display_settings( )->set_striped_pattern( )`、`set_list_header( )`（標題用 string template 帶筆數）
   - 把 `URL` 欄位藏起來：`get_columns( )->get_column( 'URL' )->set_visible( abap_false )`
   - `go_alv->display( )`
3. `CATCH cx_salv_msg` 與 `cx_salv_not_found`，用 `get_text( )` 輸出訊息
4. 執行後操作 ALV：排序、篩選、匯出（跟 ex09 一樣的內建功能）
5. 練 ADT 導覽：游標放在 `cl_salv_table` 按 `F3` 進標準類別，找找看還有什麼 `get_xxx`（提示：`get_sorts`、`get_aggregations`）

## 預期結果

ALV 顯示 SCARR 全欄位**但 URL 欄被藏掉**，斑馬紋、欄寬自動、標題含筆數；工具列完整（排序/篩選/合計/匯出）。

## 對比：ex09 vs op11

| | ex09（REUSE_ALV_GRID_DISPLAY） | op11（cl_salv_table） |
|---|---|---|
| 欄位定義 | 手工建 fieldcat（MACRO 連 append） | 自動從表格型別推導 |
| 設定方式 | 一大包 EXPORTING 參數 | 物件方法，要什麼設什麼 |
| 錯誤處理 | `sy-subrc` | 類別型例外（op09） |
| 客製欄位 | fieldcat 再加一列 | `get_column( )` 逐欄設定 |

## 團隊實務備註

- `cl_salv_table` 是**唯讀展示**的首選：程式碼最少、不用 fieldcat；要「可編輯格子」才需要 `cl_gui_alv_grid`（範圍外）
- factory + 方法鏈是 SAP 標準 API 的常見長相（`cl_gui_frontend_services`、`cl_abap_typedescr` 同款），這題練的導覽/查方法技能直接可搬
- `set_list_header` 的參數型別是 `lvc_title`（70 字元）——太長會截斷，別塞整段話
- SALV 例外全繼承 `cx_static_check`：不 CATCH 編譯不過——標準 API 也在用 op09 教的那套規矩

## 思考題

1. ex09 的 fieldcat 少寫一欄該欄就消失；op11 全欄位都出來、要藏才動手——兩種「預設」哪個比較不容易出錯？
2. 想把 CARRNAME 欄標題改成「航空公司名稱」：`F3` 進 `cl_salv_column` 找哪個方法？（提示：`set_short_text` / `set_medium_text` / `set_long_text` 為什麼有三個？）
3. `REUSE_ALV_GRID_DISPLAY` 沒被淘汰、大量舊程式還在用——維護舊程式碰到它，你現在的 OO 知識哪些直接可用？（提示：它內部其實也是包 OO 的）

## 答案

見 `zr_oo11_salv_demo.prog.abap`（SAP 端程式 `ZR_OO11_SALV_DEMO`）。
