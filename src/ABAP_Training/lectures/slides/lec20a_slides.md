---
<!-- _class: lead -->
<!-- _paginate: false -->

# 講義 20
# Control Break 群組小計

ABAP 基礎教育訓練（授課順序：接在講義 11 之後）

對應練習 ex20｜答案程式 `ZR_TR20_CONTROL_BREAK`

---

<!-- _class: lead -->
<!-- _paginate: false -->

# 講義 20a
# SQL 聚合與子查詢

ABAP 基礎教育訓練（授課順序：接在講義 20 之後）

對應練習 ex20a｜答案程式 `ZR_TR20A_SQL_AGG`

---

## 本講重點

- 只要小計時，別把全部明細撈回內表
- 聚合函數：`COUNT( * )`／`SUM`／`AVG`／`MAX`／`MIN`
- `GROUP BY` 與 `HAVING`
- `SELECT DISTINCT`
- 子查詢：`IN`／`EXISTS`／`NOT EXISTS`
- 資料庫算 vs 內表算怎麼選

> 全程傳統寫法：先宣告結構與內表，`INTO CORRESPONDING FIELDS OF TABLE`

---

## 1. 為什麼要在資料庫算

講義 20：撈**全部**明細 → 內表 → `AT END OF` + `SUM`

只要「每家公司一行」時，明細用不到：

```abap
SELECT carrid SUM( seatsocc ) AS seats
  INTO CORRESPONDING FIELDS OF TABLE gt_agg
  FROM sflight
  GROUP BY carrid.
```

資料庫彙總完，**只回傳結果**——每家公司一列

---

## 2. 聚合函數

| 函數 | 作用 |
|---|---|
| `COUNT( * )` | 列數 |
| `COUNT( DISTINCT 欄位 )` | 不重複值的個數 |
| `SUM( 欄位 )` | 加總（數值欄位） |
| `AVG( 欄位 )` | 平均 |
| `MAX`／`MIN( 欄位 )` | 最大／最小 |

- 每個聚合都要 `AS 別名`，別名要跟目的結構欄位**同名**
- `AVG` 目的欄位要能放小數：`TYPE i` → `422`，
  `TYPE p DECIMALS 2` → `422.94`

---

<!-- _class: compact -->

## 3. GROUP BY：分組

```abap
SELECT c~carrid c~carrname
       COUNT( * )        AS cnt
       SUM( f~seatsocc ) AS seats
       AVG( f~price )    AS avg_price
       MAX( f~price )    AS max_price
       MIN( f~price )    AS min_price
  INTO CORRESPONDING FIELDS OF TABLE gt_agg
  FROM sflight AS f
  INNER JOIN scarr AS c ON f~carrid = c~carrid
  GROUP BY c~carrid c~carrname
  ORDER BY c~carrid.
```

**規則**：SELECT 清單裡「不是聚合函數」的欄位，**都要列進 `GROUP BY`**

漏寫 → `The field "CONNID" from the SELECT list is missing in the GROUP BY clause`

---

## 4. HAVING：過濾分組後的結果

| 子句 | 過濾時間點 | 條件可用 |
|---|---|---|
| `WHERE` | 分組**之前**（明細列） | 一般欄位 |
| `HAVING` | 分組**之後**（整組） | 聚合函數 |

```abap
SELECT carrid COUNT( * ) AS cnt SUM( seatsocc ) AS seats
  INTO CORRESPONDING FIELDS OF TABLE gt_agg
  FROM sflight
  GROUP BY carrid
  HAVING SUM( seatsocc ) > 10000
  ORDER BY carrid.
```

能用 `WHERE` 擋掉的明細，盡量用 `WHERE`（分組前先縮小資料量）

---

## 5. DISTINCT：不重複值

```abap
SELECT DISTINCT airpfrom FROM spfli
  INTO TABLE gt_airp
  ORDER BY airpfrom.

SELECT COUNT( DISTINCT airpfrom ) FROM spfli INTO gv_dcnt.
```

SPFLI 26 條航線，只有 **8** 個不同的起飛機場

- `COUNT( * )` 數列數（26）
- `COUNT( DISTINCT ... )` 數不重複值（8）

---

<!-- _class: compact -->

## 6. 子查詢：SELECT 裡面再放 SELECT

```abap
* IN：有航線從 FRA 起飛的公司
SELECT carrid FROM scarr INTO TABLE gt_carr
  WHERE carrid IN ( SELECT carrid FROM spfli WHERE airpfrom = 'FRA' ).

* EXISTS：內層引用外層別名 c~carrid，逐列比對
SELECT carrid FROM scarr AS c INTO TABLE gt_carr
  WHERE EXISTS ( SELECT * FROM spfli
                   WHERE carrid = c~carrid AND airpfrom = 'FRA' ).

* NOT EXISTS：沒有任何航班的公司
SELECT carrid FROM scarr AS c INTO TABLE gt_carr
  WHERE NOT EXISTS ( SELECT * FROM sflight WHERE carrid = c~carrid ).
```

比 `FOR ALL ENTRIES`：**1 次往返、沒有空表陷阱**
但條件必須來自資料庫的表

---

## 7. 傳統寫法的邊界

聚合裡**不能放算式**：

```abap
SELECT carrid SUM( price * seatsocc ) AS revenue ...
```

```
The elements in the "SELECT LIST" list must be separated using commas.
```

算式屬於**新式 Open SQL**，整句要改新式寫法

- 傳統寫法：只聚合單一欄位，或撈明細用 Control Break
- 新式寫法留到講義 26

---

## 8. 資料庫算 vs 內表算

| 情境 | 建議 |
|---|---|
| 只要統計結果、不要明細 | `GROUP BY` + 聚合 |
| 要明細，又要每組小計／總計 | 撈明細 + Control Break（講義 20） |
| 算式很複雜（要用 ABAP 函數） | 撈回內表用 ABAP 算 |
| 只判斷「有沒有符合的資料」 | `EXISTS` 或 `SELECT SINGLE` |

**能讓資料庫算完再回傳的，就不要搬資料回來算**

---

## 9. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| `missing in the GROUP BY clause` | 一般欄位沒列進 `GROUP BY` |
| 聚合結果那欄是空的 | 沒用 `AS`，或別名跟結構欄位不同名 |
| `AVG` 結果沒有小數 | 目的欄位是 `i` |
| `WHERE SUM(...) > 100` 報錯 | 聚合條件要放 `HAVING` |
| **查不到資料，`sy-subrc` 卻是 0** | 沒有 `GROUP BY` 的聚合一定回一列 |

判斷有沒有資料 → 看 `COUNT( * )`，不要看 `sy-subrc`

---

<!-- _class: lead -->

# 課堂練習

完成 **ex20a**：

`GROUP BY` 統計各公司、`HAVING`、`DISTINCT`、
三種子查詢，最後跟內表累加交叉驗證
