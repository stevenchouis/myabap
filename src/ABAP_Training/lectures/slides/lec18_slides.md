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

# 講義 18
# 字串與日期處理

ABAP 基礎教育訓練（授課順序：接在講義 17 之後）

對應練習 ex18｜答案程式 `ZR_TR18_STRING_DATE`

---

## 本講重點

- 字串五大指令：`CONCATENATE`、`SPLIT`、`CONDENSE`、`REPLACE`、`TRANSLATE`
- 位移取子字串 `變數+位移(長度)`、`strlen( )`
- `c`（固定長度）與 `string`（變動長度）的差異
- 日期運算：加減天數、天數差、月初／月末

---

## 1. CONCATENATE：串接

```abap
DATA: gv_last  TYPE c LENGTH 10 VALUE '王',
      gv_first TYPE c LENGTH 10 VALUE '小明',
      gv_full  TYPE string.

CONCATENATE gv_last gv_first INTO gv_full.
* '王小明'——c 欄位「尾端」空白串接時自動忽略

CONCATENATE 'A' 'B' 'C' INTO gv_path SEPARATED BY '-'.
* 'A-B-C'——SEPARATED BY 指定分隔符
```

- 真的要保留尾端空白 → `RESPECTING BLANKS`（少用）
- 7.40 新語法對照：`gv_full = |{ gv_last }{ gv_first }|.`
  （字串模板，新程式常見，先認得）

---

## 2. SPLIT：拆解

```abap
DATA gv_csv TYPE string VALUE 'S0001,王小明,85'.

SPLIT gv_csv AT ',' INTO gv_id gv_name gv_score.
```

- 接收變數比片段少：**最後一個變數收下剩餘全部**
- 片段數不固定 → 拆進內表：
  `SPLIT gv_csv AT ',' INTO TABLE lt_parts.`
  （處理上傳檔案每一行的標準手法）

---

## 3. CONDENSE / REPLACE / TRANSLATE

```abap
DATA gv_text TYPE c LENGTH 30 VALUE '  ABAP   is   fun  '.

CONDENSE gv_text.            " 'ABAP is fun'：連續空白縮成一個
CONDENSE gv_text NO-GAPS.    " 'ABAPisfun'：空白全部拿掉

REPLACE 'fun' WITH 'great' INTO gv_text.       " 只換第一個
REPLACE ALL OCCURRENCES OF 'a' IN gv_text
        WITH 'x'.            " 全部換；沒找到 sy-subrc = 4

TRANSLATE gv_text TO UPPER CASE.   " 轉大寫
```

> 實務：使用者輸入拿去跟資料庫比對前的標準前處理
> = `CONDENSE` + `TRANSLATE TO UPPER CASE`（DB 多存大寫）

---

## 4. 位移取子字串與 strlen

`變數+位移(長度)`：位移**從 0 起算**（ABAP 少數從 0 數的地方）

```abap
DATA gv_date_c TYPE c LENGTH 8 VALUE '20260705'.

gv_yyyy = gv_date_c+0(4).         " '2026'：從第 0 位取 4 碼
WRITE: / gv_date_c+4(2).          " '07'：年月日各自切
gv_id+2(3) = '***'.               " 寫入也可以：'S0***'（遮罩）

gv_len = strlen( gv_date_c ).     " 8（c 型別不含尾端空白）
```

> 位移＋長度超出實際長度 → **執行期 dump**
> 來源不定長時，先 `strlen( )` 檢查再切

---

## 5. c 與 string 的差異整理

| | `c LENGTH n` | `string` |
|---|---|---|
| 長度 | 固定，不足補空白 | 變動，多長存多長 |
| 尾端空白 | 一直都在 | 有就是有 |
| 適用 | 固定格式欄位（代碼、學號） | 一般文字、拼接結果 |

最容易踩的差異：

- `c` 塞超長內容**默默截斷**；`string` 不會
- `WRITE` 一個 `c LENGTH 20` 佔滿 20 格版面
  `string` 只佔實際長度

---

## 6. 日期運算

`d` 是 8 碼字元（YYYYMMDD），但**可直接整數式加減**：

```abap
gv_today = sy-datum.
gv_due   = gv_today + 30.            " 30 天後（自動跨月跨年）
gv_days  = gv_today - '20260101'.    " 相減 = 天數差

* 月初：日的部分改成 01（位移寫入）
gv_first = gv_today.
gv_first+6(2) = '01'.

* 月末標準套路：月初 +31 必落下月 → 改下月 1 號 → 減 1 天
gv_last = gv_first + 31.
gv_last+6(2) = '01'.
gv_last = gv_last - 1.
```

「+31 保證跨月」：大小月、閏年通吃，不用自己判斷

---

## 日期補充

- 拆年月日：`+0(4)` 年、`+4(2)` 月、`+6(2)` 日
- `WRITE gv_today.` 依使用者設定格式化（如 05.07.2026）
  要固定格式就自己用位移拼
- 時間 `t`（HHMMSS）同理可加減秒數；`sy-uzeit` 現在時間
- 星期幾、工作日、民國年轉換 → **標準 FM 都有**
  （如 `DATE_COMPUTE_DAY`）——日期難題先找標準 FM

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| CONCATENATE 中間空白不見 | `c` 尾端空白自動忽略——用 SEPARATED BY |
| SPLIT 最後一個變數內容怪 | 變數比片段少，剩餘全塞給最後一個 |
| 位移取值 dump | 超過來源長度；位移是 0 起算 |
| REPLACE 後資料沒變 | 只換第一個、或大小寫不符 |
| 月末算成 30 或 28 號 | 自己判斷大小月寫錯——用「下月初減一天」 |
| 日期相加變怪字串 | 其中一邊不是 `d` 型別 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex18**：

姓名串接、CSV 拆欄、學號遮罩、
字串整理（CONDENSE/REPLACE/TRANSLATE）、
本月月初月末與天數差計算
