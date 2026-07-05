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

# 講義 12
# 列印排版與頁面規劃

ABAP 基礎教育訓練

對應練習 ex12｜答案程式 `ZR_TR12_PRINT_LAYOUT`

---

## 本講重點

- 紙本報表的規格思維：點矩陣印表機、行寬與行數
- `REPORT` 附加項：`NO STANDARD PAGE HEADING` / `LINE-SIZE` / `LINE-COUNT n(m)`
- `WRITE` 精確排版：位置、寬度、對齊、`CURRENCY`
- `ULINE` / `SKIP` / `NEW-PAGE`、`sy-pagno`
- `TOP-OF-PAGE` 頁首與 `END-OF-PAGE` 頁尾的搭配

---

## 1. 先懂紙，再談排版

傳統表單常印在**點矩陣印表機＋連續報表紙**：

| 規格 | 常見值 | 由來 |
|---|---|---|
| 行寬 | 132 字元（寬機）／80（窄機） | 10 CPI 字距下紙寬決定 |
| 每頁行數 | 66 行 | 11 吋紙 × 6 LPI |
| 實用行數 | 65 行（留 1 行邊界） | SAP 列印格式 `X_65_132` |

課程範例的固定開場白：

```abap
REPORT zr_tr12_print_layout NO STANDARD PAGE HEADING
                            LINE-SIZE 132
                            LINE-COUNT 65(3).
```

---

## REPORT 附加項

| 附加項 | 意義 |
|---|---|
| `NO STANDARD PAGE HEADING` | 關掉系統預設頁首，自己用 TOP-OF-PAGE 畫 |
| `LINE-SIZE 132` | 每行 132 字元，超過折到下一行 |
| `LINE-COUNT 65(3)` | 每頁 65 行，**保留末尾 3 行**給頁尾 |

> `(3)` 保留區是 END-OF-PAGE 的**開關**：
> 沒有保留行數，END-OF-PAGE 永遠不觸發
> ——「頁尾怎麼不出來」的最常見原因

---

## 2. WRITE 精確排版

格式：`WRITE /位置(寬度) 資料 [對齊/格式選項].`

```abap
LOOP AT gt_items INTO gs_item.
  WRITE: /1  '|', 2(6)   gs_item-itemno,
          9  '|', 10(20) gs_item-name,
          31 '|', 32(10) gs_item-qty,
          43 '|', 44(14) gs_item-price  CURRENCY 'USD',
          59 '|', 60(16) gs_item-amount CURRENCY 'USD',
          77 '|'.
ENDLOOP.
```

| 寫法 | 意義 |
|---|---|
| `/1` | 換行後從第 1 欄開始 |
| `10(20)` | 從第 10 欄開始、寬度 20 |

> 排版的全部秘密：**畫一張欄位座標表**
> 頁首、明細、頁尾都照表寫，直欄就對得筆直

---

## 格式選項與輔助指令

| 選項 | 效果 |
|---|---|
| `CENTERED` / `RIGHT-JUSTIFIED` | 指定寬度內置中／靠右 |
| `CURRENCY 'USD'` | 依幣別小數位格式化——**金額欄必加** |
| `NO-GAP` | 下一個輸出緊貼 |
| `NO-ZERO` | 數字 0 顯示成空白 |
| `USING EDIT MASK '__:__'` | 自訂顯示遮罩 |

```abap
ULINE.                 " 整行橫線
ULINE AT /1(77).       " 從第 1 欄畫 77 字元寬
SKIP.                  " 空一行（SKIP 3. 空三行）
NEW-PAGE.              " 強制換頁
```

---

<!-- _class: compact -->

## 3. 頁首與頁尾（標準版型）

```abap
TOP-OF-PAGE.
  WRITE: /1   '程式：', (20) sy-repid,
          50(20) '測試列印報表' CENTERED,
          108 '日期：', sy-datum.
  WRITE: /1   '使用者：', (18) sy-uname,
          108 '頁次：', (4) sy-pagno.
  ULINE AT /1(77).
  WRITE: /1  '|', 2(6)   '項次' CENTERED,
          9  '|', 10(20) '品名' CENTERED,
          31 '|', 32(10) '數量' CENTERED,
          43 '|', 44(14) '單價' CENTERED,
          59 '|', 60(16) '金額' CENTERED,
          77 '|'.
  ULINE AT /1(77).

END-OF-PAGE.
  ULINE AT /1(77).
  WRITE: /1 '審核：____________', 40 '製表：____________'.
```

- `sy-pagno`：目前頁次，頁首直接印
- 明細超過一頁 → 系統自動「頁尾 → 換頁 → 頁首」接下去
- 「頁次 n / **總頁數**」的回填技巧 → 期末實作講義 13

---

## 4. 驗證方式

- 課堂上直接看螢幕清單（清單就是「虛擬的紙」）
- 看分頁效果：故意產生超過一頁的測試資料
  （DO 150 TIMES 塞 150 筆）
  → 觀察每頁的頁首、頁尾、頁次遞增
- 列印預覽：清單畫面 → 列印 → 選格式（X_65_132）

---

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| END-OF-PAGE 完全不執行 | LINE-COUNT 沒寫保留行數 `(m)` |
| 直欄歪掉對不齊 | 起始位置/寬度不一致——先畫座標表 |
| 金額小數位錯 | 忘了 `CURRENCY`（JPY 是 0 位小數） |
| 每頁上方多一行程式名 | 忘了 `NO STANDARD PAGE HEADING` |
| 內容被折行 | 超出 LINE-SIZE |
| 中文欄位寬度怪 | 全形字佔**兩個**輸出位置 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex12**：

做一張 132 欄寬、65(3) 行的多頁明細報表

頁首（程式資訊＋欄位標題）、表格線、
金額 CURRENCY 格式、頁尾簽核欄
