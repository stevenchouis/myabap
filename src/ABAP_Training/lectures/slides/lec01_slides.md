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

# 講義 1
# ABAP 語法基礎

ABAP 基礎教育訓練

對應練習 ex01｜答案程式 `ZR_TR01_SYNTAX_BASICS`

---

## 本講重點

- ABAP 程式怎麼建立、怎麼執行（SE38 / Executable Program）
- statement 以句點 `.` 結束，可自由跨行
- 兩種註解：`*`（整行）與 `"`（行內）
- 冒號 `:` 鏈式寫法
- 關鍵字不分大小寫與 Pretty Printer
- `WRITE` 輸出與 `/` 換行

---

## 1. ABAP 程式的執行環境

程式不是你電腦裡的檔案，是 SAP 資料庫中的 **Repository 物件**，在應用伺服器上執行

**建立程式的固定步驟**（所有練習共用）：

1. SE38 → 程式名 `ZR_TRnn_姓名縮寫` → Create
2. Type 選 **Executable Program**
3. Package 填 `$TMP`（Local Object，不產生 TR）
4. 撰寫 → `Ctrl+F2` 檢查 → `Ctrl+F3` 啟用 → `F8` 執行

> **存檔 ≠ 啟用**：執行的是 active 版本
> 改完沒啟用，跑起來還是舊的——初學最容易困惑的地方

---

## 2. Statement 與句點

規則只有一條：**以句點 `.` 結束**，換行縮排都不影響意義

```abap
WRITE 'Hello ABAP!'.

* 跟上面那行完全等價：
WRITE
  'Hello ABAP!'
  .
```

**編譯器只認句點** → 兩個常見錯誤：

- 忘記句點：錯誤訊息指到「下一行」→ 先檢查上一行結尾
- 句點打成逗號：鏈式中間才用逗號，最後一定是句點

---

## 3. 註解

| 寫法 | 規則 |
|---|---|
| `*` 整行註解 | 星號必須在**第 1 個字元**（行首） |
| `"` 行內註解 | 從雙引號到行尾，可跟程式碼同行 |

```abap
* 整行註解：星號一定要貼行首，縮排後的 * 是語法錯誤
WRITE 'Hello'.        " 行內註解：解釋這一行
```

> 實務建議：註解寫「**為什麼**這樣做」
> 不要寫「這行在做什麼」（程式碼本身看得出來）

---

## 4. 冒號鏈式寫法

開頭關鍵字相同的多個 statement，用 `:` 合併、`,` 分隔、`.` 收尾

```abap
* 三句分開寫：
WRITE / 'A'.
WRITE / 'B'.

* 鏈式寫法，完全等價：
WRITE: / 'A',
       / 'B'.

* 宣告區的標準長相：
DATA: gv_a TYPE i,
      gv_b TYPE i.
```

展開規則：**冒號前的部分複製到每一段**

---

## 5. 關鍵字不分大小寫

```abap
write / 'lowercase 寫法'.
Write / 'Mixed Case 寫法'.
WRITE / 'UPPERCASE 寫法'.
```

- 對編譯器完全相同
- 例外：字面文字 `'...'` 裡是**資料**，大小寫有差
- 團隊格式靠 **Pretty Printer**（`Shift+F1`）統一
  寫完習慣按一下

---

## 6. WRITE 輸出

| 寫法 | 效果 |
|---|---|
| `WRITE '文字'.` | 接在目前輸出位置後面（同行，隔一格） |
| `WRITE / '文字'.` | **先換行**再輸出 |
| `WRITE: / 'A', 'B'.` | A 換行輸出，B 接在 A 後面 |

```abap
WRITE 'Hello ABAP!'.          " 第一行（清單起點）
WRITE '接在後面'.              " 不加 / ：同一行繼續
WRITE / '這是第二行'.          " 加 / ：換行
```

後面可接字面文字、變數、系統欄位（`sy-datum`）
格式控制（對齊、寬度）留到講義 12

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 錯誤指在某行，那行看起來沒問題 | **上一行忘了句點** |
| `*` 註解報語法錯誤 | 星號不在行首 |
| 改了程式，執行結果沒變 | 只存檔沒啟用（Activate） |
| 鏈式寫法報錯 | 中間用了句點、或最後用了逗號 |
| 字面文字裡想放單引號 | 連寫兩個：`'It''s ok'` |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex01**：

用 WRITE、註解、鏈式寫法、
大小寫混用、跨行 statement 各寫一段

驗證本講所有規則
