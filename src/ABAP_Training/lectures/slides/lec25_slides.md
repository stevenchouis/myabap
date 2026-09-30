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

# 講義 25
# Data Dictionary 總覽與 Global Type

ABAP 基礎教育訓練（授課順序：接在講義 7 之後、講義 21 之前）

對應練習 ex25｜答案物件 `ZTR25_SURPCT`／`ZTR25_ACTIVE`／`ZTR25_SURCHG`／`ZTR25_TT_SURCHG`／`ZR_TR25_DDIC`

---

## 本講重點

- Data Dictionary（SE11）：一張物件地圖，程式與畫面共用同一份定義
- **Global Type** 回顧（觀念見講義 6）：重點在動手建自己的
- 為什麼自建 Z 表：業務需求 + SM30 讓非工程師維護
- Check Table（檢查表）／Foreign Key（外鍵）／Search Help（搜尋輔助）總覽
- **DDIC Table Type**：區域表格型別升級成全域
- 案例：SM30 維護的「航空公司旺季加成」設定表

---

<!-- _class: compact -->

## 1. Data Dictionary：一張系統地圖

| 物件 | 管什麼 |
|---|---|
| Domain | 技術屬性：型別、長度、小數位、值域清單 |
| Data Element | 語意：標籤、F1 說明、Search Help 掛勾 |
| Structure | 純欄位組合，**不對應資料庫表** |
| Table（透明表） | 對應資料庫的真實表 |
| Table Type | 「很多列」的表格型別，可跨程式共用 |
| Search Help | F4 選單來源 |
| Lock Object | 產生 ENQUEUE／DEQUEUE FM（講義 27） |

定義只寫**一次**，程式（`TYPE`）與畫面（Dynpro／SM30）**共用同一份**

---

<!-- _class: compact -->

## 1.1 View 的四種類型（SE11 → View）

| 類型 | 做什麼 | JOIN | 程式 SELECT | 標準範例 |
|---|---|---|---|---|
| **Database View** | 多表 JOIN 成一個物件 | INNER，條件自定 | ✅ | `SFLIGHTS` |
| **Projection View** | 一張表的部分欄位 | 單表 | ✅ | `DEMO_SPFLI` |
| **Maintenance View** | SM30 一次維護多張表 | INNER，沿用外鍵 | ❌ | `V_TCURC` |
| **Help View** | Search Help 的資料來源 | **OUTER**，沿用外鍵 | ❌ | `H_T005` |

- 四種都能當 `TYPE`；SELECT Maintenance／Help View 啟用直接報錯：
  `"V_TCURC" is not declared as a table, projection view, or database view`
- 新開發讀多表 → **CDS View**；Maintenance／Help View 仍常用
- 本系統傳統 View 只能用 **SE11** 建立（ADT 讀不到）
- 詳見：講義 11 §2.1（Database）、講義 21a §3（Maintenance）、§4（Help）

---

<!-- _class: compact -->

## Projection View vs 直接從表 SELECT 欄位

**讀資料效能完全一樣**：資料庫不建 View，系統轉成讀原表那幾欄

| | 直接 SELECT 欄位 | Projection View |
|---|---|---|
| 欄位清單 | 每支程式各寫一次 | SE11 定義一次，多程式共用 |
| 只有這幾欄的結構 | 自己寫 TYPES | 直接 `TYPE demo_spfli` |
| 限制只能讀 | 做不到 | Maint. Status 設 `Read only` |

- 例：`DEMO_SPFLI` 只露出 `SPFLI` 的 `CARRID`／`CONNID`／`CITYFROM`／`CITYTO`，唯讀
- **不是權限控管**：程式照樣能直接讀原表全部欄位
- 實務很少自建；主要是看懂標準系統與舊程式（新開發用 CDS View）

---

<!-- _class: compact -->

## 1.2 DDIC 內建型別 vs ABAP 內建型別

| DDIC（SE11，大寫） | ABAP（程式，講義 2） | 說明 |
|---|---|---|
| `CHAR` m／`NUMC` m | `c`／`n` LENGTH m | 字元／數字字元 |
| `INT4` | `i` | 整數 |
| `DEC` m,n | `p` LENGTH m DIV 2 + 1 DECIMALS n | **m 是數字位數，不含小數點** |
| `DATS`／`TIMS` | `d`／`t` | 日期／時間 |
| `CURR`＋`CUKY` | `p`＋`c` 5 | 金額**必須配幣別**，小數位依幣別顯示 |
| `QUAN`＋`UNIT` | `p`＋`c` | 數量**必須配單位** |
| `CLNT`／`LANG` | `c` 3／`c` 1 | Client 自動處理／文字表依語言取 |

- DDIC 型別程式不能直接寫，只能透過 Data Element、表格欄位引用
- 實測：`DEC` 5,2 → `p` 3 bytes，最大 `999.99`；`DEC` 6,2 → `p` 4 bytes，最大 `9999.99`

---

## 2. Global Type 回顧

觀念（內建型別／Local Type／Global Type 三層、判斷準則）已在**講義 6 第 1.1 節**講過

回顧最關鍵的一點：

```abap
DATA lv_matnr TYPE mara-matnr.    " 升級後自動變 40 碼
DATA lv_matnr TYPE c LENGTH 18.   " 升級後默默截斷，不報錯
```

**型別的定義權交給系統唯一來源，程式只負責「引用」**
本講重點：決定「引用現成的」還是「自己建一個」

---

## 2.2 重用標準型別 vs 自建

| 情境 | 做法 |
|---|---|
| 語意跟標準欄位完全一樣（航空公司代碼、物料號碼…） | **重用標準 Data Element** |
| 公司獨有的業務概念（自訂加成比例、審核狀態…） | **自建 Domain／Data Element** |

判斷原則：

**先搜尋標準有沒有語意相符的 Data Element**
有就重用，沒有才自建

---

## 3. 為什麼要自建 Z 表

標準系統管不到的東西：客製參數、控制開關、公司自己的對照表

- **SM30 讓不會寫程式的人也能維護資料**
- 業務人員自己改參數、加設定，不用工程師介入
- **資料**維護不需要傳輸請求，只有**表結構**變更才需要

分工：講義 21 教「怎麼建」，本講講「為什麼建、重用 vs 自建」

---

## 4. Check Table（檢查表）／Foreign Key（外鍵）／Search Help（搜尋輔助）

| 名詞 | 解決什麼問題 |
|---|---|
| Check Table | 誰是「合法值清單」，可以是**標準表**（如 SCARR） |
| Foreign Key | 畫面輸入時擋掉不合法的值（**只管畫面，不管 Open SQL**） |
| Search Help | F4 選單；欄位重用已掛好 Search Help 的標準 DE，**不用自己建** |

本講案例：Check Table 直接指向標準表 `SCARR`
欄位重用標準 Data Element `S_CARR_ID`
→ Search Help 一個都不用建


---

<!-- _class: compact -->

## SE11 會看到的相關名詞

| 英文 | 中文 | 意思 |
|---|---|---|
| Foreign Key Table | 外鍵表 | 帶外鍵欄位的表（學生表） |
| Check Table | 檢查表 | 提供合法值的表（班級表） |
| Cardinality | 基數 | 幾對幾，如 `1 : CN`（講義 21 §3.1） |
| Screen Check | 畫面檢查 | 外鍵開關，打開畫面輸入才檢查 |
| Value Table | 值表 | Domain 上的建議檢查表，建外鍵時帶出預設 |
| F4 Help／Value Help | F4 說明 | 欄位按 F4 跳出的選單 |
| Selection Method | 選取方法 | Search Help 從哪張表讀資料 |
| Search Help Parameter | 搜尋輔助參數 | 選單欄位；Import 帶條件進去、Export 帶選到的值回畫面 |
---

## 5. 程式引用 DDIC 物件的寫法

```abap
DATA gs_row  TYPE ztable.                    " 整列（work area）
DATA gv_val  TYPE ztable-field.              " 單一欄位
DATA gt_rows TYPE STANDARD TABLE OF ztable.  " 整張表

DATA gv_carrid TYPE s_carr_id.       " 直接引用 Data Element
DATA gv_carrid TYPE scarr-carrid.    " 透過表格路徑（型別相同）
```

- 變數意義跟某張表綁得緊 → `TYPE 表-欄位`
- 通用的標準概念 → 直接 `TYPE s_carr_id`

---

## 6. 案例：旺季加成設定表

情境：財務想針對特定航空公司設定「旺季加成百分比」
自己在 SM30 維護，報表讀這張表算營收試算

**6.1 自建 Domain／Data Element**（加成百分比是我們公司獨有的概念）

- Domain `ZTR25_SURPCT`（DEC，兩位小數，值域 0～100）
- Data Element `ZTR25_SURPCT`，標籤「旺季加成百分比」

---

<!-- _class: compact -->

## 6.2 第三種 Global Type 模式

`ACTIVE` 欄位若直接用 `CHAR 1`：SM30 標題顯示 `+`、沒有 F4 選單

標準已有通用是／否 **Domain `XFELD`**（`X` 是、空白 否）
標準 Data Element `XFELD` 故意不帶標籤 → 我們自建 DE **重用 Domain、補標籤**

| 模式 | 例子 | 自建什麼 |
|---|---|---|
| 整個 DE 重用 | `CARRID` 用 `S_CARR_ID` | 什麼都不用建 |
| 完全自建 | `SURCHARGE_PCT` 用 `ZTR25_SURPCT` | Domain＋DE 都自建 |
| **重用 Domain、自建標籤** | `ACTIVE` 用 `ZTR25_ACTIVE` | 只補標籤 |

遇到「是／否」旗標：先找 `XFELD` 這類通用 Domain

---

<!-- _class: compact -->

## 6.3 建立表 `ZTR25_SURCHG`

| 欄位 | Key | 型別來源 |
|---|---|---|
| MANDT | ✔ | `MANDT` |
| CARRID | ✔ | **標準 DE `S_CARR_ID`**（Key 也是外鍵） |
| ACTIVE | | `ZTR25_ACTIVE`（重用 Domain `XFELD`） |
| SURCHARGE_PCT | | `ZTR25_SURPCT`（自建） |
| UPDUSER／UPDDATE | | `SYUNAME`／`SYDATUM` |

`CARRID` 外鍵：Check Table 填標準表 **`SCARR`**，基數 `1 : C`（每家航空公司最多一筆設定），打開 Screen Check

```abap
key carrid : s_carr_id not null
  with foreign key [0..1,1] scarr
    where mandt  = ztr25_surchg.mandt
      and carrid = ztr25_surchg.carrid;
```

---

## 6.4 SM30 驗證：免費拿到三樣東西

**先在 SE80 建 Function Group `ZFG_TR25`**（TMG 要放進已存在的 FG）
再建 Table Maintenance Generator（`&NC&`、Function Group `ZFG_TR25`）
新增 `AA`／啟用／15.00、`LH`／啟用／10.00

1. `CARRID` 按 **F4**：航空公司清單直接出現（`S_CARR_ID` 早就掛好 Search Help）
2. 輸入 `ZZ`：畫面直接擋下（外鍵，Check Table 是標準表照樣有效）
3. `ACTIVE` 標題正常、F4 出現「是／否」（重用 `XFELD` 換來的）

對照講義 21：自建概念的 Search Help 要手工建
這裡重用標準 DE → **完全不用建**

---

<!-- _class: compact -->

## 6.5 程式讀取：加成營收試算

還沒學 FORM／JOIN → 三張表各自讀進內表，再 `READ TABLE` 對照

```abap
SELECT * FROM sflight INTO TABLE gt_flight WHERE seatsocc > 0.
SELECT * FROM scarr   INTO TABLE gt_scarr.
SELECT * FROM ztr25_surchg INTO TABLE gt_surchg.   " TYPE ztr25_tt_surchg

LOOP AT gt_flight INTO gs_flight.
  CLEAR gs_rev.
  gs_rev-carrid = gs_flight-carrid.   " …其他航班欄位
  READ TABLE gt_scarr INTO gs_scarr WITH KEY carrid = gs_flight-carrid.
  IF sy-subrc = 0. gs_rev-carrname = gs_scarr-carrname. ENDIF.
  READ TABLE gt_surchg INTO gs_surchg WITH KEY carrid = gs_flight-carrid.
  IF sy-subrc = 0.                    " 找不到＝沒設定，維持初始值
    gs_rev-active = gs_surchg-active.
    gs_rev-surcharge_pct = gs_surchg-surcharge_pct.
  ENDIF.
  " 計算 revenue／revenue_adj 後 APPEND gs_rev TO gt_rev
ENDLOOP.
```

沒設定的公司照樣出現 → 講義 11 用一句 `LEFT OUTER JOIN` 就能完成

---

<!-- _class: compact -->

## 6.6 DDIC Table Type：表格級的 Global Type

講義 4 的 `TYPES tt_xxx` 是 **Local Type**，只有那支程式看得到
多支程式共用同一種表格參數 → 各寫一份，改欄位要改好幾處

SE11 建 `ZTR25_TT_SURCHG`：

1. Data Type → Table Type
2. **Line Type** 直接填 `ZTR25_SURCHG`（表格本身可當 Line Type）
3. Access Mode：`Standard Table`

```abap
DATA gt_surchg TYPE ztr25_tt_surchg.
SELECT * FROM ztr25_surchg INTO TABLE gt_surchg.
```

真正的用途是當**參數型別**：講義 8 的 FORM `CHANGING`、
講義 15 的 FM 介面（**一定要** DDIC 型別，取代舊式 `TABLES`）

只有本程式用 → 就地 `TYPES`；多支程式／FM 共用 → DDIC Table Type

---

<!-- _class: compact -->

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 升級後某欄位資料被截斷 | 寫死長度，沒引用 Global Type |
| 自建 DE 才發現標準早有 | 建之前沒先搜尋標準 |
| Check Table 選了自建 Z 表，其實該指標準表 | 沒想清楚合法值清單早就存在 |
| 手動建了 Search Help，其實不用 | 重用的 DE 早就掛好 |
| 沒設定的資料整筆消失 | 找不到設定就跳過；該保留、維持初始值 |
| SM30 改資料以為要走 TR | 表**結構**才需要 TR，**資料**不用 |
| SM30 標題是 `+`、沒有 F4 | 欄位用內建型別；改「重用標準 Domain＋自建 DE 補標籤」 |
| 每支程式各宣告一份 `tt_xxx` | 該升級成 DDIC Table Type |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex25**：

自建 Domain／DE（加成百分比）＋ 表（Key 重用標準 DE、
Check Table 指標準 `SCARR`）＋ SM30 ＋ Table Type，
再寫程式驗證並完成加成營收報表
