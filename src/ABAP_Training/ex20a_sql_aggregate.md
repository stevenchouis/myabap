# 練習 20a：SQL 聚合與子查詢

> 授課順序：接在練習 20（Control Break）之後、練習 12（列印排版）之前。講義見 [lec20a](lectures/lec20a_sql_aggregate.md)。

## 學習目標

- 會用聚合函數（`COUNT`／`SUM`／`AVG`／`MAX`／`MIN`）搭配 `GROUP BY` 讓資料庫做彙總
- 分清楚 `WHERE`（分組前過濾）與 `HAVING`（分組後過濾）
- 會用 `SELECT DISTINCT` 取不重複值
- 會用子查詢（`IN`／`EXISTS`／`NOT EXISTS`）回答「有沒有對應資料」類的問題
- 知道「沒有 `GROUP BY` 的聚合，沒資料時 `sy-subrc` 也是 0」這個陷阱

## 事前準備

建立程式 `ZR_TR20A_<你的姓名縮寫>`，套件 `$TMP`。需要航班測試資料（`SAPBC_DATA_GENERATOR`，練習 6 應已跑過）。

全程使用**傳統寫法**：先宣告結構與內表，`SELECT` 用 `INTO CORRESPONDING FIELDS OF TABLE`，不使用 `@DATA(...)` 行內宣告（那是練習 26 的內容）。

## 題目需求

1. **各公司統計（`GROUP BY`）**：定義結果結構 `carrid`、`carrname`、`cnt`（航班數，`i`）、`seats`（已訂座位，`i`）、`avg_price`（平均票價，`p LENGTH 12 DECIMALS 2`）、`max_price`、`min_price`。SFLIGHT 與 SCARR `INNER JOIN`，依公司分組，一次 SELECT 算出每家公司一列，依 `carrid` 排序輸出。
2. **`HAVING`**：只列出已訂座位總數超過 10000 的公司。
3. **`DISTINCT`**：從 SPFLI 列出所有不重複的起飛機場（`airpfrom`），並印出航線總數與不重複機場數各是多少。
4. **子查詢**（三個小題，各印出公司代碼）：
   1. 有航線從 `FRA` 起飛的公司——用 `IN ( SELECT ... )`
   2. 同一題，改用 `EXISTS`，確認結果與 4.1 相同
   3. 沒有任何航班（SFLIGHT 無資料）的公司——用 `NOT EXISTS`
5. **交叉驗證**：把 SFLIGHT 全部明細撈進內表，用 `LOOP ... WHERE carrid = ...` 自己累加每家公司的座位數，跟第 1 題資料庫算出來的 `seats` 逐家比對，印出差異（應該全是 0）；另外用不分組的 `SELECT SUM( seatsocc )` 算全部座位數，跟各組加總比對。
6. **實驗一（`GROUP BY` 規則）**：在第 1 題的 SELECT 清單裡多加一個 `connid`，但不寫進 `GROUP BY`，觀察編譯錯誤訊息，記下後把它拿掉。
7. **實驗二（聚合裡放算式）**：嘗試把 `SUM( seatsocc )` 改成 `SUM( price * seatsocc )`（練習 20 的營收算法），觀察錯誤訊息，記下後改回。
8. **實驗三（空結果陷阱）**：對不存在的公司代碼 `ZZ` 執行 `SELECT COUNT( * ) SUM( seatsocc ) ... WHERE carrid = 'ZZ'`，印出 `sy-subrc`、`COUNT`、`SUM`。

## 預期輸出（範例，數字依測試資料而異）

```
=== 1. 各航空公司統計（GROUP BY） ===
ID  Name                  Flights   Seats       Avg price     Max price     Min price
----------------------------------------------------------------------------------------------------
AA  American Airlines          25       5,712        422.94        422.94        422.94
AZ  Alitalia                   52      12,361        814.75      1,030.00        185.00
...

=== 2. 已訂座位總數超過 10000 的公司（HAVING） ===
AZ          52      12,361
LH          76      17,114
...

=== 3. 有航班起飛的機場（DISTINCT） ===
FCO FRA JFK NRT SFO SIN TXL TYO
航線總數             26  ／ 不重複的起飛機場數                    8

=== 6. 查一個不存在的公司（ZZ） ===
sy-subrc =     0  ／ COUNT =           0  ／ SUM =           0
```

## 思考題

1. 第 1 題裡 `carrname` 為什麼也要寫進 `GROUP BY`？如果只寫 `GROUP BY c~carrid` 會怎樣？
2. `HAVING SUM( seatsocc ) > 10000` 能不能改寫成 `WHERE`？為什麼？
3. 第 4.1 題的 `IN ( SELECT ... )` 跟講義 11 的 `FOR ALL ENTRIES` 相比，有什麼優點？（提示：往返次數、空表陷阱。）
4. 練習 20 用 Control Break 做小計，這題用 `GROUP BY`——什麼情境該選哪一個？
5. 第 1 題把 `avg_price` 宣告成 `TYPE i` 會怎樣？

## 答案

見 `zr_tr20a_sql_agg.prog.abap`（SAP 端程式 `ZR_TR20A_SQL_AGG`）。
