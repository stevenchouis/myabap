---
marp: true
theme: default
paginate: true
headingDivider: false
style: |
  section {
    font-family: 'Microsoft JhengHei', 'Noto Sans TC', sans-serif;
    font-size: 26px;
    padding: 60px;
  }
  section.lead {
    text-align: center;
    justify-content: center;
  }
  section.lead h1 { font-size: 56px; }
  code, pre {
    font-family: Consolas, 'Courier New', monospace;
  }
  pre {
    font-size: 21px;
    line-height: 1.45;
  }
  table { font-size: 23px; }
  section.compact pre { font-size: 19px; }
  section.compact table { font-size: 20px; }
  blockquote {
    border-left: 6px solid #0a6ed1;
    padding-left: 16px;
    color: #333;
    background: #eef6fc;
  }
  footer { color: #999; }
---

<!-- _class: lead -->
<!-- _paginate: false -->

# 講義 22
# Message Class 與多語言文字元素

ABAP 基礎教育訓練（授課順序：接在講義 10 之後）

對應練習 ex22｜答案：訊息類別 `ZTR22`＋程式 `ZR_TR22_TEXTS`

---

## 本講重點

- 為什麼文字不能寫死在程式裡：多語言與集中維護
- Text Symbol：`text-nnn` 與 `'字面文字'(nnn)` 兩種寫法
- Selection Texts：選擇畫面顯示欄位說明而不是變數名
- Message Class（SE91）：集中管理訊息、`&` 佔位符
- 翻譯機制：登入語言、Goto → Translation、SE63

---

## 1. 為什麼文字不能寫死

```abap
WRITE / '學生成績清單'.
MESSAGE '成績範圍請輸入 0～999' TYPE 'E'.
```

正式程式這樣寫的三個問題：

- **多語言**：英文使用者登入看到的還是中文
- **集中維護**：措辭要改得全程式搜尋替換
- **翻譯流程**：SE63 只能翻「文字元素」，翻不到寫死的字串

解法＝三個機制，都**依登入語言取用**：
Text Symbol（輸出文字）、Selection Texts（畫面標籤）、
Message Class（訊息）

---

## 2. Text Symbol

維護：SE38 → Goto → Text Elements → **Text Symbols**
（三碼編號＋文字，每支程式自己一套）

```abap
WRITE / text-001.                    " 寫法一：純符號
WRITE / '學生成績查詢'(001).          " 寫法二：字面文字＋符號
```

**差別在找不到文字時的行為（重要！）**：

| 寫法 | 該語言有維護 | 該語言沒維護 |
|---|---|---|
| `text-001` | 顯示該語言文字 | **空白**（開天窗） |
| `'學生成績查詢'(001)` | 顯示該語言文字 | 顯示字面文字（fallback） |

團隊實務多用**寫法二**：翻譯沒跟上也不會開天窗

---

## 3. Selection Texts

沒維護時，選擇畫面顯示變數名（`P_NAME`）——使用者看不懂

維護：SE38 → Goto → Text Elements → **Selection Texts**

```
P_NAME   學生姓名
S_SCORE  成績範圍
```

> 參考 DDIC 欄位的參數可勾 **Dictionary Reference**：
> 直接沿用 Data Element 的欄位標籤（講義 21 三層件又出現）
> 標籤全系統一致、翻譯現成——**能勾就勾**

---

## 4. Message Class（SE91）

訊息收進 Message Class（`Z` 開頭，如 `ZTR22`）
三碼編號、`&1`～`&4` 佔位符：

```
001  請至少輸入一個查詢條件
002  查詢完成：共 &1 筆（由 &2 於 &3 執行）
003  成績上限不可超過 &1
```

```abap
* 短式（最常用）：型別字母 + 編號 + (訊息類別)
MESSAGE e001(ztr22).

* 帶佔位符：WITH 依序填 &1 &2 &3
MESSAGE s002(ztr22) WITH lv_count sy-uname sy-datum.

* 長式（舊程式常見）：
MESSAGE ID 'ZTR22' TYPE 'E' NUMBER '001'.

* S 訊息資料、紅色錯誤樣式顯示（不中斷）：
MESSAGE s003(ztr22) WITH 999 DISPLAY LIKE 'E'.
```

---

## 訊息機制的重點觀念

**型別（I/S/W/E/A）不屬於訊息本身，是呼叫端決定的**
同一則 001：`e001(ztr22)` 擋人、`i001(ztr22)` 只是彈窗

訊息發出後，系統欄位記錄著它：
`sy-msgid`（類別）、`sy-msgty`（型別）、
`sy-msgno`（編號）、`sy-msgv1`～`4`（佔位符值）

> CALL FUNCTION 的例外訊息、BAPI 的回傳（BAPIRET2）
> 都是這套機制——現在的觀念直通實務

| 場景 | 機制 |
|---|---|
| 報表標題、欄頭、固定文字 | Text Symbol |
| 選擇畫面欄位標籤 | Selection Texts（優先 Dict. Ref.） |
| 驗證錯誤、完成通知 | Message Class |

---

## 5. 翻譯與登入語言

- 文字元素有「**原始語言**」（程式屬性 Original Language）
  其他語言：SE38 → Goto → Translation，或集中在 **SE63**
- 執行時依**登入語言**取文字：EN 拿英文、ZF 拿繁中
  → 練習時兩種語言各登入一次，理解最快
- 翻譯缺漏行為：`text-nnn` 開天窗、`'文字'(nnn)` 有 fallback、
  訊息類別顯示原始語言（不會空白）

> 正式專案先跟團隊確認：原始語言 EN 還是 ZF、翻譯誰維護
> ——事後改原始語言很麻煩

---

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 某段文字整個空白 | `text-nnn` 該語言沒維護——用 `'文字'(nnn)` |
| 畫面顯示 P_NAME 變數名 | Selection Texts 沒維護 |
| &1 沒被取代、直接顯示 & | WITH 參數個數對不上 |
| 訊息內容對、沒擋住使用者 | 型別字母用錯——擋人用 `e` |
| 文字改了沒生效 | 文字元素也要**啟用**（Activate） |
| 換語言登入還是原語言 | 沒翻譯、或是訊息類別的 fallback |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex22**：

建訊息類別 `ZTR22`、維護 Text Symbols 與 Selection Texts

把練習 10 等級的報表改造成「零寫死文字」版本
用佔位符訊息回報查詢結果
