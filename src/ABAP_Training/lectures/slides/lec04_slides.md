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

# 講義 4
# Internal Table 基礎

ABAP 基礎教育訓練

對應練習 ex04｜答案程式 `ZR_TR04_ITAB_BASICS`

---

## 本講重點

- 三個角色的分工：資料庫表、internal table（多筆）、work area（一筆）
- `TYPES ... TYPE STANDARD TABLE OF` 定義表格型別
- `APPEND` 加資料、`LOOP AT ... INTO` 逐筆處理
- `READ TABLE ... WITH KEY / INDEX` 讀單筆
- **鐵律：讀完就檢查 `sy-subrc`**；認識 `sy-tabix`
- `CLEAR` / `REFRESH` / `FREE` 的差別

---

## 1. 三個角色

| 角色 | 位置 | 存幾筆 | 比喻 |
|---|---|---|---|
| 資料庫表 | 資料庫，永久保存 | 全公司的資料 | 倉庫 |
| internal table | 程式記憶體 | 這次要處理的多筆 | 推車 |
| work area | 程式記憶體 | **一次一筆** | 手上那一件 |

典型報表流程：
DB → SELECT 進 internal table（講義 6）→ 記憶體加工 → 輸出

work area = 與內表之間搬進搬出的「單筆容器」
型別就是上一講的**結構**

---

## 2. 宣告 internal table

一列的長相（結構）→ 很多列（表格型別）→ DATA 出實體：

```abap
TYPES: BEGIN OF ty_student,
         id    TYPE c LENGTH 5,
         name  TYPE string,
         score TYPE i,
       END OF ty_student.

TYPES tt_student TYPE STANDARD TABLE OF ty_student
                 WITH NON-UNIQUE KEY id.

DATA: gt_students TYPE tt_student,     " internal table：多筆
      gs_student  TYPE ty_student.     " work area：一筆
```

| 類別 | 特性 |
|---|---|
| `STANDARD` | 依附加順序（**本課程用這個**） |
| `SORTED` | 永遠依 KEY 排序，二分搜尋 |
| `HASHED` | KEY 查詢與筆數無關，必須 UNIQUE KEY |

---

## 3. APPEND：加一筆到表尾

```abap
gs_student-id = 'S0001'. gs_student-name = '王小明'.
gs_student-score = 85.
APPEND gs_student TO gt_students.

gs_student-id = 'S0002'. gs_student-name = '李小美'.
gs_student-score = 92.
APPEND gs_student TO gt_students.
```

APPEND 是**複製**進表尾：

- APPEND 後再改 work area，表裡那筆**不會跟著變**
- 填新一筆沒把每個欄位都覆寫 → 舊值殘留混入
  → 必要時先 `CLEAR gs_student.`

---

## 4. LOOP AT ... INTO：逐筆處理

```abap
LOOP AT gt_students INTO gs_student.
  WRITE: / sy-tabix, gs_student-id, gs_student-score.
ENDLOOP.
```

- 每圈把當前列**複製**進 work area
  → 改 `gs_student` 不會改到表格（要改用 MODIFY／ASSIGNING）
- `sy-tabix`：目前第幾筆（1 起算）
- 可加條件：`LOOP AT ... WHERE score >= 60.`
- 一筆都沒迴圈到 → ENDLOOP 後 `sy-subrc <> 0`

---

## 5. READ TABLE：讀單筆

```abap
* 方式一：WITH KEY——找第一筆符合的
READ TABLE gt_students INTO gs_student WITH KEY id = 'S0002'.
IF sy-subrc = 0.
  WRITE: / '找到：', gs_student-name.
ENDIF.

* 方式二：INDEX——直接讀第 n 筆
READ TABLE gt_students INTO gs_student INDEX 3.

* 只想知道「有沒有」：不搬資料、較快，位置在 sy-tabix
READ TABLE gt_students TRANSPORTING NO FIELDS
     WITH KEY id = 'S0002'.
```

---

## 6. 鐵律：檢查 sy-subrc

READ 找不到時**不報錯、不當掉**，且 **work area 保持原內容**：

```abap
READ TABLE gt_students INTO gs_student
     WITH KEY id = 'S0002'.   " 找到，gs 是李小美
READ TABLE gt_students INTO gs_student
     WITH KEY id = 'S9999'.   " 沒找到！
WRITE gs_student-name.        " 印出來還是「李小美」——殘留值！
```

「查無資料卻顯示別人的資料」的標準成因

> 反射動作：**READ TABLE 下一行永遠是 `IF sy-subrc = 0.`**
> 同理適用 SELECT、CALL FUNCTION…

---

## 7. CLEAR / REFRESH / FREE

| 指令 | 對 work area | 對 internal table |
|---|---|---|
| `CLEAR gs.` | 欄位全歸初始值 | - |
| `CLEAR gt.` / `REFRESH gt.` | - | 刪光所有列（記憶體保留） |
| `FREE gt.` | - | 刪光並釋放記憶體 |

日常用 `CLEAR` 就夠
`REFRESH` 是舊寫法，讀舊程式會遇到，效果同 `CLEAR gt.`

---

## 8. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 查無資料卻顯示出值 | READ 失敗沒檢查 sy-subrc，用到殘留值 |
| 兩筆資料長一樣 | APPEND 後忘了改 work area 又 APPEND |
| LOOP 裡改值，表格沒變 | INTO 是複本 → MODIFY 或 ASSIGNING |
| `sy-tabix` 在 LOOP 外不對 | 只在 LOOP/READ 當下有意義 |
| READ INDEX 0 或超過筆數 | sy-subrc = 4/8，一樣要檢查 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex04**：

建學生內表、APPEND 三筆、LOOP 輸出、
WITH KEY 與 INDEX 讀取

實際觀察 sy-subrc 與殘留值現象
