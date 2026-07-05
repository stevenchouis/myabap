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

# 講義 2
# 變數與 TYPE / LIKE / CONSTANTS

ABAP 基礎教育訓練

對應練習 ex02｜答案程式 `ZR_TR02_TYPE_LIKE`

---

## 本講重點

- `DATA` 宣告變數：TYPE、LENGTH、DECIMALS、VALUE
- 內建資料型別總表與適用場景
- `TYPE`（參考型別）與 `LIKE`（參考另一個變數）的差別
- `CONSTANTS` 常數
- 賦值 `=`、`CLEAR`，以及自動型別轉換的行為

---

## 1. 宣告變數：DATA

```abap
DATA 變數名 TYPE 型別 [LENGTH 長度] [DECIMALS 小數位] [VALUE 初始值].
```

```abap
DATA gv_name  TYPE c LENGTH 10 VALUE 'ABAP'.   " 固定長度文字
DATA gv_count TYPE i VALUE 100.                " 整數
DATA gv_price TYPE p LENGTH 8 DECIMALS 2.      " 帶小數的金額
DATA gv_memo  TYPE string.                     " 變動長度文字

* 鏈式寫法（實務標準寫法）：
DATA: gv_qty   TYPE i,
      gv_today TYPE d.
```

命名慣例：全域 `gv_`/`gs_`/`gt_`、區域 `lv_`/`ls_`/`lt_`
→ 前綴讓人一眼看出「這是什麼形狀的資料」

---

<!-- _class: compact -->

## 2. 內建資料型別總表

| 型別 | 名稱 | 初始值 | 用途與注意 |
|---|---|---|---|
| `c` | 固定長度字元 | 空白 | **不給 LENGTH 就只有 1 個字元** |
| `n` | 數字字元 | '0…0' | 編號（如 0001），不能拿來運算 |
| `string` | 變動長度字串 | 空字串 | 一般文字建議用它 |
| `i` | 整數 | 0 | 計數、筆數 |
| `p` | 壓縮十進位 | 0 | **金額、數量的標準型別** + DECIMALS |
| `f` | 浮點數 | 0.0 | 有精度誤差，**金額禁用** |
| `d` | 日期 | '00000000' | YYYYMMDD，可直接加減天數 |
| `t` | 時間 | '000000' | HHMMSS |
| `x`/`xstring` | 十六進位 | - | 二進位資料，先認識即可 |

三個最容易踩的點：
`TYPE c` 忘 LENGTH（只剩 1 字）｜金額用 `f`（0.1 存不準）｜`n` 參與運算

---

## 日期運算範例

`d` 型別可以直接加減天數：

```abap
DATA: gv_today TYPE d,
      gv_due   TYPE d.

gv_today = sy-datum.          " 系統欄位：今天日期
gv_due   = gv_today + 30.     " 30 天後

WRITE: / '今天：', gv_today, '30 天後：', gv_due.
```

---

## 3. TYPE 與 LIKE 的差別

| 寫法 | 參考對象 | 讀法 |
|---|---|---|
| `DATA a TYPE i.` | **型別** | 「a 的型別是 i」 |
| `DATA b LIKE a.` | **另一個資料物件** | 「b 跟 a 長一樣」 |

```abap
DATA gv_date1 TYPE d.            " TYPE：參考型別
DATA gv_date2 LIKE sy-datum.     " LIKE：參考系統欄位
DATA gv_date3 LIKE gv_date1.     " LIKE：跟 gv_date1 同型別
```

- 「跟某個既有欄位保持一致」用 `LIKE`——來源改了自動跟
- 之後最常見：`TYPE scarr-carrid`（DDIC 欄位型別，講義 6）
- 進階：`DATA gs LIKE LINE OF gt_tab.`（講義 10）

---

## 4. CONSTANTS 常數

宣告後不可改值，**必須**給 `VALUE`：

```abap
CONSTANTS gc_max_score TYPE i VALUE 100.
CONSTANTS gc_pass_line TYPE i VALUE 60.

IF gv_score >= gc_pass_line.
  WRITE / '及格'.
ENDIF.
```

- 把「魔術數字」集中命名：改規則只改一處
- `gc_pass_line` 比裸寫 `60` 可讀得多
- 對常數賦值 → 直接編譯錯誤（這是保護不是限制）

---

## 5. 賦值、CLEAR 與型別轉換

```abap
gv_count = 42.                 " 賦值就是等號
CLEAR gv_count.                " 恢復初始值（i 是 0，c 是空白）
```

不同型別互相賦值會**自動轉換**——方便也危險：

```abap
DATA: gv_char TYPE c LENGTH 3 VALUE '123',
      gv_int  TYPE i.
gv_int = gv_char.              " '123' → 123，成功
gv_char = 'ABC'.
* gv_int = gv_char.            " 執行期當掉 CONVT_NO_NUMBER！
```

> 鐵律：轉換錯誤是**執行期**才爆，語法檢查抓不到
> 來源資料不可信時，賦值前要自己驗證

---

## 6. 系統欄位初探（structure SY)

用 `sy-欄位名` 取用，本課程常用：

| 欄位 | 內容 |
|---|---|
| `sy-datum` | 今天日期（伺服器） |
| `sy-uzeit` | 現在時間 |
| `sy-uname` | 登入帳號 |
| `sy-subrc` | 上一個操作的回傳碼（0 = 成功）——講義 4 起天天用 |
| `sy-tabix` | 內表迴圈目前筆數（講義 4） |
| `sy-index` | `DO` 迴圈目前圈數（講義 17） |

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 文字被截成 1 個字 | `TYPE c` 沒給 LENGTH |
| 金額加總出現 0.0000001 誤差 | 用了 `f`，該用 `p DECIMALS` |
| 對 CONSTANTS 賦值編譯錯誤 | 常數不可改——改宣告的 VALUE |
| 執行期 CONVT_NO_NUMBER | 字元轉數值但內容不是數字 |
| `LIKE` 後面接型別名報錯 | `LIKE` 只能接資料物件 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex02**：

宣告各型別變數、用 LIKE 參考、
定義常數並觀察轉換行為
