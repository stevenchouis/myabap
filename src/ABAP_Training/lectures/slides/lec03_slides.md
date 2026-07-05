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

# 講義 3
# Local Type 與 Structure

ABAP 基礎教育訓練

對應練習 ex03｜答案程式 `ZR_TR03_STRUCTURES`

---

## 本講重點

- 為什麼需要結構：一筆資料有多個欄位
- `TYPES BEGIN OF ... END OF` 定義自訂結構型別
- 「型別（TYPES）」與「變數（DATA）」的分工：模具 vs 產品
- 欄位存取 `-`、結構整體賦值、`CLEAR`
- `MOVE-CORRESPONDING` 同名欄位搬值

---

## 1. 為什麼需要結構

三個散裝變數：「屬於同一筆」的關係只存在你腦中

```abap
* 沒有結構：三個散裝變數
DATA: gv_id    TYPE c LENGTH 5,
      gv_name  TYPE string,
      gv_score TYPE i.

* 有結構：一筆資料一個變數
DATA gs_student TYPE ty_student.
```

> 結構是下一講 internal table 的基礎：
> **結構是一列，internal table 是很多列**

---

## 2. TYPES：定義自訂結構型別

```abap
TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,     " 學號
         name  TYPE string,         " 姓名
         score TYPE i,              " 成績
       END OF ty_student.
```

- `BEGIN OF` 開始、`END OF` 結束，中間每行一個欄位
- 慣例：結構型別 `ty_` 開頭、表格型別 `tt_` 開頭
- 只在本程式看得到 = **Local Type**
  多支程式共用 → 改定義在 SE11（本課程先用 Local）

---

## 3. TYPES vs DATA：模具與產品

| | TYPES | DATA |
|---|---|---|
| 產生什麼 | 型別（**不佔記憶體**） | 資料物件（真的存值） |
| 比喻 | 餅乾模具 | 壓出來的餅乾 |
| 可以賦值嗎 | 不可以 | 可以 |

```abap
TYPES ty_amount TYPE p LENGTH 8 DECIMALS 2.   " 模具：定義一次
DATA: gv_price TYPE ty_amount,                " 產品：想壓幾個壓幾個
      gv_cost  TYPE ty_amount.
```

> 初學常犯：對 `ty_student-id` 賦值 → 編譯錯誤
> 型別不能存資料，要先 `DATA` 出變數

---

## 4. 欄位存取：連字號 `-`

```abap
DATA gs_student TYPE ty_student.

gs_student-id    = 'S0001'.
gs_student-name  = '王小明'.
gs_student-score = 85.

WRITE: / gs_student-id, gs_student-name, gs_student-score.
```

`結構-欄位` 是 ABAP 最高頻寫法之一

> 所以**變數命名不要含連字號**，避免與欄位存取混淆

---

## 5. 結構的整體操作

```abap
* 同型別：直接賦值 = 整筆複製
gs_b = gs_a.

* 整筆歸零：所有欄位回初始值
CLEAR gs_a.
```

> 習慣：重複用同一個結構填資料時，**先 CLEAR**
> 避免上一筆殘留值混進來——實務很常見的 bug 來源

**不同型別**的結構直接 `=` 會照「位置」硬轉、結果錯亂
→ 要用 MOVE-CORRESPONDING（下一頁）

---

## MOVE-CORRESPONDING：同名欄位對搬

```abap
TYPES: BEGIN OF ty_student_lite,
         id   TYPE c LENGTH 5,
         name TYPE string,
       END OF ty_student_lite.

DATA: gs_full TYPE ty_student,
      gs_lite TYPE ty_student_lite.

MOVE-CORRESPONDING gs_full TO gs_lite.   " 只搬同名欄位 id、name
```

規則：**欄位名相同就搬**（逐欄轉換）
- 目的端沒有的欄位 → 丟掉
- 目的端多的欄位 → 不動
- 欄位名拼錯 → **默默不搬、不報錯**，要自己核對

---

## 6. 巢狀結構（先看得懂）

結構的欄位也可以是另一個結構，用兩層 `-` 存取：

```abap
TYPES: BEGIN OF ty_address,
         city   TYPE string,
         street TYPE string,
       END OF ty_address.
TYPES: BEGIN OF ty_person,
         name    TYPE string,
         address TYPE ty_address,     " 欄位本身是結構
       END OF ty_person.

DATA gs_person TYPE ty_person.
gs_person-address-city = '台北'.
```

SAP 標準結構常有巢狀，先能讀懂即可

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 對 `ty_xxx` 賦值編譯錯誤 | TYPES 是型別不是變數 |
| `END OF` 名稱報錯 | 必須跟 BEGIN OF 的名稱相同 |
| MOVE-CORRESPONDING 後欄位空的 | 兩邊欄位名不同（拼錯） |
| 這一筆混到上一筆的值 | 填欄位前忘了 CLEAR |
| 不同型別結構直接 `=` | 照位置硬轉錯亂 → 用 MOVE-CORRESPONDING |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex03**：

定義學生結構、填值輸出、
練習整體賦值與 MOVE-CORRESPONDING
