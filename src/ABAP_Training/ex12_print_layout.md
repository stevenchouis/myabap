# 練習 12：列印排版與頁面規劃（LINE-SIZE / LINE-COUNT）

## 學習目標

- 會依**輸出印表機**決定 `LINE-SIZE` 與 `LINE-COUNT`
- 會用 `NO STANDARD PAGE HEADING` + 自製頁首（`TOP-OF-PAGE`）與頁尾（`END-OF-PAGE`）
- 會 WRITE 精確排版：`AT` 欄位位置、`(寬度)`、`CENTERED`、`NO-GAP`、`CURRENCY`、`ULINE AT /1(n)`
- 認識系統欄位：`sy-repid`（程式名）、`sy-uname`（使用者）、`sy-pagno`（頁次）

## 印表機與 LINE-SIZE / LINE-COUNT 選型（點矩陣）

### LINE-SIZE 看「一行幾個字元」

| 印表機 | 字元密度 | 一行字元數 | LINE-SIZE 建議 | SAP 列印格式 |
|---|---|---|---|---|
| 窄機（A4 直印 / 9.5"） | 10 CPI 標準 | 80 | **80** | `X_65_80` |
| 寬機（15" 報表紙） | 10 CPI 標準 | 132～136 | **132** | `X_65_132` |
| 寬機壓縮字型 | 17.1 CPI | 230+ | 255（可讀性差，少用） | `X_65_255` |

- LINE-SIZE **超過**印表機格式寬度 → 右邊被截字或折行，報表格線全毀
- 列印格式（`X_65_132` 等）在 SPAD 對應到印表機的 device type，找 Basis 確認可用格式

### LINE-COUNT 看「一頁幾行」

| 報表紙 | 行距 | 實體行數 | LINE-COUNT 建議 |
|---|---|---|---|
| 11 吋連續紙（整刀） | 6 LPI | 66 | **65**（留安全邊界） |
| 5.5 吋連續紙（中一刀） | 6 LPI | 33 | **30～32** |

- `LINE-COUNT 65(3)`：括號＝每頁**保留 3 行給頁尾**，`END-OF-PAGE` 事件才會觸發；沒保留行數，END-OF-PAGE 寫了也不跑
- 螢幕預覽看不出截斷問題——**上線前務必用目標印表機實印一頁驗證**

## 事前準備

建立程式 `ZR_TR12_<你的姓名縮寫>`，套件 `$TMP`。本題假設輸出到「寬機點矩陣、11 吋連續紙」→ `LINE-SIZE 132 LINE-COUNT 65(3)`。

## 題目需求

1. `REPORT ... NO STANDARD PAGE HEADING LINE-SIZE 132 LINE-COUNT 65(3).`，並在註解寫出這三個值的理由
2. 用 `DO 150 TIMES` 產生 150 筆測試資料（項次/品名/數量/單價/金額）——故意超過一頁
3. 明細用 `|` 畫表格線：`/1 '|', 2(6) 欄位, 9 '|', ...` 對齊到固定位置；金額欄用 `CURRENCY 'USD'`
4. `TOP-OF-PAGE`：程式名（`sy-repid`）、置中標題（`50(20) '...' CENTERED`）、日期、使用者、頁次（`sy-pagno`）+ 欄位標題列（`CENTERED`）夾在兩條 `ULINE AT /1(77)` 之間
5. `END-OF-PAGE`：橫線 + 「審核：／製表：」簽核欄
6. 執行後翻頁檢查：每頁都有頁首頁尾、表格線垂直對齊

## 預期結果

150 筆資料分成 3 頁（每頁約 55 筆明細 + 頁首 5 行 + 頁尾 3 行），每頁頁首含頁次，頁尾有簽核欄，`|` 分隔線上下對齊成直線。

## 思考題

1. 目標程式 `Z_INVENTORY_COST_REPORT` 用 `LINE-SIZE 100`——用上面的選型表評論這個值：窄機印得下嗎？寬機會怎樣？你會改成多少？
2. 把 `LINE-COUNT 65(3)` 改成 `LINE-COUNT 65`，END-OF-PAGE 還會觸發嗎？實測看看
3. `CURRENCY 'USD'` 換成 `CURRENCY 'TWD'` 或 `'JPY'`，小數位會怎麼變？（提示：TCURX 表定義各幣別小數位）

## 答案

見 `zr_tr12_print_layout.prog.abap`（SAP 端程式 `ZR_TR12_PRINT_LAYOUT`）。
