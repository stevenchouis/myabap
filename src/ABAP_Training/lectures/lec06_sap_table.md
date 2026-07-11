# 講義 6：讀 SAP Table——航班模型與 SELECT

> 對應練習：[ex06](../ex06_sap_table.md)｜答案程式：`ZR_TR06_SAP_TABLE`

## 本講重點

- 資料字典（DDIC）與透明表：SE11 看定義、SE16N 看資料
- SAP 練習用航班資料模型：SCARR / SPFLI / SFLIGHT
- `SELECT ... INTO TABLE`、`SELECT SINGLE`、`WHERE`、`UP TO n ROWS`
- `sy-subrc` 與 `sy-dbcnt`
- 為什麼不用 `SELECT *`、為什麼避免 `SELECT ... ENDSELECT`

## 1. 資料字典與透明表

SAP 的資料表定義集中在**資料字典（Data Dictionary，DDIC）**，用 SE11 檢視：欄位、型別（Data Element）、鍵、外鍵關係都在這裡。透明表（transparent table）就是資料庫裡真實存在的表。

| 交易代碼 | 用途 |
|---|---|
| SE11 | 看表的**定義**（欄位、型別、鍵） |
| SE16N | 看表的**資料**（開發/測試機查數據） |

宣告變數時直接參考 DDIC 型別，是實務最標準的寫法：

```abap
DATA gv_carrid TYPE scarr-carrid.               " 跟表欄位同型別
DATA gs_carrier TYPE scarr.                     " 整列結構
DATA gt_carriers TYPE STANDARD TABLE OF scarr.  " 內表：一列 = 一筆 SCARR
```

好處：表定義改了，程式的變數自動一致；而且帶著欄位的語意（長度、轉換規則、檢核表）。這個「引用型別而非寫死」的觀念正式名稱是 **Global Type**，講義 25 會用一個真實的 SAP 升級案例把它講深。

## 2. 航班資料模型（訓練標準教材）

SAP 內建一組練習用資料表，本課程到期末都用它：

| 表 | 內容 | 鍵欄位 |
|---|---|---|
| SCARR | 航空公司主檔 | CARRID |
| SPFLI | 航線（起訖機場、時刻） | CARRID, CONNID |
| SFLIGHT | 航班（日期、票價、座位） | CARRID, CONNID, FLDATE |

三張表用 CARRID（+CONNID）串起來：一家公司有多條航線，一條航線有多個日期的航班。**沒有資料時**先執行報表 `SAPBC_DATA_GENERATOR`（SE38 跑一次）產生測試資料。

另外每張 SAP 表第一欄幾乎都是 `MANDT`（client）：Open SQL 會**自動**只撈當前 client 的資料，WHERE 不用（也不要）自己寫 MANDT。

## 3. SELECT 語法全景

```abap
SELECT 欄位清單
  FROM 資料表
  INTO 目的地
  [UP TO n ROWS]
  WHERE 條件.
```

### 3.1 撈多筆進內表（最常用）

```abap
DATA gt_carriers TYPE STANDARD TABLE OF scarr.

SELECT * FROM scarr
  INTO TABLE gt_carriers.

IF sy-subrc <> 0.
  WRITE / '查無資料'.
ENDIF.
WRITE: / '共撈到', sy-dbcnt, '筆'.     " sy-dbcnt：這次 SELECT 的筆數
```

### 3.2 指定欄位（實務建議）

只撈需要的欄位，目的結構的欄位**順序與型別要對得上**：

```abap
TYPES: BEGIN OF ty_carr,
         carrid   TYPE scarr-carrid,
         carrname TYPE scarr-carrname,
       END OF ty_carr.
DATA gt_carr TYPE STANDARD TABLE OF ty_carr.

SELECT carrid carrname FROM scarr
  INTO TABLE gt_carr.
```

> `SELECT *` 在練習可以，正式程式盡量列欄位：少傳輸、少記憶體，而且表加欄位時不會莫名多撈。欄位對不齊的問題之後用 `INTO CORRESPONDING FIELDS OF`（講義 11）解。

### 3.3 SELECT SINGLE：讀一筆

已知完整鍵、只要一筆時用：

```abap
DATA gs_carrier TYPE scarr.
SELECT SINGLE * FROM scarr
  INTO gs_carrier
  WHERE carrid = 'AA'.
IF sy-subrc = 0.
  WRITE: / gs_carrier-carrid, gs_carrier-carrname.
ENDIF.
```

### 3.4 WHERE 與 UP TO n ROWS

```abap
SELECT * FROM sflight
  INTO TABLE gt_flights
  UP TO 50 ROWS                        " 最多 50 筆（試跑大表的保命符）
  WHERE carrid = 'AA'
    AND fldate >= '20260101'
    AND seatsocc > 0.
```

WHERE 可用 `=`、`<>`、`>`、`>=`、`<`、`<=`、`BETWEEN`、`LIKE`（`%` 萬用字元）、`IN`（講義 7 搭配 SELECT-OPTIONS）。字元欄位比對**區分大小寫**，資料庫存大寫就要用大寫比。

## 4. SELECT ... ENDSELECT（看得懂即可）

舊程式常見的逐筆迴圈式撈取：

```abap
SELECT * FROM scarr INTO gs_carrier.
  WRITE: / gs_carrier-carrid, gs_carrier-carrname.
ENDSELECT.
```

每一圈跟資料庫要一筆，效能差；維護時看得懂就好，**新程式一律 INTO TABLE 一次撈回**，再用 LOOP 處理。同理，**絕對不要**在 LOOP 裡面對每筆再下 SELECT（講義 11 用 JOIN 解決這個需求）。

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 練習系統撈不到航班資料 | 沒跑過 `SAPBC_DATA_GENERATOR` |
| WHERE 比對不到明明存在的值 | 大小寫不符（資料庫存大寫）或欄位有前導零（`n` 型別） |
| 指定欄位 SELECT 後資料錯位 | 目的結構欄位順序/型別跟欄位清單不一致 |
| SELECT SINGLE 撈到「不知道哪一筆」 | WHERE 沒給完整鍵——條件不唯一時它任取一筆 |
| 程式在大表上跑不完 | 忘了 WHERE / UP TO n ROWS，全表掃描 |
| 自己 WHERE mandt = ... | 不需要，Open SQL 自動處理 client |

## 6. 課堂練習

完成 [ex06](../ex06_sap_table.md)：確認測試資料、SELECT SCARR 全表與指定欄位、SELECT SINGLE 讀單筆、用 WHERE 與 UP TO n ROWS 撈 SFLIGHT，全程檢查 sy-subrc / sy-dbcnt。
