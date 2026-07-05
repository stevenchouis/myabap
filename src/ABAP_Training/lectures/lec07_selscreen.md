# 講義 7：選擇畫面——PARAMETERS / SELECT-OPTIONS / IN

> 對應練習：[ex07](../ex07_selscreen.md)｜答案程式：`ZR_TR07_SELSCREEN`

## 本講重點

- 選擇畫面（selection screen）是什麼、何時產生
- `PARAMETERS`：單值輸入與各種附加選項
- `SELECT-OPTIONS`：範圍條件，理解背後的 range 表（SIGN/OPTION/LOW/HIGH）
- `IN` 運算子：range 條件用在 SELECT、LOOP、IF
- `SELECTION-SCREEN BLOCK` 畫面排版與標題

## 1. 選擇畫面是什麼

在宣告區寫下 `PARAMETERS` 或 `SELECT-OPTIONS`，系統就**自動**產生一個輸入畫面（standard selection screen），執行程式時先顯示，使用者填完按執行（F8）才進主邏輯。不用自己畫畫面——這是傳統報表開發效率高的原因之一。

命名限制：畫面欄位名**最長 8 個字元**。慣例：`p_` 開頭是 PARAMETERS、`s_` 開頭是 SELECT-OPTIONS。

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
| `OBLIGATORY` | 必填，空白不能執行（欄位出現勾勾） |
| `AS CHECKBOX` | 核取方塊；勾選時值為 `'X'`，未勾為空白 |
| `LOWER CASE` | 不自動轉大寫（檔名、密碼類必加，否則輸入被轉成大寫） |
| `RADIOBUTTON GROUP g` | 單選鈕（同 GROUP 互斥，擇一為 'X'） |

```abap
* 單選鈕：輸出方式擇一
PARAMETERS: p_list AS CHECKBOX,                      " 對照：checkbox 可複選
            p_alv  RADIOBUTTON GROUP g1 DEFAULT 'X',
            p_txt  RADIOBUTTON GROUP g1.

IF p_desc = 'X'.       " checkbox / radiobutton 都是判斷 'X'
  SORT gt_students BY score DESCENDING.
ENDIF.
```

## 3. SELECT-OPTIONS：範圍條件

單值不夠用：使用者常要「85 到 100」「A 開頭」「這三個代碼」「排除某段」。SELECT-OPTIONS 一行搞定，畫面自動出現「低值～高值」兩欄與多重選擇按鈕：

```abap
DATA gv_score TYPE i.                 " 需要一個「參考欄位」決定型別
SELECT-OPTIONS s_score FOR gv_score.
```

`FOR` 後面必須是**已宣告的資料物件**（變數或 `TABLES` 表工作區的欄位），不能直接寫型別。

### 3.1 背後是一張 range 內表

`s_score` 其實是一張內表，每列四個欄位——理解這個結構，就理解了 SELECT-OPTIONS 的一切：

| 欄位 | 意義 | 常見值 |
|---|---|---|
| SIGN | 包含或排除 | `I`（include）／`E`（exclude） |
| OPTION | 比較方式 | `EQ` 等於、`BT` 區間、`CP` 樣式（含 `*`）、`GE`/`LE`/`GT`/`LT`、`NE` |
| LOW | 低值（或單值） | |
| HIGH | 高值（BT 才用） | |

使用者在畫面輸入「85 ~ 100」，系統就往 `s_score` 塞一列 `I / BT / 85 / 100`；多重選擇裡的每一行輸入都是一列。程式也可以自己塞（常用於 INITIALIZATION 給預設範圍）：

```abap
DATA gs_score LIKE LINE OF s_score.     " 跟 range 表一列同型別

INITIALIZATION.
  gs_score-sign   = 'I'.
  gs_score-option = 'BT'.
  gs_score-low    = 0.
  gs_score-high   = 100.
  APPEND gs_score TO s_score.
```

## 4. IN：套用 range 條件

`IN` 判斷「值是否符合 range 表的所有條件」，三個場景通用：

```abap
* 1) SELECT 的 WHERE
SELECT * FROM sflight INTO TABLE gt_flights
  WHERE carrid IN s_carr.

* 2) LOOP 的 WHERE
LOOP AT gt_students INTO gs_student WHERE score IN s_score.
  WRITE: / gs_student-id, gs_student-name, gs_student-score.
ENDLOOP.

* 3) IF
IF gs_student-score IN s_score.
  ...
ENDIF.
```

**關鍵行為**：range 表是**空的**（使用者什麼都沒填）時，`IN` 對所有值都成立＝不過濾。所以「不填就是查全部」不用另外寫 IF 判斷，這是 SELECT-OPTIONS 的預設哲學。

## 5. 畫面排版：BLOCK 與標題

```abap
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
  PARAMETERS p_title TYPE c LENGTH 20 DEFAULT '學生成績清單'.
  SELECT-OPTIONS s_score FOR gv_score.
  PARAMETERS p_desc AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  t_b1 = '查詢條件'.        " 框標題在 INITIALIZATION 給值
```

- `BLOCK ... WITH FRAME` 把相關欄位框在一起，`TITLE t_xx` 是框標題變數（系統自動宣告，INITIALIZATION 事件裡賦值——事件詳見講義 10）。
- 欄位左邊的說明文字正式做法是 **Selection Texts**（SE38 → Goto → Text Elements → Selection Texts），支援多語言；課堂練習先用預設顯示變數名即可。

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| SELECT-OPTIONS 報「欄位未定義」 | `FOR` 後面的參考變數沒先 DATA 出來 |
| 欄位名報錯 | 超過 8 字元 |
| 輸入的小寫字母全變大寫 | 沒加 `LOWER CASE` |
| checkbox 判斷 `= 'x'` 不成立 | 勾選值是大寫 `'X'` |
| 沒輸入條件卻以為會查不到資料 | 空 range 表 = 全部成立，是規格不是 bug |
| 想在程式裡直接改 s_score 某列 | 記得它就是內表，APPEND/DELETE/LOOP 都適用 |

## 7. 課堂練習

完成 [ex07](../ex07_selscreen.md)：建 BLOCK 畫面（標題參數、成績範圍、排序 checkbox），用 `IN` 過濾學生名單並處理「查無資料」訊息。
