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
- **Global Type**：型別從哪裡來、為什麼業務欄位要引用 DDIC 型別
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
這個「引用型別而非寫死」的觀念叫 **Global Type**

---

## 1.1 型別從哪裡來

| 層級 | 寫法 | 定義在哪 |
|---|---|---|
| 內建型別 | `TYPE c LENGTH 3` | 語言本身，長度**寫死** |
| Local Type | `TYPES ty_x ...`（講義 3、4） | 這支程式裡，別的程式要再抄一份 |
| **Global Type** | `TYPE scarr-carrid`／`TYPE scarr`／`TYPE s_carr_id` | **資料字典**，全系統共用同一份 |

Global Type 包含：Data Element、表格欄位、Structure／整列、Table Type

---

## 1.2 為什麼引用，不要寫死

物料號碼 `MATNR`：舊版 18 碼 → S/4HANA **40 碼**

```abap
DATA lv_matnr TYPE mara-matnr.    " 升級後自動變 40 碼，程式不用改
DATA lv_matnr TYPE c LENGTH 18.   " 升級後資料默默截斷，也不報錯
```

**判斷準則**

- 純區域暫存（計數器、旗標）→ 內建型別
- 代表業務資料（公司、物料、票價、日期）→ **引用 Global Type**
- 只有本程式用的欄位組合 → Local Type；多支程式共用 → DDIC Structure／Table Type（講義 25）

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

<!-- _class: compact -->

## S/4HANA 的資料表變化：舊表的四種狀態

| 狀態 | 例子（本系統實測） | 程式該怎麼做 |
|---|---|---|
| 舊表名變成 CDS View | `BSIS`／`BSAS`、`GLT0`、`FAGLFLEXT`、`COSP` | 讀取可用；新程式讀新表 |
| 透明表掛 Proxy | `MKPF`／`MSEG`（→`MATDOC`）、`MARD`、`FAGLFLEXA`、`COEP` | 只讀不寫；新程式讀新表 |
| 表還在、不再寫資料 | `VBUK`／`VBUP`、`KONV`（**0 筆**） | 讀了是空的，一定要改讀新位置 |
| 沒變 | `BKPF`、`BSEG`、`VBAK`／`VBAP`、`KNA1` | 照舊 |

- 新表：`ACDOCA`（總帳行項目）、`MATDOC`（物料憑證）、`PRCD_ELEMENTS`（定價條件）、`BUT000`（業務夥伴）
- Proxy＝替代物件：`SELECT` 舊表時系統自動改讀一個 CDS View，資料從新表即時算出

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

<!-- _class: compact -->

## ORDER BY：讓資料庫排好序再回傳

```abap
SELECT * FROM sflight
  INTO TABLE gt_flights
  UP TO 3 ROWS
  WHERE carrid = 'LH'
  ORDER BY fldate DESCENDING.      " 傳統寫法：ORDER BY 接在 WHERE 之後
```

- **不寫 `ORDER BY`，回傳順序不確定**
- `ORDER BY carrid price DESCENDING`：多欄空格分隔，方向各欄自己管；`ORDER BY PRIMARY KEY`
- 先排序再取 `UP TO n ROWS` → 前 n 名；沒 `ORDER BY` 只是任意 n 筆
- `SELECT SINGLE` 不能加 `ORDER BY` → 用 `SELECT ... ENDSELECT` 讀到第一筆就 `EXIT`

---

<!-- _class: compact -->

## 新式寫法對照：New Open SQL

```abap
* 傳統
SELECT * FROM scarr INTO TABLE gt_carriers
  UP TO 10 ROWS WHERE currcode = gv_curr ORDER BY carrid.

* 新式
SELECT * FROM scarr
  WHERE currcode = @gv_curr
  ORDER BY carrid
  INTO TABLE @DATA(gt_carriers)
  UP TO 10 ROWS.
```

1. **程式變數（宿主變數）加 `@`**：`@gv_curr`、`IN @s_carrid`；沒 `@` 的是資料庫欄位
2. 欄位清單、`ORDER BY` 用**逗號**分隔
3. **`INTO` 放最後**，`UP TO n ROWS` 接在 `INTO` 之後
4. `@DATA(gt)` 行內宣告，型別由 SELECT 清單推導

**一句裡不能混用**新舊特徵，否則編譯錯誤

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
