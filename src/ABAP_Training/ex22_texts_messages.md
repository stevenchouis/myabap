# 練習 22：Message Class 與多語言文字元素

> 授課順序：接在練習 10 之後、練習 11 之前。講義見 [lec22](lectures/lec22_texts_messages.md)。

## 學習目標

- 會在 SE91 建 Message Class，會用 `&1`～`&4` 佔位符
- 會維護 Text Symbols 與 Selection Texts，理解 `text-nnn` 與 `'文字'(nnn)` 的 fallback 差異
- 會寫 `MESSAGE 型別+編號(類別) WITH ...`，理解型別是呼叫端決定的
- 理解登入語言與翻譯（Goto → Translation）的關係

## 事前準備

- 建立程式 `ZR_TR22_<你的姓名縮寫>`，套件 `$TMP`
- SE91 建立訊息類別 `ZTR22_<你的姓名縮寫>`（示範解答用 `ZTR22`），維護三則訊息：

| 編號 | 訊息文字 |
|---|---|
| 001 | 請至少輸入一個查詢條件 |
| 002 | 查詢完成：共 &1 筆（由 &2 於 &3 執行） |
| 003 | 成績上限不可超過 &1 |

## 題目需求

1. 沿用練習 10 的學生資料與選擇畫面（`s_score` 成績範圍、加一個 `p_name` 姓名參數），**程式中不得出現任何寫死的中文字串**（字面文字＋符號的 fallback 寫法除外）
2. 維護 **Selection Texts**：`S_SCORE`「成績範圍」、`P_NAME`「學生姓名」——執行畫面不能再出現變數名
3. 維護 **Text Symbols**：`001` 報表標題、`002`「查詢條件：」、`003`「符合筆數：」；標題用 `'學生成績查詢'(001)` 的 fallback 寫法，其餘用 `text-nnn`
4. `AT SELECTION-SCREEN` 驗證：
   - `s_score` 與 `p_name` 都空白 → `MESSAGE e001(...)`（擋在畫面上）
   - `s_score` 上限超過 999 → `MESSAGE e003(...) WITH 999`
5. `START-OF-SELECTION`：過濾輸出明細（標題、條件、明細行都用文字元素），最後 `MESSAGE s002(...) WITH 筆數 sy-uname sy-datum`——觀察狀態列的佔位符替換
6. 把 `s002` 那行改成加 `DISPLAY LIKE 'E'` 再跑一次，觀察「內容是 S、樣式像 E」的效果，之後改回來
7. 翻譯實驗（二選一）：
   - 有英文語言環境：Goto → Translation 維護 EN 文字，用 EN 重新登入執行，截圖對照
   - 沒有：把 Text Symbol `002` 刪掉再執行，觀察 `text-002` 開天窗 vs 標題（fallback 寫法）仍正常，再加回來

## 預期輸出（範例，ZF 登入）

選擇畫面顯示「成績範圍」「學生姓名」（不是 S_SCORE/P_NAME）。

```
學生成績查詢
查詢條件： 60  ～ 100
S0001 王小明             85
S0002 李小美             92
S0003 陳大文             67
符合筆數：          3
```

狀態列（S 訊息）：`查詢完成：共 3 筆（由 STEVE 於 2026/07/05 執行）`

兩個條件都空白直接執行時：被 `請至少輸入一個查詢條件` 擋在選擇畫面。

## 思考題

1. 訊息 002 的型別為什麼用 `s` 不用 `i`？兩者使用者體驗差在哪？
2. `text-nnn` 開天窗和 `'文字'(nnn)` fallback，各適合什麼情境？為什麼舊程式常看到前者？
3. 同一則 001 訊息，在 `AT SELECTION-SCREEN` 用 `e`、在 `START-OF-SELECTION` 用 `e`，行為一樣嗎？（提示：實際試試看——事件位置會影響 E 訊息的效果）

## 答案

見 `zr_tr22_texts.prog.abap`（SAP 端程式 `ZR_TR22_TEXTS`＋訊息類別 `ZTR22`；Text Symbols / Selection Texts 內容以程式開頭註解為準）。
