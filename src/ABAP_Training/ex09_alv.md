# 練習 9：ALV 輸出——cl_salv_table

## 學習目標

- 會用 `cl_salv_table=>factory` + `display` 把 internal table 顯示成 ALV 表格
- 體會 ALV 相對於 WRITE 排版的優勢：排序/篩選/加總/匯出 Excel 全部內建
- 初識 `TRY ... CATCH ... ENDTRY` 例外處理與 `DATA(...)` 內聯宣告（先會用，細節後續課程）

## 事前準備

- 建立程式 `ZR_TR09_<你的姓名縮寫>`，套件 `$TMP`
- 需要 `SCARR` 有資料（同練習 6）

## 題目需求

1. `SELECT * FROM scarr INTO TABLE @gt_carriers.`（讀全部，SCARR 是小表），沒資料就提示並 `RETURN`
2. 用 `cl_salv_table=>factory` 建立 ALV 物件（照答案的 `TRY ... ENDTRY` 樣板抄，重點是理解結構）
3. 開啟工具列全部功能（`get_functions( )->set_all`）、欄寬最佳化（`get_columns( )->set_optimize`）
4. `display( )` 顯示
5. 執行後在 ALV 畫面上實際操作：點欄位標題排序、設篩選、匯出試算表

## 預期結果

執行後出現全螢幕 ALV 表格，顯示 SCARR 全部欄位（欄位標題自動帶 DDIC 的欄位說明），工具列有排序/篩選/匯出等按鈕。

## 對比：練習 6 vs 練習 9

| | ex06（WRITE） | ex09（ALV） |
|---|---|---|
| 排版 | 自己算欄位位置 | 自動（含欄寬最佳化） |
| 欄位標題 | 自己寫死 | DDIC 自動帶出 |
| 排序/篩選/匯出 | 要自己寫程式 | 內建 |
| 適用 | 簡單清單、背景輸出 | 絕大多數報表的標準答案 |

實務上：新報表輸出一律優先考慮 ALV，WRITE 用於特殊固定格式（如練習 6 之前看過的套表列印）。

## 思考題

1. 把 `TRY/CATCH` 拿掉直接呼叫 factory，語法檢查會過嗎？為什麼？（提示：`cx_salv_msg` 是 checked exception）
2. 想只顯示三個欄位（代碼/名稱/幣別）該怎麼做？（提示：宣告只有三個欄位的自訂結構型別來裝 SELECT 結果——這正是練習 3 學的 TYPES 的實戰用途）

## 答案

見 `zr_tr09_alv.prog.abap`（SAP 端程式 `ZR_TR09_ALV`）。
