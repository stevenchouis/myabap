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

# 講義 11
# 多表 JOIN 與 CORRESPONDING FIELDS

ABAP 基礎教育訓練

對應練習 ex11｜答案程式 `ZR_TR11_JOIN`

---

## 本講重點

- 為什麼要 JOIN：報表幾乎都要跨表撈欄位
- `INNER JOIN` 與 `LEFT OUTER JOIN` 的差別
- 語法細節：別名 `AS`、欄位前綴 `~`、`ON` 條件
- `INTO CORRESPONDING FIELDS OF TABLE`：依欄位名對應
- `FOR ALL ENTRIES` 簡介與著名的空表陷阱
- 效能觀念：JOIN vs 迴圈中 SELECT

---

## 1. 為什麼要 JOIN

需求：「列出每個航班，**含航空公司名稱**」
航班在 SFLIGHT、公司名稱在 SCARR——單表拿不齊

```abap
* 反面教材：N 筆航班 = N 次資料庫往返，大表直接跑不動
LOOP AT gt_flights INTO gs_flight.
  SELECT SINGLE carrname FROM scarr INTO gv_name
    WHERE carrid = gs_flight-carrid.
ENDLOOP.
```

JOIN 讓資料庫**一次**把兩張表串好回傳

---

## 2. INNER JOIN

```abap
TYPES: BEGIN OF ty_flight,
         carrid   TYPE sflight-carrid,
         connid   TYPE sflight-connid,
         fldate   TYPE sflight-fldate,
         carrname TYPE scarr-carrname,   " 來自另一張表
       END OF ty_flight.

SELECT f~carrid f~connid f~fldate c~carrname
  INTO CORRESPONDING FIELDS OF TABLE gt_flights
  FROM sflight AS f
  INNER JOIN scarr AS c ON f~carrid = c~carrid
  WHERE f~fldate >= '20260101'.
```

- `AS f`：表別名；之後每個欄位標來源 `f~carrid`（**`~` 不是 `-`**）
- `ON` 是**串表條件**、`WHERE` 是**過濾條件**——別混
- INNER 語意：**兩邊都對得上才輸出**，對不上整筆消失

---

## 3. LEFT OUTER JOIN

「左表全留，右表對不上就給初始值」：

```abap
SELECT c~carrid c~carrname f~connid f~fldate
  INTO CORRESPONDING FIELDS OF TABLE gt_result
  FROM scarr AS c
  LEFT OUTER JOIN sflight AS f ON c~carrid = f~carrid.
```

結果：**每家**公司都在；沒航班的公司 `connid`/`fldate` 是初始值

**選擇原則**：「沒對到的要不要出現在報表上？」
要 → LEFT OUTER；不要 → INNER

> 限制：LEFT OUTER 的 WHERE 對**右表**欄位下條件
> 會把 NULL 列濾掉、效果變回 INNER——右表條件放 ON

---

## 4. INTO 的兩種對應方式

| 寫法 | 對應規則 | 風險 |
|---|---|---|
| `INTO TABLE gt` | 依**順序** | 順序錯 = 資料錯位（不報錯） |
| `INTO CORRESPONDING FIELDS OF TABLE gt` | 依**欄位名** | 欄名拼錯 = 默默留空 |

JOIN 的結果結構欄位東拼西湊
→ **建議一律用 CORRESPONDING FIELDS**

- 順序自由、可讀性高
- 代價：欄位名要跟 SELECT 清單一致
- 別名欄位：`SELECT f~price AS ticket_price ...`

---

## 5. FOR ALL ENTRIES（維護會遇到）

先撈第一張表，再用內表內容當第二張表的條件：

```abap
IF gt_flights IS NOT INITIAL.        " 這個 IF 是保命符！
  SELECT carrid carrname FROM scarr
    INTO TABLE gt_carriers
    FOR ALL ENTRIES IN gt_flights
    WHERE carrid = gt_flights-carrid.
ENDIF.
```

- **空表陷阱**：驅動內表是空的 → WHERE 整個失效＝**全表撈回**
  `IS NOT INITIAL` 檢查**不是可選的**
- 結果自動去除完全重複的列
- 新程式優先 JOIN；FOR ALL ENTRIES 用在 JOIN 不便的場景

---

## 6. 效能觀念小結

| 寫法 | 資料庫往返 | 評價 |
|---|---|---|
| LOOP 內 SELECT SINGLE | N 次 | **禁止**（測試看不出慢，上線就爆） |
| SELECT + FOR ALL ENTRIES | 2 次 | 可用，記得空表防呆 |
| INNER / LEFT OUTER JOIN | 1 次 | **首選** |

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 欄位前綴報語法錯誤 | 要用 `f~carrid`（`~`），不是 `-` |
| 某些資料整筆不見 | INNER 對不上就丟——該用 LEFT OUTER？ |
| CORRESPONDING 後某欄全空 | 欄位名跟 SELECT（或 AS 別名）不一致 |
| LEFT OUTER 行為像 INNER | 右表條件要放 ON，不放 WHERE |
| FOR ALL ENTRIES 慢到懷疑人生 | 驅動內表是空的——補 IS NOT INITIAL |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex11**：

INNER JOIN 撈「航班＋公司名稱」、
LEFT OUTER JOIN 觀察沒航班的公司、
比較兩種 INTO 的行為差異
