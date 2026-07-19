# 練習 26：新式語法總覽（字串模板／New Open SQL／Functional Operator）

> 授課順序：進階選修，全課程最後一題，接在練習 23 之後。講義見 [lec26](lectures/lec26_modern_syntax.md)。

## 學習目標

- 會用字串模板 `|...|` 取代 `CONCATENATE`，並用 `WIDTH`／`ALIGN`／`PAD`／`CASE` 格式化輸出
- 會用 `SELECT ... INTO TABLE @DATA(...)` 行內宣告，並在 `SELECT` 清單裡用 `CASE ... END AS` 做分類
- 會用 `COND`／`SWITCH` 取代 `IF/ELSEIF`／`CASE` 陳述式賦值
- 會用 `VALUE` 建構內表初始資料、`REDUCE` 做累加、`FILTER` 篩選子集合（含次要鍵）

## 事前準備

建立程式 `ZR_TR26_<你的姓名縮寫>`，套件 `$TMP`。系統需有航班測試資料（`SCARR`/`SFLIGHT`，先跑一次 `SAPBC_DATA_GENERATOR` 若尚未產生過）。

## 題目需求

1. **字串模板**：宣告姓 `'王'`、名 `'小明'`（`c LENGTH 10`），用字串模板串成全名輸出（不可用 `CONCATENATE`）；再宣告 `gv_score TYPE i VALUE 85`，用字串模板搭配 `WIDTH = 5 ALIGN = RIGHT PAD = '0'` 輸出補零結果
2. **New Open SQL**：用一句 `SELECT` 從 `SCARR` JOIN `SFLIGHT`（取 `carrid`／`carrname`／`connid`／`price`），用 `@DATA(...)` 行內宣告內表，`SELECT` 清單內用 `CASE WHEN ... END AS price_level` 把票價分成 `LOW`（< 500）／`MID`（< 1500）／`HIGH`（其餘）三級，`ORDER BY carrid, connid`，`UP TO 10 ROWS`；`LOOP` 輸出每一筆的四個欄位＋分級
3. **COND**：沿用需求 1 的 `gv_score`，用 `COND` 依區間換算等第（`>=90` A、`>=80` B、`>=60` C、其餘 D）並輸出
4. **SWITCH**：宣告 `gv_carrid TYPE s_carr_id VALUE 'LH'`，用 `SWITCH` 對應到航空公司全名（`LH`→`Lufthansa`、`AA`→`American Airlines`、`UA`→`United Airlines`、其餘→`Unknown`）並輸出
5. **VALUE**：宣告一個 `SORTED TABLE`（Local Type，含 `matnr`/`qty` 兩欄，主鍵 `matnr` 唯一排序、另建一個以 `qty` 為排序鍵的非唯一次要鍵），用 `VALUE` 一次建好 3 筆測試資料（`M001/10`、`M002/25`、`M003/5`），`LOOP` 輸出
6. **REDUCE**：對需求 5 的內表用 `REDUCE` 算出 `qty` 總和並輸出
7. **FILTER**：對需求 5 的內表用 `FILTER` 搭配次要鍵，篩出 `qty >= 10` 的項目並 `LOOP` 輸出

## 預期輸出（範例，資料筆數依系統實際測試資料而定）

```
===== 1. 字串模板 =====
全名：王小明
成績（靠右對齊補零）：00085
===== 2. New Open SQL =====
LH  Lufthansa             0400        350.00 LOW
LH  Lufthansa             0402       1200.00 MID
...（依系統資料，最多 10 筆，依 carrid/connid 排序）
===== 3. COND =====
成績等級：B
===== 4. SWITCH =====
航空公司：Lufthansa
===== 5. VALUE =====
M001         10
M002         25
M003          5
===== 6. REDUCE =====
總數量：40
===== 7. FILTER =====
M001         10
M002         25
```

（New Open SQL 那段的實際航班筆數與票價，依系統當時的示範資料而定，只要分級邏輯正確、`ORDER BY` 排序正確即可，不要求數字跟範例一模一樣。）

## 思考題

1. 需求 2 如果把 `SELECT` 欄位清單改回舊式空白分隔（`SELECT scarr~carrid scarr~carrname ...`），`@DATA(...)` 還需不需要加 `@`？如果句子裡還有 `WHERE @lv_x = ...` 這種宿主變數呢？
2. 需求 7 如果把 `FILTER` 條件換成 `WHERE matnr = 'M002'`，還需要 `USING KEY by_qty` 嗎？為什麼？
3. 需求 3／4 如果把 `COND`/`SWITCH` 的 `ELSE` 拿掉、剛好沒有任何分支命中，程式會發生什麼事？跟傳統 `CASE ... WHEN OTHERS` 少寫的後果一樣嗎？

## 答案

見 `zr_tr26_modern_syntax.prog.abap`（SAP 端程式 `ZR_TR26_MODERN_SYNTAX`）。
