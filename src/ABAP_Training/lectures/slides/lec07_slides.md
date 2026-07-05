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

# 講義 7
# 選擇畫面

PARAMETERS / SELECT-OPTIONS / IN

對應練習 ex07｜答案程式 `ZR_TR07_SELSCREEN`

---

## 本講重點

- 選擇畫面是什麼、何時產生
- `PARAMETERS`：單值輸入與各種附加選項
- `SELECT-OPTIONS`：範圍條件與背後的 range 表
- `IN` 運算子：range 條件用在 SELECT、LOOP、IF
- `SELECTION-SCREEN BLOCK` 畫面排版

---

## 1. 選擇畫面是什麼

宣告區寫 `PARAMETERS` / `SELECT-OPTIONS`
→ 系統**自動**產生輸入畫面，執行時先顯示
→ 使用者填完按 F8 才進主邏輯

**不用自己畫畫面**——傳統報表開發效率高的原因之一

命名限制：畫面欄位名**最長 8 個字元**
慣例：`p_` = PARAMETERS、`s_` = SELECT-OPTIONS

---

## 2. PARAMETERS：單值輸入

```abap
PARAMETERS p_title TYPE c LENGTH 20 DEFAULT '學生成績清單'.
PARAMETERS p_carr  TYPE scarr-carrid OBLIGATORY.     " 必填
PARAMETERS p_desc  AS CHECKBOX.                      " 核取方塊
PARAMETERS p_file  TYPE string LOWER CASE.           " 保留小寫
```

| 附加選項 | 效果 |
|---|---|
| `DEFAULT 值` | 預設值 |
| `OBLIGATORY` | 必填，空白不能執行 |
| `AS CHECKBOX` | 勾選 = `'X'`、未勾 = 空白 |
| `LOWER CASE` | 不自動轉大寫（檔名必加） |
| `RADIOBUTTON GROUP g` | 單選鈕（同 GROUP 互斥） |

---

## 單選鈕與判斷

```abap
* 單選鈕：輸出方式擇一
PARAMETERS: p_list AS CHECKBOX,                " checkbox 可複選
            p_alv  RADIOBUTTON GROUP g1 DEFAULT 'X',
            p_txt  RADIOBUTTON GROUP g1.

IF p_desc = 'X'.       " checkbox / radiobutton 都判斷 'X'
  SORT gt_students BY score DESCENDING.
ENDIF.
```

---

## 3. SELECT-OPTIONS：範圍條件

「85 到 100」「A 開頭」「這三個代碼」「排除某段」——一行搞定：

```abap
DATA gv_score TYPE i.                 " 需要一個參考欄位決定型別
SELECT-OPTIONS s_score FOR gv_score.
```

- 畫面自動出現「低值～高值」兩欄與多重選擇按鈕
- `FOR` 後面必須是**已宣告的資料物件**，不能直接寫型別

---

## 背後是一張 range 內表

`s_score` 其實是內表，每列四個欄位——理解它就理解一切：

| 欄位 | 意義 | 常見值 |
|---|---|---|
| SIGN | 包含/排除 | `I`（include）／`E`（exclude） |
| OPTION | 比較方式 | `EQ`、`BT` 區間、`CP` 樣式、`GE`/`LE`、`NE` |
| LOW | 低值（或單值） | |
| HIGH | 高值（BT 才用） | |

使用者輸入「85 ~ 100」→ 塞一列 `I / BT / 85 / 100`

```abap
DATA gs_score LIKE LINE OF s_score.
INITIALIZATION.
  gs_score-sign = 'I'. gs_score-option = 'BT'.
  gs_score-low  = 0.   gs_score-high   = 100.
  APPEND gs_score TO s_score.        " 程式給預設範圍
```

---

## 4. IN：套用 range 條件

三個場景通用：

```abap
* 1) SELECT 的 WHERE
SELECT * FROM sflight INTO TABLE gt_flights
  WHERE carrid IN s_carr.

* 2) LOOP 的 WHERE
LOOP AT gt_students INTO gs_student WHERE score IN s_score.

* 3) IF
IF gs_student-score IN s_score.
```

> **關鍵行為**：range 表是**空的**時，`IN` 對所有值都成立
> ＝不過濾。「不填就是查全部」是 SELECT-OPTIONS 的預設哲學

---

## 5. 畫面排版：BLOCK 與標題

```abap
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
  PARAMETERS p_title TYPE c LENGTH 20.
  SELECT-OPTIONS s_score FOR gv_score.
  PARAMETERS p_desc AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  t_b1 = '查詢條件'.        " 框標題在 INITIALIZATION 給值
```

- `t_xx` 由系統自動宣告，INITIALIZATION 裡賦值（事件見講義 10）
- 欄位左邊的說明文字正式做法是 **Selection Texts**
  （SE38 → Goto → Text Elements，支援多語言——講義 22）

---

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| SELECT-OPTIONS「欄位未定義」 | `FOR` 的參考變數沒先 DATA |
| 欄位名報錯 | 超過 8 字元 |
| 輸入的小寫全變大寫 | 沒加 `LOWER CASE` |
| checkbox 判斷 `= 'x'` 不成立 | 勾選值是大寫 `'X'` |
| 沒輸入條件卻查到全部 | 空 range = 全部成立，是規格不是 bug |
| 想改 s_score 某列 | 它就是內表，APPEND/DELETE/LOOP 都適用 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex07**：

建 BLOCK 畫面（標題參數、成績範圍、排序 checkbox）

用 `IN` 過濾學生名單並處理「查無資料」訊息
