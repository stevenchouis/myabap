# 講義 5：Internal Table 進階

> 對應練習：[ex05](../ex05_itab_advanced.md)｜答案程式：`ZR_TR05_ITAB_ADVANCED`

## 本講重點

- `SORT`：單欄／多欄、升冪／降冪
- `MODIFY`：改表中既有的列（搭配 INDEX / TRANSPORTING）
- `DELETE`：依 INDEX、依 WHERE、去重複（ADJACENT DUPLICATES）
- `INSERT ... INDEX`：插在指定位置
- `DESCRIBE TABLE` / `lines( )` 取筆數
- 這些指令與 `sy-subrc` / `sy-tabix` 的互動

## 1. SORT：排序

```abap
SORT gt_students BY score DESCENDING.            " 成績由高到低
SORT gt_students BY score.                       " 不寫就是 ASCENDING
SORT gt_students BY grade ASCENDING
                    score DESCENDING.            " 多欄：先等第、同等第再比成績
```

- 不加 `BY` 時依表格定義的 KEY 排序——**建議永遠明寫 BY**，意圖清楚。
- 排序會改變 INDEX：排序前記下的「第 n 筆」排序後就不算數了。
- 同值想保持原本相對順序，加 `STABLE`：`SORT gt BY score DESCENDING STABLE.`

排序後可以用二分搜尋加速 READ（大表差很多）：

```abap
SORT gt_students BY id.
READ TABLE gt_students INTO gs_student WITH KEY id = 'S0002' BINARY SEARCH.
```

> BINARY SEARCH 的前提是**已依同一組欄位排序**，沒排序就用會拿到錯誤結果（不是報錯！）。

## 2. MODIFY：修改表中的列

MODIFY 把 work area 的內容**寫回**表中指定的列：

```abap
* 指定第幾筆
READ TABLE gt_students INTO gs_student INDEX 2.
gs_student-score = 99.
MODIFY gt_students FROM gs_student INDEX 2.

* LOOP 中可省略 INDEX（自動用目前這一筆，即 sy-tabix）
LOOP AT gt_students INTO gs_student.
  gs_student-score = gs_student-score + 5.       " 全班加 5 分
  MODIFY gt_students FROM gs_student.
ENDLOOP.
```

只想更新部分欄位時用 `TRANSPORTING`，其他欄位不動：

```abap
MODIFY gt_students FROM gs_student INDEX 2 TRANSPORTING score.
```

> 最常見的坑：LOOP INTO 改了 work area 卻**忘了 MODIFY**——迴圈結束表格完全沒變，程式也不報錯。講義 16 的 `LOOP ... ASSIGNING` 就是為了根治這個問題。

## 3. DELETE：刪除列

```abap
DELETE gt_students INDEX 3.                      " 刪第 3 筆
DELETE gt_students WHERE score < 60.             " 刪所有不及格（可能多筆）
```

- `sy-subrc`：有刪到 0，沒刪到 4——照鐵律檢查。
- 去除重複（**先排序**再用，只比相鄰列）：

```abap
SORT gt_students BY id.
DELETE ADJACENT DUPLICATES FROM gt_students COMPARING id.
```

不加 COMPARING 則比整列。忘記先 SORT 是經典錯誤：不相鄰的重複不會被刪。

> 注意：LOOP 進行中 DELETE 同一張表雖然合法（刪目前列可用 `DELETE gt_students.` 搭配隱含 index），但容易寫出難懂的邏輯——初學建議「先 LOOP 蒐集、迴圈外再刪」或直接用 `DELETE ... WHERE`。

## 4. INSERT：插在指定位置

APPEND 只能加在表尾；要插在中間用 INSERT：

```abap
gs_student-id = 'S0009'. gs_student-name = '插班生'. gs_student-score = 70.
INSERT gs_student INTO gt_students INDEX 2.      " 插成第 2 筆，原本的往後推
```

省略 INDEX 的 `INSERT ... INTO TABLE gt.` 用於 SORTED/HASHED 表（依 KEY 找位置），STANDARD 表日常還是 APPEND 為主。

## 5. 取得筆數

```abap
DATA gv_lines TYPE i.
DESCRIBE TABLE gt_students LINES gv_lines.       " 傳統寫法
WRITE: / '共', gv_lines, '筆'.

gv_lines = lines( gt_students ).                 " 內建函數寫法（較新、較簡潔）
```

兩種都要看得懂；判斷「表是不是空的」還可以用 `IF gt_students IS INITIAL.`。

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
  WRITE: / sy-tabix, gs_student-id, gs_student-name, gs_student-score.
ENDLOOP.
WRITE: / '倖存', lines( gt_students ), '人'.
```

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| LOOP 裡改分數，結束後表沒變 | 忘了 MODIFY（INTO 是複本） |
| BINARY SEARCH 找不到明明存在的資料 | 沒先依查詢欄位 SORT |
| ADJACENT DUPLICATES 沒刪乾淨 | 沒先 SORT，重複列不相鄰 |
| 排序後用舊 INDEX 讀到別筆 | SORT 之後列的位置全變了 |
| DELETE WHERE 之後筆數不如預期 | 條件寫反；用 sy-subrc 與 lines( ) 驗證 |

## 8. 課堂練習

完成 [ex05](../ex05_itab_advanced.md)：對學生表做 SORT、MODIFY 加分、DELETE 篩選與去重複，觀察每步的筆數與 sy-subrc。

> 接下來（依授課順序）先上 **lec19 除錯 Debugger**（拿目前的技能實戰抓 bug），再上 **lec16 Field-Symbol**：解決本講「INTO 複本 + MODIFY」的效能與遺漏問題。
