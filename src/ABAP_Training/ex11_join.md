# 練習 11：多表 JOIN

## 學習目標

- 會寫 `INNER JOIN`：兩表都有的資料才出現
- 會寫 `LEFT OUTER JOIN`：左表全保留，右表無對應時欄位為空——並理解兩者差異
- 會用表別名（`AS a` / `a~carrid`）與 `ON` 關聯條件
- 會用 `INTO CORRESPONDING FIELDS OF TABLE`（依欄位名對應）
- 會用 `TABLES` 宣告 + `SELECT-OPTIONS ... FOR <db表-欄位>`（自動帶 F4 與欄位說明）

## 資料模型（航班訓練模型）

- `SCARR`：航空公司（1）
- `SPFLI`：航線（多）——`CARRID` 關聯回 SCARR

一家公司有多條航線，這是「主檔 : 明細 = 1 : N」的典型關聯。

## 事前準備

建立程式 `ZR_TR11_<你的姓名縮寫>`，套件 `$TMP`；確認 SPFLI/SCARR 有資料。

## 題目需求

1. `TABLES spfli.` + `SELECT-OPTIONS s_carrid FOR spfli-carrid.`——跟 ex07 的 FOR 自訂變數比較：畫面上的欄位說明和 F4 從哪來？
2. 定義自訂結構（欄位名跟 DB 欄位一致）：carrid/connid/cityfrom/cityto + **carrname（來自 SCARR）**
3. `INNER JOIN`：SPFLI join SCARR，取出航線清單含公司名稱，輸出筆數與內容
4. `LEFT OUTER JOIN`：反過來以 SCARR 為左表 join SPFLI，輸出總筆數，並列出 `connid IS INITIAL` 的公司（＝沒有航線的公司）
5. 比較兩次的筆數，說出差異的原因

## 預期輸出（範例，依系統資料而定）

```
=== INNER JOIN：航線清單（含公司名稱），筆數         18 ===
AA 0017 American Airlines  NEW YORK     -> SAN FRANCISCO
...
=== LEFT OUTER JOIN：總筆數         21 ===
（比 INNER 多出來的，就是沒有航線的公司）
SQ Singapore Airlines （無航線）
...
```

## 思考題

1. 把 `INTO CORRESPONDING FIELDS OF TABLE` 改成 `INTO TABLE`，會發生什麼事？（提示：欄位「順序與型別」必須完全對齊 vs「名稱」對應）
2. 目標程式 `Z_INVENTORY_COST_REPORT` 的 `get_data` 用了 1 個 INNER + 3 個 LEFT JOIN——去讀讀看，說出 MAKT 為什麼用 LEFT JOIN 而不是 INNER？（提示：料號可能沒維護某語言的說明）

## 答案

見 `zr_tr11_join.prog.abap`（SAP 端程式 `ZR_TR11_JOIN`）。
