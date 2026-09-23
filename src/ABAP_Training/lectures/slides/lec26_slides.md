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

# 講義 26
# 新式語法總覽

字串模板／New Open SQL／Functional Operator

ABAP 基礎教育訓練（進階選修，全課程最後一講，接在講義 23 之後）

對應練習 ex26｜答案程式 `ZR_TR26_MODERN_SYNTAX`

---

## 本講重點

- 行內宣告：`DATA(...)`／`FIELD-SYMBOL(...)`（先備觀念）
- 字串模板：取代 `CONCATENATE`，附格式化選項
- New Open SQL：宿主變數（Host Variable）與 `@` 跳脫、`@DATA(...)`、`SELECT` 內的 `CASE`
- Functional Operator 五件套：`COND`／`SWITCH`／`VALUE`／`REDUCE`／`FILTER`

> 這些是 7.40 之後（S/4HANA 常態）的寫法
> 前 25 講刻意用傳統語法打底——**兩種寫法都要看得懂**

---

<!-- _class: compact -->

## 0. 先備觀念：行內宣告（Inline Declaration）

前 25 講：**先宣告、再使用**　→　7.40 起：**第一次使用處直接宣告**

```abap
* 傳統：先宣告，再使用
DATA gs_student TYPE ty_student.
LOOP AT gt_students INTO gs_student.
FIELD-SYMBOLS <ls> TYPE ty_student.
LOOP AT gt_students ASSIGNING <ls>.

* 行內宣告：宣告與使用合在同一行
DATA(gv_len) = strlen( 'ABAP' ).             " 型別由右邊自動推導
LOOP AT gt_students INTO DATA(gs_student).
LOOP AT gt_students ASSIGNING FIELD-SYMBOL(<ls>).
```

| 形式 | 用在哪 |
|---|---|
| `DATA(名稱)` | 賦值、`LOOP INTO`、`READ TABLE INTO`、方法接收端 |
| `FIELD-SYMBOL(<名稱>)` | `LOOP／READ TABLE ASSIGNING`、`ASSIGN ... TO` |
| `@DATA(名稱)` | `SELECT ... INTO`（第 2 節） |

---

## 0.1 行內宣告的四個注意點

1. **型別由右邊決定**：`DATA(lv_n) = 0.` → `i`；`DATA(lv_s) = 'abc'.` → **`c LENGTH 3`**（之後塞長字串被截斷）；要 string 用反引號
2. **作用範圍是整個程式單元**：兩個 `LOOP` 都 `INTO DATA(gv_x)` → 編譯錯誤 `already declared`
3. **不是每個位置都行**：`CALL FUNCTION ... IMPORTING x = DATA(y)` 不合法
4. **只是少寫一行宣告**，效果與傳統寫法完全相同

---

## 1. 字串模板

```abap
WRITE: / |全名：{ gv_last }{ gv_first }|.

WRITE: / |成績：{ gv_score WIDTH = 5 ALIGN = RIGHT PAD = '0' }|.
* 00085

WRITE: / |代碼：{ gv_code CASE = UPPER }|.
* LH
```

- 語法 `|文字{ 運算式 }文字|`
- `{ }` 內放單一運算式，**不能**是多參數的 `EXPORTING`／`IMPORTING` 方法呼叫

---

## 1.1 字串模板的格式化選項

| 選項 | 作用 |
|---|---|
| `WIDTH = n` | 輸出寬度 |
| `ALIGN = LEFT／RIGHT／CENTER` | 對齊方式 |
| `PAD = 'x'` | 補齊字元（預設補空白） |
| `CASE = UPPER／LOWER` | 轉大小寫 |
| `DECIMALS = n` | 數值小數位數 |

對照講義 18：`CONCATENATE` 要先想暫存變數
字串模板文字與變數交錯寫同一行，組訊息文字尤其好讀

---

<!-- _class: compact -->

## 2. 宿主變數（Host Variable）是什麼

一句 SELECT 裡有兩種名稱：**資料庫欄位**（`carrid`）與 **ABAP 變數**（`gv_carrid`）
從 ABAP（宿主語言）傳進 SQL 的變數 → **宿主變數（Host Variable）**

**舊式 Open SQL 靠位置猜**：`WHERE carrid = gv_carrid`
位置單純，猜得準——但遇到這兩種情況猜不出來：

- 算式／`CASE`／子查詢把資料庫欄位跟變數混在同一運算式
- 行內宣告 `@DATA(gt_x)`：變數在陳述式當下才「憑空」誕生

**新式解法：宿主變數一律加 `@` 前綴**
有 `@` = ABAP 變數；沒 `@` = 資料庫欄位，語意完全消歧義

---

<!-- _class: compact -->

## 2.1 New Open SQL：行內宣告與 CASE 運算式

```abap
SELECT scarr~carrid, scarr~carrname, sflight~connid, sflight~price,
       CASE WHEN sflight~price < 500  THEN 'LOW'
            WHEN sflight~price < 1500 THEN 'MID'
            ELSE 'HIGH'
       END AS price_level
  FROM scarr
  INNER JOIN sflight ON sflight~carrid = scarr~carrid
  ORDER BY scarr~carrid, sflight~connid
  INTO TABLE @DATA(gt_flight)
  UP TO 10 ROWS.
```

- `@DATA(gt_flight)`：不用先宣告，型別由 SELECT 清單推導；`@` 標記這是要行內宣告的宿主變數
- `CASE ... END AS alias`：在資料庫層算好分類
- 位置：`ORDER BY` 在 `INTO` 之前、`UP TO n ROWS` 在 `INTO` 之後
- **規則**：欄位清單用逗號分隔 → 句中所有宿主變數都要加 `@`（混用舊式 `INTO CORRESPONDING FIELDS OF TABLE` 也一樣）

---

## 2.2 聚合函數內放算式

聚合函數裡可以直接放算式（呼應講義 20a）：

```abap
SELECT carrid,
       SUM( price * seatsocc ) AS revenue
  FROM sflight
  GROUP BY carrid
  ORDER BY carrid
  INTO TABLE @DATA(gt_rev).
```

傳統寫法報「must be separated using commas」
新式寫法在資料庫內直接算出各公司營收

---

## 3. COND：依條件回傳一個值

```abap
DATA(gv_level) = COND #( WHEN gv_score >= 90 THEN 'A'
                          WHEN gv_score >= 80 THEN 'B'
                          WHEN gv_score >= 60 THEN 'C'
                          ELSE 'D' ).
```

- 取代 `IF ... ELSEIF ... ENDIF` 賦值
- `#` 由賦值目標推導型別，也可明寫 `COND string( ... )`
- 沒有 `WHEN` 命中又沒寫 `ELSE`：**不報錯**，結果是初始值

---

## 4. SWITCH：依單一值對應

```abap
DATA(gv_carrname) = SWITCH #( gv_carrid
                       WHEN 'LH' THEN 'Lufthansa'
                       WHEN 'AA' THEN 'American Airlines'
                       WHEN 'UA' THEN 'United Airlines'
                       ELSE 'Unknown' ).
```

| | 用途 |
|---|---|
| `COND` | 每個分支各自寫條件（範圍、多欄位、AND／OR） |
| `SWITCH` | 針對**同一個值**比對多個候選值 |

---

<!-- _class: compact -->

## 5. VALUE：建構結構／內表

```abap
TYPES: BEGIN OF ty_item,
         matnr TYPE c LENGTH 10,
         qty   TYPE i,
       END OF ty_item,
       tt_item TYPE SORTED TABLE OF ty_item
                WITH UNIQUE KEY matnr
                WITH NON-UNIQUE SORTED KEY by_qty COMPONENTS qty.

DATA(gt_item) = VALUE tt_item( ( matnr = 'M001' qty = 10 )
                                ( matnr = 'M002' qty = 25 )
                                ( matnr = 'M003' qty = 5 ) ).
```

- 取代逐筆 `APPEND VALUE #( ... ) TO gt_item.`
- `by_qty` 是**次要索引**，給第 7 節 `FILTER` 用
- `SORTED TABLE`：給的資料順序要符合主鍵排序，否則執行期出錯

---

## 6. REDUCE：迴圈累加成單一運算式

```abap
DATA(gv_total_qty) = REDUCE i( INIT sum = 0
                                 FOR wa IN gt_item
                                 NEXT sum = sum + wa-qty ).
```

- 取代 `LOOP` + 累加變數
- `INIT` 初始值、`FOR ... IN itab` 相當 `LOOP AT`、`NEXT` 每輪更新
- 適用：累加、串接字串、找最大值

邏輯複雜（要中途 `EXIT`、多層判斷）時，傳統 `LOOP` 更好讀
**不要為了用而用**

---

## 7. FILTER：篩選子集合

```abap
DATA(gt_item_big) =
  FILTER #( gt_item USING KEY by_qty WHERE qty >= 10 ).
```

- 取代 `LOOP ... WHERE` + `APPEND`
- **關鍵限制**：`WHERE` 條件欄位必須是**表格鍵值**的一部分
  （主鍵或 `USING KEY` 指定的次要鍵）
- `qty` 不是主鍵 `matnr` → 第 5 節才多宣告 `by_qty`

忘記這條規則，編譯階段報錯——這個運算子最容易踩的坑

---

<!-- _class: compact -->

## 8. 舊寫法 vs 新寫法

| 需求 | 傳統寫法 | 新式寫法 |
|---|---|---|
| 依條件賦值 | `IF ... ELSEIF` | `COND #( WHEN ... THEN ... )` |
| 依值對應賦值 | `CASE v. WHEN ...` | `SWITCH #( v WHEN ... THEN ... )` |
| 建內表初始資料 | 逐筆 `APPEND` | `VALUE tt( ( ... ) ( ... ) )` |
| 迴圈累加 | `LOOP` + 累加變數 | `REDUCE type( INIT ... FOR ... NEXT ... )` |
| 篩選子集合 | `LOOP ... WHERE` + `APPEND` | `FILTER #( itab USING KEY k WHERE ... )` |
| 撈資料到內表 | `DATA` 宣告 + `SELECT ... INTO TABLE itab` | `SELECT ... INTO TABLE @DATA(itab)` |
| 字串拼接 | `CONCATENATE a b INTO c` | 字串模板 `{ a }{ b }` |

---

<!-- _class: compact -->

## 9. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 「must be escaped using @」 | 欄位清單用新式寫法，全句宿主變數都要 `@` |
| `FILTER` 編譯報錯 | `WHERE` 欄位不是主鍵或指定的次要鍵 |
| `COND`／`SWITCH` 結果是空值／0 | 沒寫 `ELSE`，未命中回傳初始值，不報錯 |
| 字串模板 `{ }` 內方法呼叫錯誤 | 只能單一運算式或 `RETURNING` 方法 |
| `VALUE` 建 `SORTED TABLE` dump | 資料順序不符主鍵排序 |
| `ORDER BY`／`UP TO` 位置錯誤 | `ORDER BY` 在 `INTO` 前，`UP TO` 在 `INTO` 後 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex26**：

把講義 18 字串、11 JOIN、17 等第判斷、20 累加，
各自改寫成新式寫法，
並示範 `FILTER` 搭配次要鍵
