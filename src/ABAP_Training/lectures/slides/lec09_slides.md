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

# 講義 9
# Functional ALV 與 MACRO

ABAP 基礎教育訓練

對應練習 ex09｜答案程式 `ZR_TR09_ALV`

---

## 本講重點

- ALV 是什麼、為什麼取代純 WRITE 清單
- fieldcat（欄位目錄）：告訴 ALV 每個欄位怎麼顯示
- `REUSE_ALV_GRID_DISPLAY` 的呼叫方式與常用參數
- layout 版面設定（斑馬紋、欄寬最佳化）
- MACRO（`DEFINE ... END-OF-DEFINITION`）：讀舊程式必修

---

## 1. ALV 是什麼

ALV（ABAP List Viewer）= SAP 標準表格顯示元件

使用者拿到的不是死板文字清單，而是能
**排序、篩選、加總、調欄寬、匯出 Excel** 的互動表格
——全部內建，一行都不用寫。實務報表輸出九成用 ALV

| 寫法 | 核心 | 定位 |
|---|---|---|
| Functional ALV | `REUSE_ALV_GRID_DISPLAY` | 傳統寫法，舊程式主流（**本講**） |
| OO ALV | `cl_salv_table` 等 | 新程式建議，留待 OOP 課程 |

---

## 2. fieldcat：欄位目錄

「顯示哪些欄位、標題是什麼、多寬」的說明書，一欄一列：

```abap
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_fieldcat TYPE slis_fieldcat_alv.

CLEAR gs_fieldcat.
gs_fieldcat-fieldname = 'CARRID'.          " 欄位名（大寫！）
gs_fieldcat-seltext_l = '航空公司代碼'.     " 欄位標題
gs_fieldcat-outputlen = 12.                " 顯示寬度
APPEND gs_fieldcat TO gt_fieldcat.
```

| fieldcat 欄位 | 用途 |
|---|---|
| `fieldname` | **必須大寫**，打錯該欄直接不顯示 |
| `seltext_l/m/s` | 長／中／短標題 |
| `key` / `do_sum` / `no_out` | 鍵欄位／自動加總／先隱藏 |
| `currency` / `cfieldname` | 金額欄位的幣別 |

---

## 3. MACRO：把重複程式碼縮成一行

加一欄五行、十個欄位五十行 → 傳統程式用 MACRO 壓縮：

```abap
DEFINE mc_add_field.
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = &1.     " &1~&9 佔位參數
  gs_fieldcat-seltext_l = &2.
  gs_fieldcat-outputlen = &3.
  APPEND gs_fieldcat TO gt_fieldcat.
END-OF-DEFINITION.

* 呼叫：像自創指令（參數用空白隔開，不是逗號）
mc_add_field 'CARRID'   '航空公司代碼' 12.
mc_add_field 'CARRNAME' '航空公司名稱' 24.
mc_add_field 'CURRCODE' '幣別'         6.
```

---

## MACRO 的本質與紀律

本質：**編譯前的文字展開**（&n 換成實參後原地貼上）

- **不能下中斷點**，除錯單步直接跳過——出錯很難查
- 只在定義它的程式內有效，必須**先定義後使用**
- 新程式**不要寫 MACRO**（用 FORM / Method 取代）
- 但舊程式極常見（ZDQM0001F01 的 gui_download 就是）
  → **必須看得懂**

---

## 4. 呼叫 REUSE_ALV_GRID_DISPLAY

```abap
DATA gs_layout TYPE slis_layout_alv.
gs_layout-zebra             = 'X'.     " 斑馬紋
gs_layout-colwidth_optimize = 'X'.     " 欄寬自動調整

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_program = sy-repid       " 回呼程式：本程式自己
    is_layout          = gs_layout
    it_fieldcat        = gt_fieldcat
  TABLES
    t_outtab           = gt_carriers    " 要顯示的資料內表
  EXCEPTIONS
    program_error      = 1
    OTHERS             = 2.
IF sy-subrc <> 0.
  WRITE / 'ALV 顯示失敗'.
ENDIF.
```

CALL FUNCTION 完整語法與 EXCEPTIONS → 講義 15
此處先照樣板使用並檢查 sy-subrc

---

## 5. 完整流程回顧

1. SELECT 資料進內表（講義 6）
2. 建 fieldcat（手工 + MACRO，或 `REUSE_ALV_FIELDCATALOG_MERGE` 自動產生）
3. （可選）設 layout
4. CALL `REUSE_ALV_GRID_DISPLAY`，檢查 sy-subrc

> DDIC 結構可用 MERGE 自動產 fieldcat；
> 自訂結構手工建——兩種都會遇到

---

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 某欄位就是不顯示 | `fieldname` 沒大寫或拼錯（默默消失） |
| 整個 ALV 空白 | fieldcat 是空的，或 t_outtab 傳錯 |
| 金額欄小數位不對 | 沒設 `currency` / `cfieldname` |
| MACRO 呼叫報語法錯誤 | 參數用了逗號、或呼叫在定義之前 |
| 除錯進不去某段邏輯 | 那段是 MACRO——在展開前後下斷點 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex09**：

SELECT SCARR、用 MACRO 建四欄 fieldcat、
REUSE_ALV_GRID_DISPLAY 顯示

試玩排序／篩選／匯出功能
