# 講義 22：Message Class 與多語言文字元素（授課順序：接在講義 10 之後）

> 對應練習：[ex22](../ex22_texts_messages.md)｜答案物件：訊息類別 `ZTR22`＋程式 `ZR_TR22_TEXTS`

## 本講重點

- 為什麼文字不能寫死在程式裡：多語言與集中維護
- Text Symbol（文字符號）：`text-nnn` 與 `'字面文字'(nnn)` 兩種寫法
- Selection Texts：讓選擇畫面顯示欄位說明而不是變數名
- Message Class（SE91）：集中管理訊息、`&` 佔位符、`MESSAGE` 完整語法
- 翻譯機制：登入語言、Goto → Translation、SE63

## 1. 為什麼文字不能寫死

到目前為止我們都這樣寫：

```abap
WRITE / '學生成績清單'.
MESSAGE '成績範圍請輸入 0～999' TYPE 'E'.
```

正式程式這樣寫有三個問題：

- **多語言**：英文使用者登入看到的還是中文——SAP 是多語言系統，同一支程式要依**登入語言**顯示對應文字。
- **集中維護**：措辭要改得全程式搜尋替換；文字元素改一處就好，而且不用改程式碼（不進版本比對的邏輯差異）。
- **翻譯流程**：公司的翻譯（SE63）只能翻「文字元素」，翻不到寫死在程式碼裡的字串。

解法就是本講的三個機制：Text Symbol（一般輸出文字）、Selection Texts（選擇畫面標籤）、Message Class（訊息）。三者都掛在「文字元素（Text Elements）」或獨立物件上，**依登入語言取用**。

## 2. Text Symbol：程式的文字符號

維護處：SE38 → Goto → Text Elements → **Text Symbols**。每個符號是三碼編號＋文字（單筆上限 132 字元），例如：

```
001  學生成績查詢
002  查詢條件：
003  符合筆數：
```

程式裡兩種寫法：

```abap
WRITE / text-001.                    " 寫法一：純符號
WRITE / '學生成績查詢'(001).          " 寫法二：字面文字＋符號
```

兩種的差別在**找不到文字時的行為**（重要！）：

| 寫法 | 登入語言有維護 | 登入語言沒維護 |
|---|---|---|
| `text-001` | 顯示該語言文字 | **空白**（initial） |
| `'學生成績查詢'(001)` | 顯示該語言文字 | 顯示程式裡的字面文字（fallback） |

團隊實務多用**寫法二**：程式碼自帶可讀的原文，翻譯沒跟上也不會開天窗；純 `text-nnn` 則常見於舊程式。Text Symbol 是**每支程式自己一套**，不跨程式共用。

## 3. Selection Texts：選擇畫面的欄位標籤

沒維護時，選擇畫面上顯示的是變數名（`P_NAME`、`S_SCORE`）——使用者看不懂。維護處：SE38 → Goto → Text Elements → **Selection Texts**，每個畫面欄位一行：

```
P_NAME   學生姓名
S_SCORE  成績範圍
```

- 參考 DDIC 欄位的參數（如 `PARAMETERS p_carr TYPE scarr-carrid.`）可以勾 **Dictionary Reference**：直接沿用 Data Element 的欄位標籤（講義 21 的三層件又出現了）——標籤全系統一致、翻譯也是現成的，**能勾就勾**。
- 自訂型別的欄位才需要手打文字。

## 4. Message Class：訊息的集中管理

講義 10 的 `MESSAGE '文字' TYPE 'E'` 是字面寫法，正式做法是把訊息收進 **Message Class**（SE91 建立，命名 `Z` 開頭，如 `ZTR22`），每則訊息一個三碼編號，`&`（或 `&1`～`&4`）是佔位符：

```
001  請至少輸入一個查詢條件
002  查詢完成：共 &1 筆（由 &2 於 &3 執行）
003  成績上限不可超過 &1
```

### 4.1 MESSAGE 語法

```abap
* 短式（最常用）：型別字母 + 編號 + (訊息類別)
MESSAGE e001(ztr22).

* 帶佔位符：WITH 依序填 &1 &2 &3 &4
MESSAGE s002(ztr22) WITH lv_count sy-uname sy-datum.

* 長式（舊程式常見，看得懂即可）：
MESSAGE ID 'ZTR22' TYPE 'E' NUMBER '001'.

* 顯示技巧：S 訊息的資料（不中斷），但用紅色錯誤樣式顯示
MESSAGE s003(ztr22) WITH 999 DISPLAY LIKE 'E'.
```

重點觀念：

- **訊息型別（I/S/W/E/A，講義 10 的表）不屬於訊息本身**，是呼叫端決定的——同一則 001，可以 `e001(ztr22)` 也可以 `i001(ztr22)`，行為依當下型別與所在事件而定。
- 訊息發出後，系統欄位記錄著它：`sy-msgid`（類別）、`sy-msgty`（型別）、`sy-msgno`（編號）、`sy-msgv1`～`sy-msgv4`（佔位符值）——除錯與寫 log 都用得到。
- CALL FUNCTION 的例外訊息、之後 BAPI 的回傳訊息（BAPIRET2）都是這套機制——現在建立的觀念直通實務。

### 4.2 什麼時候用哪種文字機制

| 場景 | 機制 |
|---|---|
| 報表輸出的標題、欄頭、固定文字 | Text Symbol |
| 選擇畫面欄位標籤 | Selection Texts（優先 Dictionary Reference） |
| 驗證錯誤、完成通知、狀態列訊息 | Message Class |

## 5. 翻譯與登入語言

- 文字元素維護時有「原始語言」（程式屬性裡的 Original Language）；其他語言用 SE38 → Goto → Translation（或集中在 **SE63**）維護。
- 執行時依**登入語言**取文字：EN 登入拿英文、ZF 登入拿繁中。練習時用兩種語言各登入一次，是理解整套機制最快的方式。
- 翻譯缺漏的行為回顧：`text-nnn` 開天窗、`'文字'(nnn)` 有 fallback、訊息類別未翻譯則顯示原始語言（不會空白）。
- 正式專案的慣例請跟團隊確認：原始語言用 EN 還是 ZF、翻譯由誰維護——建物件前先問，事後改原始語言很麻煩。

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 畫面/報表某段文字整個空白 | `text-nnn` 在登入語言沒維護——改用 `'文字'(nnn)` 或補翻譯 |
| 選擇畫面顯示 P_NAME 這種變數名 | Selection Texts 沒維護 |
| MESSAGE 的 &1 沒被取代、直接顯示 & | WITH 的參數個數與佔位符對不上 |
| 訊息內容對、行為不對（沒擋住使用者） | 型別字母用錯——擋人要在 AT SELECTION-SCREEN 用 `e` |
| 文字改了沒生效 | 文字元素也要**啟用**（Text Elements 畫面內 Activate） |
| 換語言登入還是原語言 | 該語言沒翻譯，或看的是訊息類別的原始語言 fallback |

## 7. 課堂練習

完成 [ex22](../ex22_texts_messages.md)：建訊息類別 `ZTR22`、維護 Text Symbols 與 Selection Texts，把練習 10 等級的報表改造成「零寫死文字」版本，並用佔位符訊息回報查詢結果。
