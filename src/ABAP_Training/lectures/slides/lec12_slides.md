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

<!-- _class: compact -->

## 買紙時看到的規格：80 行、132 行、中一刀

品名範例：「電腦報表紙 9.5×11×1P（80行）中一刀」

| 品名上的字 | 意思 |
|---|---|
| `9.5×11` | 紙寬×紙長（英吋），寬度含兩側孔條 |
| `80行`／`132行` | **一行幾個字**（＝`LINE-SIZE`），不是一頁幾行 |
| `1P`／`2P` | 聯數 |
| 全頁／**中一刀**／中二刀 | 一頁中間沒撕線／**1 條撕線（上下兩張 9.5×5.5）**／2 條（三張） |

| 撕法 | 每張長度 | 可印行數（6 LPI） |
|---|---|---|
| 全頁 | 11 吋 | 66 |
| 中一刀 | 5.5 吋 | **33** |
| 中二刀 | 約 3.67 吋 | 22 |

中一刀印半張單據：① `LINE-COUNT 33`＋Basis 建 33 行自訂格式＋印表機頁長 5.5 吋
或 ② 維持 66 行，一頁排兩張，第二張 `SKIP TO LINE 34`
→ **先問清楚用哪種紙**，行寬與頁長都由紙決定

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

<!-- _class: compact -->

## 1.1 超過 132 欄：LINE-SIZE 要對得上列印格式

實務上看到的寫法：`LINE-SIZE 203` ＋ `LINE-COUNT 65(0)`

- **203 不是標準印表機寬度**：更寬的報表靠壓縮字（約 17 CPI）或雷射橫印
- 列印時要選**寬度 ≥ LINE-SIZE** 的格式（本系統實有）：

| 格式 | 行 × 字 | 用途 |
|---|---|---|
| `X_65_80` | 65 × 80 | 窄機 |
| `X_65_132` | 65 × 132 | **點矩陣寬機標準** |
| `X_65_200` | 65 × 200 | 壓縮字／雷射橫印 |
| `X_65_255` | 65 × 255 | 傳統清單最大寬度 |

- 203 > 200 → 要用 `X_65_255`；**寬報表直接取 200 或 255**
- `65(0)`：保留 0 行 → END-OF-PAGE 永不觸發

---

<!-- _class: compact -->

## 1.2 要印到某台印表機：先查它支援的 Format

工廠大型機：寬機點矩陣／行式印表機 → 通常 `X_65_132` 或 `X_65_255`
（標籤機 Zebra 是另一套：Smartform／ZPL）

**查法**：列印 → Output Device 選該印表機 → **Format 按 F4**
（或 SPAD：Output Device → Device Type → Formats）

**參數照格式名 `X_行數_寬度` 寫**：

| 格式 | REPORT 參數 |
|---|---|
| `X_65_132` | `LINE-SIZE 132  LINE-COUNT 65(m)` |
| `X_65_255` | `LINE-SIZE 255  LINE-COUNT 65(m)` |
| `X_90_120` | `LINE-SIZE 120  LINE-COUNT 90(m)` |

- **優先用 132**（正常字最好讀），放不下才用 255
- LINE-SIZE 可比格式窄，不能比它寬
- 固定印某台：`GET_PRINT_PARAMETERS` 的 `LAYOUT` 寫死格式

---

## 1.3 正常字距還是壓縮字？由 Format 決定

**ABAP 沒有「切換壓縮字」的指令**，清單只管幾字×幾行

1. LINE-SIZE → 列印時系統**帶出預設 Format**（可改選）
2. SPAD 裡每個 Device Type × Format 有**印表機初始化控制碼**
   → `X_65_255` 送出 17 CPI 壓縮字、`X_65_132` 維持 10 CPI
3. Windows 驅動印表機：SAP 依格式寬度**自動縮字**

> 程式只是**間接**影響；字距不對 → 請 Basis 查 SPAD，改程式沒用

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

## 2.1 中文字會被截掉：寬度要自己給足

`WRITE` 的預設輸出寬度**按字數**算，但中文字、`→` 每個**佔兩格**
→ 結尾被截掉，**沒有錯誤訊息**

```abap
WRITE / '測試 2：雙擊這一行 → SUBMIT 另一支報表'.
* 顯示：測試 2：雙擊這一行 → SUBMIT 另一支報      ← 「表」不見了

WRITE /(60) '測試 2：雙擊這一行 → SUBMIT 另一支報表'.
* 顯示：完整                                      ← 指定寬度 60 格
```

用 `(寬度)` 指定輸出寬度，中文一個字抓**兩格**
欄位座標表裡的中文欄位也以「字數 × 2」規劃

（講義 10 驗證程式實測，2026-09-25）

---

<!-- _class: compact -->

## 位置／寬度用變數、SKIP TO LINE、算實際格數

```abap
WRITE AT /gv_pos(gv_wid) gs_item-name.      " 變數當位置寬度要加 AT
WRITE: AT /01(t_optfm-hkont) t_docit-hkont,  " 欄寬集中在一個結構
       AT    (t_optfm-kostl) t_docit-kostl.
SKIP TO LINE 55.                             " 游標跳到本頁第 55 行

gv_disp = cl_abap_list_utilities=>dynamic_output_length( gv_text ).
gv_pos  = ( sy-linsz - gv_disp ) / 2.        " 中文標題置中
WRITE AT /gv_pos gv_text.
```

- `t_optfm` 結構 = 欄位座標表的程式版：改一個 VALUE，所有列一起變
- `SKIP TO LINE n`：n 超過頁長會變成普通 SKIP
- 實測「東捷資訊ABC」：`strlen` = 7、`dynamic_output_length` = **11**
- 以上都出自講義 13 的實戰案例 ZRFI0004

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

## 3.1 65(3) 怎麼算？最後一頁為何沒頁尾？

**65 = 整頁總行數**：頁首標題、空行、明細、頁尾**全部算在內**
`(3)` = 從 65 行裡劃出最後 3 行給頁尾

> 上頁版型：頁首 5 行 ＋ 頁尾 3 行 → 明細最多 **57** 行

⚠️ END-OF-PAGE **只在寫到保留區時觸發**（`NEW-PAGE` 不觸發）
→ 最後一頁沒寫滿 → **沒有頁尾**；一頁的短報表完全沒頁尾

實務常見改法：
- `LINE-COUNT 65(0)`：不保留，65 行全給頁首＋明細
- 明細 FORM 結尾自己印頁尾，先 `RESERVE n LINES.` 避免頁尾被拆兩頁
- 代價：頁尾只在報表最後，不是每頁都有

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
| 最後一頁沒頁尾 | 沒寫滿到保留區不觸發（3.1） |
| 直欄歪掉對不齊 | 起始位置/寬度不一致——先畫座標表 |
| 金額小數位錯 | 忘了 `CURRENCY`（JPY 是 0 位小數） |
| 每頁上方多一行程式名 | 忘了 `NO STANDARD PAGE HEADING` |
| 內容被折行 | 超出 LINE-SIZE |
| 中文欄位寬度怪、結尾被截 | 全形字佔**兩格**，用 `(寬度)` 指定（2.1） |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex12**：

做一張 132 欄寬、65(3) 行的多頁明細報表

頁首（程式資訊＋欄位標題）、表格線、
金額 CURRENCY 格式、頁尾簽核欄
