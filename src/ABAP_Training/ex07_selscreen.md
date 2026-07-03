# 練習 7：選擇畫面——PARAMETERS 與 SELECT-OPTIONS

## 學習目標

- 會用 `PARAMETERS` 做單一輸入（`DEFAULT`、`AS CHECKBOX`）
- 會用 `SELECT-OPTIONS ... FOR` 做範圍條件，理解它跟 `PARAMETERS` 的差別
- 會用 `IN` 判斷值是否落在範圍條件內
- 會用 `SELECTION-SCREEN BEGIN OF BLOCK ... WITH FRAME TITLE` 分區
- 知道 `INITIALIZATION` 事件給畫面文字賦值

## 事前準備

- 建立程式 `ZR_TR07_<你的姓名縮寫>`，套件 `$TMP`
- 延伸教材：執行 `ZR_SELSCREEN_DEMO`（示範程式）看更多選擇畫面元件——按鈕、同列排版、radio button 群組

## 題目需求

1. 沿用練習 4 的學生資料（4 筆，成績 85/92/67/45）
2. 選擇畫面一個 BLOCK（有框、有標題）內含：
   - `p_title`：報表標題，預設「學生成績清單」
   - `s_score`：成績範圍（`SELECT-OPTIONS`）
   - `p_desc`：核取方塊，勾選＝由高到低排序
3. 依畫面條件輸出：標題 → 橫線（`ULINE`）→ 符合成績範圍的學生（用 `LOOP ... WHERE score IN s_score`）
4. 一筆都沒有時輸出「沒有符合條件的資料」（`LOOP` 後檢查 `sy-subrc`）

## 測試案例

| 輸入 | 預期結果 |
|---|---|
| 不輸入任何條件 | 4 筆全列（範圍條件空白 = 全部通過） |
| s_score 輸入 60 ~ 90 | 只剩 85、67 兩筆 |
| 勾選 p_desc | 依成績由高到低 |
| s_score 輸入 100 ~ 200 | 顯示「沒有符合條件的資料」 |

## 思考題

1. `PARAMETERS` 和 `SELECT-OPTIONS` 什麼時候該用哪個？（提示：回頭看 Z_INVENTORY_COST_REPORT 的 `p_werks` 和 `s_matnr`）
2. `SELECT-OPTIONS` 其實是一個特殊的 internal table（selection table）——在程式裡 `LOOP AT s_score` 印出它的 `sign`/`option`/`low`/`high` 四個欄位看看

## 答案

見 `zr_tr07_selscreen.prog.abap`（SAP 端程式 `ZR_TR07_SELSCREEN`）。
