# 練習 10：Report Event 事件流程

## 學習目標

- 理解 Report 是**事件驅動**：系統在不同時機觸發各事件區塊，跟程式碼寫的位置無關
- 掌握六個常用事件的觸發時機與典型用途：

| 事件 | 時機 | 典型用途 |
|---|---|---|
| `INITIALIZATION` | 選擇畫面顯示前 | 給預設值 |
| `AT SELECTION-SCREEN` | 按執行後、主程式前 | 驗證輸入（E 訊息擋在畫面） |
| `START-OF-SELECTION` | 主處理 | 取數、運算、輸出 |
| `END-OF-SELECTION` | 主處理結束 | 總結、統計 |
| `TOP-OF-PAGE` | 清單每頁開頭 | 表頭 |
| `AT LINE-SELECTION` | 清單上雙擊/F2 | 互動明細（第二層清單） |

- 會用 `HIDE` 把行資料藏進清單、在 `AT LINE-SELECTION` 取回
- 會用 `LIKE LINE OF` 宣告 selection table 的 work area（回收練習 7 思考題）

## 事前準備

建立程式 `ZR_TR10_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 學生資料 4 筆（期中/期末），選擇畫面一個成績範圍 `SELECT-OPTIONS`
2. `INITIALIZATION`：預設範圍 0～100（用 `LIKE LINE OF` 的 work area 組 `sign/option/low/high` 後 APPEND）
3. `AT SELECTION-SCREEN`：範圍超出 0～999 時發 E 訊息擋下
4. `START-OF-SELECTION`：列出符合條件的學生（學號/姓名/期中/期末），每行 `HIDE` 學號，並累計筆數
5. `END-OF-SELECTION`：輸出「符合條件筆數」
6. `TOP-OF-PAGE`：表頭標題與橫線
7. `AT LINE-SELECTION`：雙擊資料行顯示該學生完整明細；雙擊非資料行顯示「請雙擊資料行」（提示：LOOP 結束後 `CLEAR` HIDE 用的變數）

## 測試案例

| 操作 | 預期結果 |
|---|---|
| 直接執行（預設 0~100） | 表頭 + 4 筆 + 「符合條件筆數: 4」 |
| 範圍輸入 -5 ~ 100 | E 訊息擋在選擇畫面 |
| 範圍輸入 70 ~ 100 | 只列期中 >= 70 的學生 |
| 雙擊「李小美」那一行 | 第二層清單顯示她的完整明細 |
| 雙擊表頭或空白處 | 顯示「請雙擊資料行」 |

## 觀察重點

把 `TOP-OF-PAGE` 區塊移到程式最上面再執行一次——輸出完全一樣。**事件區塊的位置不影響觸發順序**，這是 Report 跟一般「由上而下」程式最大的差別。

## 思考題

1. 表頭為什麼不寫在 `START-OF-SELECTION` 開頭就好？（提示：資料超過一頁時會怎樣？）
2. `HIDE` 藏的是「變數在 WRITE 當下的值」——如果 `HIDE` 寫在 `WRITE` 之前一行，行為會變嗎？
3. 本專案的 `Z_INVENTORY_COST_REPORT` 用了哪些事件？它的 `END-OF-SELECTION` 在做一件很特別的事（回填總頁數），去讀讀看

## 答案

見 `zr_tr10_events.prog.abap`（SAP 端程式 `ZR_TR10_EVENTS`）。
