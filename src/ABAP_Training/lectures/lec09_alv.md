# 講義 9：Functional ALV 與 MACRO

> 對應練習：[ex09](../ex09_alv.md)｜答案程式：`ZR_TR09_ALV`

## 本講重點

- ALV 是什麼、為什麼取代純 WRITE 清單
- fieldcat（欄位目錄）：告訴 ALV 每個欄位怎麼顯示
- `REUSE_ALV_GRID_DISPLAY` 的呼叫方式與常用參數
- layout 版面設定（斑馬紋、欄寬最佳化）
- MACRO（`DEFINE ... END-OF-DEFINITION`）：看得懂舊程式的必修

## 1. ALV 是什麼

ALV（ABAP List Viewer）是 SAP 標準的表格顯示元件：使用者拿到的不是死板的文字清單，而是能**自行排序、篩選、加總、調欄寬、匯出 Excel** 的互動表格——這些功能全部內建，一行都不用寫。實務報表輸出九成用 ALV。

兩種寫法：

| 寫法 | 核心 | 定位 |
|---|---|---|
| Functional ALV | `CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'` | 傳統寫法，舊程式主流（本講） |
| OO ALV | `cl_salv_table` / `cl_gui_alv_grid` | 新程式建議，留待 OOP 課程 |

## 2. fieldcat：欄位目錄

ALV 需要知道「顯示哪些欄位、標題是什麼、多寬」——這份說明書就是 fieldcat，一欄一列：

```abap
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,     " fieldcat 內表
      gs_fieldcat TYPE slis_fieldcat_alv.       " 一欄的設定

CLEAR gs_fieldcat.
gs_fieldcat-fieldname = 'CARRID'.          " 資料內表的欄位名（大寫！）
gs_fieldcat-seltext_l = '航空公司代碼'.     " 欄位標題（long）
gs_fieldcat-outputlen = 12.                " 顯示寬度
APPEND gs_fieldcat TO gt_fieldcat.
```

（`slis_...` 型別來自標準型別群組 SLIS，程式裡直接用即可。）常用欄位：

| fieldcat 欄位 | 用途 |
|---|---|
| `fieldname` | 對應資料內表的欄位名，**必須大寫**，打錯該欄直接不顯示 |
| `seltext_l` / `seltext_m` / `seltext_s` | 長／中／短欄位標題（ALV 依欄寬挑用） |
| `outputlen` | 顯示寬度 |
| `key` | `'X'` = 鍵欄位（固定不捲動、上色） |
| `do_sum` | `'X'` = 數值欄自動加總 |
| `no_out` | `'X'` = 先隱藏（使用者可自行叫出） |
| `currency` / `cfieldname` | 金額欄位的幣別（固定值／參考欄位） |

> 若資料內表直接用 DDIC 結構（如 `TYPE TABLE OF scarr`），也可以呼叫 `REUSE_ALV_FIELDCATALOG_MERGE` 自動產生 fieldcat；自訂結構則手工建——兩種都會遇到。

## 3. MACRO：把重複程式碼縮成一行

上面「加一欄」要五行，十個欄位就是五十行。傳統程式用 **MACRO** 壓縮這種重複：

```abap
DEFINE mc_add_field.
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = &1.     " &1~&9 是佔位參數，呼叫時依順序代入
  gs_fieldcat-seltext_l = &2.
  gs_fieldcat-outputlen = &3.
  APPEND gs_fieldcat TO gt_fieldcat.
END-OF-DEFINITION.

* 呼叫：像自創的指令一樣用（注意：參數用空白隔開，不是逗號）
mc_add_field 'CARRID'   '航空公司代碼' 12.
mc_add_field 'CARRNAME' '航空公司名稱' 24.
mc_add_field 'CURRCODE' '幣別'         6.
```

MACRO 的本質是**編譯前的文字展開**（把 &n 換成實參後原地貼上），因此：

- **不能下中斷點**、除錯時單步直接跳過整個 MACRO——出錯很難查。
- 只在定義它的程式內有效，必須先定義後使用。
- 新程式碼**不要寫 MACRO**（用 FORM / Method 取代），但舊程式極常見（本專案 ZDQM0001F01 的 gui_download 就是），**必須看得懂**。

## 4. 呼叫 REUSE_ALV_GRID_DISPLAY

```abap
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_program = sy-repid       " 回呼程式：本程式自己
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

- `i_callback_program` 給 `sy-repid`（目前程式名），ALV 事件回呼（如自訂頁首、雙擊）都靠它找回你的程式。
- CALL FUNCTION 的完整語法與 EXCEPTIONS 機制，講義 15 詳解；此處先照樣板使用並檢查 sy-subrc。

### 4.1 layout：整體版面

```abap
DATA gs_layout TYPE slis_layout_alv.
gs_layout-zebra             = 'X'.     " 斑馬紋（隔行底色）
gs_layout-colwidth_optimize = 'X'.     " 欄寬自動依內容調整

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_program = sy-repid
    is_layout          = gs_layout     " 多傳這個參數
    it_fieldcat        = gt_fieldcat
  TABLES
    t_outtab           = gt_carriers
  EXCEPTIONS
    program_error      = 1
    OTHERS             = 2.
```

## 5. 完整流程回顧

1. SELECT 資料進內表（講義 6）
2. 建 fieldcat（手工 + MACRO，或 MERGE 自動產生）
3. （可選）設 layout
4. CALL `REUSE_ALV_GRID_DISPLAY`，檢查 sy-subrc

## 6. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 某欄位就是不顯示 | `fieldname` 沒大寫或拼錯（不會報錯，默默消失） |
| 整個 ALV 空白 | fieldcat 是空的，或 t_outtab 傳錯內表 |
| 金額欄小數位不對 | 沒設 `currency` / `cfieldname` |
| MACRO 呼叫報語法錯誤 | 參數用了逗號（要用空白），或呼叫寫在定義之前 |
| 除錯進不去某段邏輯 | 那段是 MACRO——換成在展開前後下斷點觀察變數 |

## 7. 課堂練習

完成 [ex09](../ex09_alv.md)：SELECT SCARR，用 MACRO 建四欄 fieldcat，以 REUSE_ALV_GRID_DISPLAY 顯示，並試玩排序／篩選／匯出功能。
