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

# 講義 17
# 運算與流程控制

ABAP 基礎教育訓練

對應練習 ex17｜答案程式 `ZR_TR17_CONTROL_FLOW`

---

## 本講重點

- 算術運算子：`+ - * /`、整數商 `DIV`、餘數 `MOD`
- 條件分支：`IF / ELSEIF / ELSE`、`CASE / WHEN`
- 比較與邏輯運算：`AND / OR / NOT`、`IS INITIAL`、`BETWEEN`
- 迴圈：`DO n TIMES`、`DO`（無上限）、`WHILE`
- 迴圈控制三兄弟：`EXIT`、`CONTINUE`、`CHECK`

---

## 1. 算術運算

```abap
DATA: gv_a      TYPE i VALUE 17,
      gv_b      TYPE i VALUE 5,
      gv_result TYPE i,
      gv_avg    TYPE p LENGTH 8 DECIMALS 2.

gv_result = gv_a + gv_b.        " 22
gv_result = gv_a DIV gv_b.      " 3   整數商（無條件捨去）
gv_result = gv_a MOD gv_b.      " 2   餘數
gv_avg    = gv_a / gv_b.        " 3.40
gv_result = gv_a / gv_b.        " 3！目的地是整數 → 四捨五入
```

---

## 算術運算：兩個必知

**結果存哪裡決定精度**
`17 / 5` 存進 `i` 得 **3**（捨入）、存進 `p DECIMALS 2` 得 **3.40**
→ 金額計算的中間變數要用 `p`

**除以零會 dump**（COMPUTE_INT_ZERODIVIDE）
分母來自資料時，除之前必須檢查不為零
→ 講義 19 的除錯練習就埋了這顆地雷

> 舊程式的 `COMPUTE`、`ADD 1 TO gv_x.` 看得懂即可，新程式一律用 `=`

---

## 2. IF / ELSEIF / ELSE

```abap
IF gv_score >= 80.
  gv_grade = 'A'.
ELSEIF gv_score >= 60.
  gv_grade = 'B'.
ELSE.
  gv_grade = 'C'.
ENDIF.
```

- 由上往下判斷，**第一個成立的分支執行完就跳出**
  → 條件從嚴到寬排（先 `>= 80` 再 `>= 60`）
- `ELSEIF` / `ELSE` 可省略；`ENDIF` 不可省略

---

## 比較與邏輯運算子

| 符號寫法 | 舊字母寫法 | 意義 |
|---|---|---|
| `=` | `EQ` | 等於 |
| `<>` | `NE` | 不等於 |
| `>` / `>=` | `GT` / `GE` | 大於／大於等於 |
| `<` / `<=` | `LT` / `LE` | 小於／小於等於 |

組合條件用 `AND` / `OR` / `NOT`，括號讓優先順序一目了然：

```abap
IF ( gv_score >= 60 AND gv_score < 80 ) OR gv_makeup = 'X'.
```

---

## 常用述語（不是比較符號）

```abap
IF gv_name IS INITIAL.               " 是不是初始值（空白/0）
IF gv_score BETWEEN 60 AND 79.       " 區間（含兩端）
IF gv_grade CA 'AB'.                 " Contains Any：含 A 或 B
IF gv_carrid IN s_carrid.            " range 條件（講義 7）
```

> **ABAP 沒有布林型別**：旗標慣例用 `c LENGTH 1`
> `'X'` = 真、空白 = 假
> 判斷寫 `IF p_flag = 'X'.`，寫 `IF p_flag.` 是語法錯誤

---

## 3. CASE / WHEN：離散值分支

```abap
CASE gv_grade.
  WHEN 'A'.
    WRITE / '優等'.
  WHEN 'B' OR 'C'.            " 多值共用一個分支
    WRITE / '普通'.
  WHEN OTHERS.                " 其餘全部（建議永遠要寫）
    WRITE / '資料異常'.
ENDCASE.
```

- CASE 比的是**完全相等**；範圍條件（`>= 60`）只能用 IF
- 不寫 `WHEN OTHERS`：比不中就默默跳過，容易吞掉資料異常

---

<!-- _class: compact -->

## 4. 迴圈：DO 與 WHILE

```abap
* 固定次數：圈數在 sy-index（1 起算）
DO 5 TIMES.
  WRITE: / '第', sy-index, '圈'.
ENDDO.

* 不定次數：DO 沒有上限，必須自己 EXIT！
DO.
  gv_sum = gv_sum + sy-index.
  IF gv_sum > 100.
    EXIT.
  ENDIF.
ENDDO.

* 前測式：條件成立才進圈
WHILE gv_n * gv_n <= 200.
  gv_n = gv_n + 1.
ENDWHILE.
```

---

## 迴圈：兩個注意

**`sy-index` vs `sy-tabix`**
- `sy-index`：DO / WHILE 的圈數
- `sy-tabix`：內表 `LOOP AT` 的列號（講義 4）
- 巢狀時內層會蓋掉外層 → 需要就先存進自己的變數

**無上限 `DO` 一定要有出口**
手滑寫出無窮迴圈 → 程式最終以 **TIME_OUT** dump 收場

---

## 5. EXIT / CONTINUE / CHECK

LOOP、DO、WHILE 通用：

| 指令 | 效果 |
|---|---|
| `EXIT` | 跳出**整個迴圈** |
| `CONTINUE` | 跳過這一圈，直接進**下一圈** |
| `CHECK 條件` | 條件**不成立**＝CONTINUE（成立才往下） |

```abap
DO 10 TIMES.
  CHECK sy-index MOD 2 = 0.        " 奇數直接下一圈
  WRITE: / '偶數：', sy-index.
ENDDO.
```

---

## EXIT / CHECK 的陷阱

**`CHECK` 語感跟 IF 相反**
「通過檢查才繼續」——第一次讀舊程式很容易看反
（ZDQM 等舊程式裡極常見）

**`EXIT` 寫在迴圈外意義完全不同**
結束目前處理區塊，效果近似 RETURN
→ 迴圈外要提早結束，一律用 `RETURN`，語意單一

---

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 平均值永遠是整數 | 結果存進 `i` → 改用 `p DECIMALS` |
| dump COMPUTE_INT_ZERODIVIDE | 除法前沒檢查分母為零 |
| IF 條件對了卻進錯分支 | 條件從寬排到嚴，第一個成立就出去 |
| CASE 對範圍值不動作 | CASE 只比完全相等，範圍用 IF |
| 程式跑到 TIME_OUT | 無上限 DO/WHILE 沒有出口 |
| CHECK 邏輯寫反 | CHECK 是「成立才往下」 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex17**：

算術運算與 DIV/MOD
同一個等第判斷分別用 IF 與 CASE 寫
DO / WHILE 求和
CHECK 過濾偶數
