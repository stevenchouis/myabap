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

# 講義 20
# Control Break 群組小計

ABAP 基礎教育訓練（授課順序：接在講義 11 之後）

對應練習 ex20｜答案程式 `ZR_TR20_CONTROL_BREAK`

---

## 本講重點

- 群組報表的標準需求：明細 → 各組小計 → 總計
- Control Break：`AT NEW` / `AT END OF` / `AT FIRST` / `AT LAST`
- `SUM`：整組數值欄自動加總進 work area
- 兩條鐵則：**先 SORT**、**群組欄位放結構前面**
- AT 區塊內欄位被遮蔽成 `*` 的規則

---

## 1. 需求長相（傳統報表招牌格式）

```
=== 航班營收（依公司小計） ===
AA American Airlines
   0017 2026/01/03    380    159,494.31
   0017 2026/01/31    372    156,136.13
   小計                752    315,630.44
AZ Alitalia
   ...
   小計                ...
================================
總計                 5,204  2,381,904.99
```

土法煉鋼：自己記「上一筆的 carrid」逐筆比對
ABAP 內建了這個場景的語法——**Control Break**

---

<!-- _class: compact -->

## 2. 語法：LOOP 裡的 AT 區塊

```abap
SORT gt_rev BY carrid connid fldate.    " 鐵則一：先排序！

LOOP AT gt_rev INTO gs_rev.

  AT FIRST.                             " 第一筆之前：標題
    WRITE / '=== 航班營收（依公司小計） ==='.
  ENDAT.

  AT NEW carrid.                        " 每組第一筆之前：組頭
    WRITE: / gs_rev-carrid, gs_rev-carrname.
  ENDAT.

  WRITE: /5 gs_rev-connid, gs_rev-fldate,   " 明細行
            gs_rev-seatsocc, gs_rev-revenue.

  AT END OF carrid.                     " 每組最後一筆之後：小計
    SUM.                                " 數值欄加總進 gs_rev
    WRITE: /5 '小計', gs_rev-seatsocc, gs_rev-revenue.
    ULINE.
  ENDAT.

  AT LAST.                              " 最後一筆之後：總計
    SUM.
    WRITE: / '總計', gs_rev-seatsocc, gs_rev-revenue.
  ENDAT.

ENDLOOP.
```

---

## AT 陳述式總表／SUM

| 陳述式 | 觸發時機 | 用途 |
|---|---|---|
| `AT FIRST` | 迴圈第一筆之前，一次 | 報表標題 |
| `AT NEW 欄位` | 該欄位（含**左邊所有欄位**）變動的那筆之前 | 組頭 |
| `AT END OF 欄位` | 該組最後一筆之後 | **小計** |
| `AT LAST` | 迴圈最後一筆之後，一次 | **總計** |

**SUM**（只能寫在 AT 區塊內）：
把目前群組所有列的**數值欄**加總進 work area
→ 小計行直接 `WRITE gs_rev-revenue`，不用自己累加

> 注意：SUM 是「所有數值欄」一起總
> 不該加總的欄位（如**單價**）小計行不要印

---

## 3. 鐵則一：先 SORT

Control Break 只認「**相鄰列**」：

- 沒依群組欄位排序 → 同公司資料分散各處
- AT NEW / AT END OF 觸發好幾次、小計整組錯
- **而且不報錯**

`SORT` 的欄位順序要跟群組層次一致

---

## 鐵則二：群組欄位放結構最前面

`AT NEW f` 的比較規則：「`f` **加上它左邊所有欄位**」任一變動就觸發

```abap
TYPES: BEGIN OF ty_rev,
         carrid   TYPE sflight-carrid,     " 群組欄位放最前
         carrname TYPE scarr-carrname,     " 一對一，緊跟其後
         connid   TYPE sflight-connid,     " 明細鍵
         fldate   TYPE sflight-fldate,
         seatsocc TYPE sflight-seatsocc,   " 數值欄（要小計的）
         revenue  TYPE p LENGTH 12 DECIMALS 2,
       END OF ty_rev.
```

`carrid` 放中間 → 前面的欄位一變就誤觸發
**群組欄位排最前是保命慣例**

---

## 遮蔽規則：AT 區塊內右邊欄位變 `*`

進入 `AT NEW f` / `AT END OF f` 區塊時：
work area 中 `f` **右邊**的字元欄全被遮成 `*`、數值欄清空
（明細值沒有意義了，系統防止誤用）

組頭想同時印 `carrid` 與 `carrname`：

```abap
AT NEW carrname.       " 用右邊那欄當斷點，兩欄都看得到
  WRITE: / gs_rev-carrid, gs_rev-carrname.
ENDAT.
```

（carrname 與 carrid 一對一，觸發效果等同 AT NEW carrid）

> 報表上第一次出現 `*****`，幾乎都是這個規則造成的

---

## 4. 適用邊界

- Control Break 專屬 `LOOP AT ... INTO`
  → 搭配 `ASSIGNING` **不能用** AT 區塊
- 迴圈加 `WHERE` 或中途 DELETE，群組判斷可能失真
  → 要過濾就**先整理成乾淨的內表**再 LOOP
- 只要總計不要明細 → 直接 `SELECT SUM( ) GROUP BY`
  或 `COLLECT` 更省（課後自行延伸）

---

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 同一公司出現多次小計 | 沒先 SORT |
| 組頭/小計印出 `*****` | 遮蔽規則——改用右側欄位當斷點或別印 |
| 小計數字大得離譜 | SUM 總了不該總的欄位（單價）還印出來 |
| AT NEW 太常觸發 | 群組欄位左邊還有變動欄位——移到最前 |
| ASSIGNING 迴圈 AT 區塊報錯 | Control Break 只支援 INTO |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex20**：

SFLIGHT＋SCARR JOIN 出營收明細
依公司做組頭、小計，AT LAST 總計

實驗「不 SORT 會怎樣」與遮蔽規則
