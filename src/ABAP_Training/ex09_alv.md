# 練習 9：Functional ALV 與 MACRO

## 學習目標

- 會用 Function Module `REUSE_ALV_GRID_DISPLAY` 把 internal table 顯示成 ALV 表格
- 理解欄位目錄（fieldcat，`slis_t_fieldcat_alv`）：告訴 ALV 顯示哪些欄位、標題、寬度
- 會定義與使用 `MACRO`（`DEFINE ... END-OF-DEFINITION`、`&1 &2 &3` 佔位參數）
- 體會 ALV 相對於 WRITE 排版的優勢：排序/篩選/加總/匯出全部內建
- 初識 `CALL FUNCTION` 的 `EXPORTING`/`TABLES`/`EXCEPTIONS` 結構

## 事前準備

- 建立程式 `ZR_TR09_<你的姓名縮寫>`，套件 `$TMP`
- 需要 `SCARR` 有資料（同練習 6）

## 題目需求

1. `SELECT * FROM scarr INTO TABLE gt_carriers.` 讀資料，沒資料就提示並 `RETURN`
2. 定義 MACRO `mc_add_field`，接三個參數（欄位名/標題/寬度），內容是「清空 work area → 填三個欄位 → APPEND 到 fieldcat」
3. 用 MACRO 連續四行建出 CARRID / CARRNAME / CURRCODE / URL 的欄位目錄
4. 呼叫 `REUSE_ALV_GRID_DISPLAY`（`i_callback_program = sy-repid`、傳入 fieldcat 與資料表），檢查 `sy-subrc`
5. 執行後在 ALV 畫面實際操作：點欄位標題排序、設篩選、匯出試算表

## 預期結果

執行後出現 ALV 表格，只顯示 fieldcat 定義的四個欄位，標題是你自訂的中文字，工具列有排序/篩選/匯出等按鈕。

## 關於 MACRO

- 語法：`DEFINE 名稱.` ～ `END-OF-DEFINITION.`，呼叫時 `名稱 參數1 參數2 ... .`，`&1`～`&9` 依序代入
- 適合「一模一樣的程式碼重複多次」的場景（例如本題的 fieldcat、BDC 程式的 append_bdc 場景）
- **缺點**：無法下中斷點、除錯器直接跳過、錯誤訊息難讀——所以新程式碼優先用 FORM，MACRO 以「看得懂舊程式」為主
- 本專案實例：`ZDQM0001F01` 的 `gui_download` 就是 MACRO，學完本課回頭看就懂了

## 對比：練習 6 vs 練習 9

| | ex06（WRITE） | ex09（Functional ALV） |
|---|---|---|
| 排版 | 自己算欄位位置 | fieldcat 定義即可 |
| 排序/篩選/匯出 | 要自己寫程式 | 內建 |
| 適用 | 簡單清單、背景輸出 | 絕大多數報表的標準答案 |

另有 OO 寫法 `cl_salv_table`（連 fieldcat 都不用建），留待 SAP OOP 課程。

## 思考題

1. fieldcat 少寫一個欄位（例如拿掉 URL），ALV 會怎樣？多寫一個 internal table 沒有的欄位名呢？（動手試）
2. 把 MACRO 改寫成 FORM `add_field`，比較兩種寫法——哪個能下中斷點？

## 答案

見 `zr_tr09_alv.prog.abap`（SAP 端程式 `ZR_TR09_ALV`）。
