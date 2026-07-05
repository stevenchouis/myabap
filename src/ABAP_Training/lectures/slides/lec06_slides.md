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

# 講義 6
# 讀 SAP Table——航班模型與 SELECT

ABAP 基礎教育訓練

對應練習 ex06｜答案程式 `ZR_TR06_SAP_TABLE`

---

## 本講重點

- 資料字典（DDIC）與透明表：SE11 看定義、SE16N 看資料
- SAP 練習用航班資料模型：SCARR / SPFLI / SFLIGHT
- `SELECT ... INTO TABLE`、`SELECT SINGLE`、`WHERE`、`UP TO n ROWS`
- `sy-subrc` 與 `sy-dbcnt`
- 為什麼不用 `SELECT *`、為什麼避免 `SELECT ... ENDSELECT`

---

## 1. 資料字典與透明表

表定義集中在 **DDIC**；透明表 = 資料庫裡真實存在的表

| T-code | 用途 |
|---|---|
| SE11 | 看表的**定義**（欄位、型別、鍵） |
| SE16N | 看表的**資料**（查數據） |

宣告變數直接參考 DDIC 型別——實務最標準寫法：

```abap
DATA gv_carrid   TYPE scarr-carrid.               " 跟表欄位同型別
DATA gs_carrier  TYPE scarr.                      " 整列結構
DATA gt_carriers TYPE STANDARD TABLE OF scarr.    " 內表
```

好處：表定義改了，變數自動一致；帶著欄位語意

---

## 2. 航班資料模型（訓練標準教材）

| 表 | 內容 | 鍵欄位 |
|---|---|---|
| SCARR | 航空公司主檔 | CARRID |
| SPFLI | 航線（起訖機場、時刻） | CARRID, CONNID |
| SFLIGHT | 航班（日期、票價、座位） | CARRID, CONNID, FLDATE |

一家公司 → 多條航線 → 多個日期的航班

- **沒有資料時**：先跑報表 `SAPBC_DATA_GENERATOR`
- 每張表第一欄幾乎都是 `MANDT`：
  Open SQL **自動**只撈當前 client，WHERE 不用（不要）自己寫

---

## 3. SELECT：撈多筆進內表（最常用）

```abap
DATA gt_carriers TYPE STANDARD TABLE OF scarr.

SELECT * FROM scarr
  INTO TABLE gt_carriers.

IF sy-subrc <> 0.
  WRITE / '查無資料'.
ENDIF.
WRITE: / '共撈到', sy-dbcnt, '筆'.    " sy-dbcnt：這次的筆數
```

---

## 指定欄位（實務建議）

只撈需要的欄位，目的結構的**順序與型別要對得上**：

```abap
TYPES: BEGIN OF ty_carr,
         carrid   TYPE scarr-carrid,
         carrname TYPE scarr-carrname,
       END OF ty_carr.
DATA gt_carr TYPE STANDARD TABLE OF ty_carr.

SELECT carrid carrname FROM scarr
  INTO TABLE gt_carr.
```

> `SELECT *` 練習可以，正式程式盡量列欄位：
> 少傳輸、少記憶體、表加欄位時不會莫名多撈
> 欄位對不齊 → 用 `INTO CORRESPONDING FIELDS OF`（講義 11）

---

## SELECT SINGLE 與 WHERE

```abap
* 已知完整鍵、只要一筆：
SELECT SINGLE * FROM scarr
  INTO gs_carrier
  WHERE carrid = 'AA'.
IF sy-subrc = 0. ... ENDIF.

* WHERE 與 UP TO n ROWS：
SELECT * FROM sflight
  INTO TABLE gt_flights
  UP TO 50 ROWS                 " 試跑大表的保命符
  WHERE carrid = 'AA'
    AND fldate >= '20260101'
    AND seatsocc > 0.
```

WHERE 可用 `= <> > >= < <=`、`BETWEEN`、`LIKE`、`IN`（講義 7）
字元比對**區分大小寫**——資料庫存大寫就用大寫比

---

## 4. SELECT ... ENDSELECT（看得懂即可）

舊程式常見的逐筆撈取：

```abap
SELECT * FROM scarr INTO gs_carrier.
  WRITE: / gs_carrier-carrid, gs_carrier-carrname.
ENDSELECT.
```

- 每一圈跟資料庫要一筆，**效能差**
- 維護看得懂就好，新程式一律 `INTO TABLE` 一次撈回
- **絕對不要**在 LOOP 裡對每筆再下 SELECT
  （這個需求用 JOIN 解決——講義 11）

---

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 撈不到航班資料 | 沒跑過 `SAPBC_DATA_GENERATOR` |
| WHERE 比對不到存在的值 | 大小寫不符、或欄位有前導零 |
| 指定欄位 SELECT 後資料錯位 | 目的結構欄位順序/型別不一致 |
| SELECT SINGLE 撈到不知哪筆 | WHERE 沒給完整鍵，它任取一筆 |
| 大表上跑不完 | 忘了 WHERE / UP TO n ROWS |
| 自己 WHERE mandt = ... | 不需要，Open SQL 自動處理 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex06**：

確認測試資料、SELECT SCARR 全表與指定欄位、
SELECT SINGLE 讀單筆、
WHERE + UP TO n ROWS 撈 SFLIGHT

全程檢查 sy-subrc / sy-dbcnt
