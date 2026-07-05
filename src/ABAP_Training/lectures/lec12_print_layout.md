# 講義 12：列印排版與頁面規劃

> 對應練習：[ex12](../ex12_print_layout.md)｜答案程式：`ZR_TR12_PRINT_LAYOUT`

## 本講重點

- 紙本報表的規格思維：點矩陣印表機、行寬與行數怎麼定
- `REPORT` 附加項：`NO STANDARD PAGE HEADING` / `LINE-SIZE` / `LINE-COUNT n(m)`
- `WRITE` 精確排版：位置、寬度、對齊、`CURRENCY`
- `ULINE` / `SKIP` / `NEW-PAGE`、`sy-pagno`
- `TOP-OF-PAGE` 頁首與 `END-OF-PAGE` 頁尾的搭配

## 1. 先懂紙，再談排版

傳統表單（出貨單、對帳單）常印在**點矩陣印表機＋連續報表紙**上，規格是排版的前提：

| 規格 | 常見值 | 由來 |
|---|---|---|
| 行寬 | 132 字元（寬機）／80 字元（窄機） | 10 CPI 字距下紙寬決定 |
| 每頁行數 | 66 行 | 11 吋紙 × 6 LPI |
| 實用行數 | 65 行（留 1 行安全邊界） | 對應 SAP 列印格式 `X_65_132`（SPAD 維護） |

所以課程範例的固定開場白是：

```abap
REPORT zr_tr12_print_layout NO STANDARD PAGE HEADING
                            LINE-SIZE 132
                            LINE-COUNT 65(3).
```

| 附加項 | 意義 |
|---|---|
| `NO STANDARD PAGE HEADING` | 關掉系統預設頁首（程式名那行），自己用 TOP-OF-PAGE 畫 |
| `LINE-SIZE 132` | 每行 132 字元，超過的 WRITE 內容折到下一行 |
| `LINE-COUNT 65(3)` | 每頁 65 行，其中**保留末尾 3 行**給頁尾（END-OF-PAGE） |

> `(3)` 這個保留區是 END-OF-PAGE 的開關：**沒有保留行數，END-OF-PAGE 永遠不觸發**——最常見的「頁尾怎麼不出來」原因。

## 2. WRITE 精確排版

完整格式：`WRITE [AT] /位置(寬度) 資料 [對齊/格式選項].`

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
| `(20)`（無位置） | 接目前位置，寬度 20 |

每欄位固定「起始欄＋寬度」，配合頁首同座標的欄位標題，直欄就會對得筆直——這是點矩陣報表排版的全部秘密：**畫一張欄位座標表，頁首、明細、頁尾都照表寫**。

常用格式選項：

| 選項 | 效果 |
|---|---|
| `CENTERED` / `RIGHT-JUSTIFIED` / `LEFT-JUSTIFIED` | 指定寬度內置中／靠右／靠左（數值預設靠右、文字靠左） |
| `CURRENCY 'USD'`（或幣別變數） | 依幣別小數位格式化金額——金額欄必加 |
| `NO-GAP` | 下一個輸出緊貼、不留間隔 |
| `NO-ZERO` | 數字 0 顯示成空白 |
| `USING EDIT MASK '__:__'` | 自訂顯示遮罩 |

輔助指令：

```abap
ULINE.                 " 整行橫線
ULINE AT /1(77).       " 從第 1 欄畫 77 個字元寬的橫線
SKIP.                  " 空一行（SKIP 3. 空三行）
NEW-PAGE.              " 強制換頁
```

## 3. 頁首與頁尾

搭配講義 10 的清單事件，標準版型長這樣：

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

- `sy-pagno`：目前頁次，頁首直接印。
- 觸發時機回顧：TOP-OF-PAGE 在每頁第一個 WRITE 前；END-OF-PAGE 在輸出踏進保留行區時。明細行數超過一頁，系統自動「頁尾 → 換頁 → 頁首」接下去。
- 「頁次 n / 總頁數」的**總頁數**要等全部輸出完才知道——回填技巧（READ LINE / MODIFY LINE）在期末實作講義 13 教。

## 4. 驗證方式

課堂上直接看螢幕清單即可（清單就是「虛擬的紙」）；要看實際分頁效果，故意產生超過一頁的測試資料（如 DO 150 TIMES 塞 150 筆），觀察每頁的頁首、頁尾與頁次遞增。列印預覽：清單畫面 → 列印，選對應格式（如 X_65_132）。

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| END-OF-PAGE 完全不執行 | LINE-COUNT 沒寫保留行數 `(m)` |
| 直欄歪掉對不齊 | 各行同一欄位的起始位置/寬度不一致——先畫欄位座標表 |
| 金額小數位錯 | 忘了 `CURRENCY`（有的幣別 0 位小數，如 JPY） |
| 每頁上方多一行程式名 | 忘了 `NO STANDARD PAGE HEADING` |
| 內容被折行 | 超出 LINE-SIZE——加寬或縮欄位 |
| 中文欄位寬度怪 | 全形字佔兩個輸出位置，寬度要抓兩倍 |

## 6. 課堂練習

完成 [ex12](../ex12_print_layout.md)：做一張 132 欄寬、65(3) 行的多頁明細報表——頁首（程式資訊＋欄位標題）、表格線、金額 CURRENCY 格式、頁尾簽核欄。
