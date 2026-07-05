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

# 講義 5
# Internal Table 進階

ABAP 基礎教育訓練

對應練習 ex05｜答案程式 `ZR_TR05_ITAB_ADVANCED`

---

## 本講重點

- `SORT`：單欄／多欄、升冪／降冪
- `MODIFY`：改表中既有的列（INDEX / TRANSPORTING）
- `DELETE`：依 INDEX、依 WHERE、去重複
- `INSERT ... INDEX`：插在指定位置
- `DESCRIBE TABLE` / `lines( )` 取筆數
- 這些指令與 `sy-subrc` / `sy-tabix` 的互動

---

## 1. SORT：排序

```abap
SORT gt_students BY score DESCENDING.   " 成績由高到低
SORT gt_students BY score.              " 不寫就是 ASCENDING
SORT gt_students BY grade ASCENDING
                    score DESCENDING.   " 多欄排序
```

- 不加 `BY` 依表格 KEY 排序——**建議永遠明寫 BY**
- 排序會改變 INDEX：排序前記的「第 n 筆」就不算數了
- 同值保持原順序 → 加 `STABLE`

---

## SORT + BINARY SEARCH

排序後可用二分搜尋加速 READ（大表差很多）：

```abap
SORT gt_students BY id.
READ TABLE gt_students INTO gs_student
     WITH KEY id = 'S0002' BINARY SEARCH.
```

> **前提：已依同一組欄位排序**
> 沒排序就用 → 拿到**錯誤結果**（不是報錯！）

---

## 2. MODIFY：修改表中的列

把 work area 的內容**寫回**表中指定的列：

```abap
* 指定第幾筆
READ TABLE gt_students INTO gs_student INDEX 2.
gs_student-score = 99.
MODIFY gt_students FROM gs_student INDEX 2.

* LOOP 中可省略 INDEX（自動用 sy-tabix 那筆）
LOOP AT gt_students INTO gs_student.
  gs_student-score = gs_student-score + 5.
  MODIFY gt_students FROM gs_student.
ENDLOOP.

* 只更新部分欄位：
MODIFY gt_students FROM gs_student INDEX 2 TRANSPORTING score.
```

> 最常見的坑：LOOP INTO 改了 work area 卻**忘了 MODIFY**
> 表格完全沒變、程式也不報錯——講義 16 的 ASSIGNING 根治它

---

## 3. DELETE：刪除列

```abap
DELETE gt_students INDEX 3.              " 刪第 3 筆
DELETE gt_students WHERE score < 60.     " 刪所有不及格
```

`sy-subrc`：有刪到 0、沒刪到 4——照鐵律檢查

**去除重複（先排序再用，只比相鄰列）：**

```abap
SORT gt_students BY id.
DELETE ADJACENT DUPLICATES FROM gt_students COMPARING id.
```

- 不加 COMPARING → 比整列
- **忘記先 SORT 是經典錯誤**：不相鄰的重複不會被刪

> LOOP 中刪同一張表容易寫出難懂邏輯
> 初學建議：先 LOOP 蒐集、迴圈外再刪，或直接 `DELETE ... WHERE`

---

## 4. INSERT／5. 取得筆數

```abap
* APPEND 只能加表尾；插中間用 INSERT：
INSERT gs_student INTO gt_students INDEX 2.   " 原本的往後推
```

```abap
* 筆數兩種寫法都要看得懂：
DESCRIBE TABLE gt_students LINES gv_lines.    " 傳統寫法
gv_lines = lines( gt_students ).              " 內建函數（較新）

* 判斷空表：
IF gt_students IS INITIAL.
```

---

## 6. 綜合範例

```abap
* 需求：去重複 → 全班加 5 分 → 刪不及格 → 依成績排名輸出
SORT gt_students BY id.
DELETE ADJACENT DUPLICATES FROM gt_students COMPARING id.

LOOP AT gt_students INTO gs_student.
  gs_student-score = gs_student-score + 5.
  MODIFY gt_students FROM gs_student TRANSPORTING score.
ENDLOOP.

DELETE gt_students WHERE score < 60.

SORT gt_students BY score DESCENDING.
LOOP AT gt_students INTO gs_student.
  WRITE: / sy-tabix, gs_student-id, gs_student-score.
ENDLOOP.
WRITE: / '倖存', lines( gt_students ), '人'.
```

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| LOOP 裡改分數，結束後表沒變 | 忘了 MODIFY（INTO 是複本） |
| BINARY SEARCH 找不到存在的資料 | 沒先依查詢欄位 SORT |
| ADJACENT DUPLICATES 沒刪乾淨 | 沒先 SORT，重複列不相鄰 |
| 排序後用舊 INDEX 讀到別筆 | SORT 之後位置全變了 |
| DELETE WHERE 筆數不如預期 | 條件寫反；用 sy-subrc 與 lines( ) 驗證 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex05**：

SORT、MODIFY 加分、DELETE 篩選與去重複
觀察每步的筆數與 sy-subrc

**接下來**：lec19 除錯實戰 → lec16 Field-Symbol
（根治「INTO 複本 + MODIFY」問題）
