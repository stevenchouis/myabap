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

# 講義 21
# 建立 Z 資料表與 Open SQL 寫入

ABAP 基礎教育訓練（授課順序：接在講義 25 之後、講義 8a 之前）

對應練習 ex21｜答案：表 `ZTR21_STUD` + `ZTR21_CLASS`、Search Help `ZTR21_CLASSH`、SM30 維護畫面＋程式 `ZR_TR21_ZTABLE`

---

## 本講重點

- DDIC 三層件：Domain → Data Element → 表格欄位
- SE11 建立透明表：鍵欄位、Delivery Class、Technical Settings
- **Header／Detail 兩表關聯**：外鍵（Foreign Key）與檢查表（Check Table）
- **Search Help**：F4 值清單怎麼來的，跟外鍵的差別
- SM30 維護畫面：在畫面上驗證值域、外鍵、F4
- Open SQL 寫入：`INSERT` / `UPDATE` / `MODIFY` / `DELETE`
- LUW 與 `COMMIT WORK` / `ROLLBACK WORK`

Maintenance View、Help View、JOIN 串表 → **講義 21a**（要先學 JOIN）

---

## 1. DDIC 三層件

| 層 | 管什麼 | 例 |
|---|---|---|
| **Domain** | **技術屬性**：型別、長度、值域、轉換常式 | INT4、值域 0～999 |
| **Data Element** | **語意**：欄位標籤、F1 說明（多語言） | 「學生成績」 |
| 表格欄位 | 引用 DE（或直接用內建型別） | `SCORE TYPE ztr21_score` |

為什麼分三層？**重複利用與一致性**：
十張表共用同一個 DE → 標籤、F1、值域全系統一致，改一處全生效
（`TYPE scarr-carrid` 帶出那麼多語意的原因——講義 6）

實務折衷：鍵欄位與業務欄位用 DE；
純技術欄位（旗標、備註）直接用內建型別省事

---

## 2. SE11 建立透明表

1. SE11 → Database table → `ZTR21_STUD` → Create
2. **Delivery Class**：`A`（應用資料，預設選它）
   `C` = Customizing 設定檔（跟著 TR 搬）、`L` = 暫存
3. Data Browser/Table View Maint.：`Display/Maintenance Allowed`
4. **Fields**：第一欄一定是 `MANDT TYPE mandt` 且勾 **Key**
   接著鍵欄位、資料欄位
5. **Technical Settings**（必填才能啟用）：
   Data Class `APPL0`、Size Category `0`
6. 啟用——表就真的建在資料庫了，SE16N 可立刻查

> 表建錯欄位型別，上線後要改很痛（要轉檔）
> **設計階段多想一分鐘**

---

<!-- _class: compact -->

## 2.1 Key：主鍵（Primary Key）

勾起來的欄位合起來**唯一識別一筆資料**，不會有兩筆主鍵相同

| 表 | 主鍵 |
|---|---|
| `ZTR21_STUD` | `MANDT`＋`ID` |
| `ZFI0037` | `MANDT`＋`BUKRS`＋`INAUGURATION`（換主管新增一筆生效日） |
| `MAKT` | `MANDT`＋`MATNR`＋`SPRAS` |

- 第一個是 `MANDT`；Key 欄位**連續排在最前面**；最多 16 個、總長 ≤ 900 bytes
- `INSERT` 重複主鍵 → `sy-subrc = 4`；`MODIFY` 靠主鍵決定新增或更新
- 系統自動建主索引：`WHERE` 給 Key 欄位讀取很快
- 有資料後再改 Key 要轉資料 → 建表時想清楚

---

<!-- _class: compact -->

## 2.1 Initial Values（DDL 的 `not null`）

Fields 頁籤 Key 右邊的勾選框：資料庫欄位能不能是 **NULL**

| 勾選 | 沒給值時 |
|---|---|
| 有勾 | `NOT NULL`，填初始值（空白、`0`、`00000000`） |
| 沒勾 | 可能是 NULL（完全沒有值） |

- NULL ≠ 空白：`WHERE f = space` 找不到 NULL，要用 `IS NULL`
- 勾了 Key，Initial Values 會自動跟著勾；新建表差別不大
- **舊表加新欄位時才關鍵**：沒勾，舊資料可能是 NULL；有勾會回填初始值（大表很慢）

---

<!-- _class: compact -->

## 2.2 金額要配幣別、數量要配單位

| 欄位型別 | 必須參考 | 小數位由誰決定 |
|---|---|---|
| `CURR`（金額） | `CUKY`（幣別） | `TCURX-CURRDEC`，不在表裡預設 2 位 |
| `QUAN`（數量） | `UNIT`（單位） | `T006-DECAN`，只去掉多出來的 0 |

同樣存 `100.00`：`USD` → `100.00`、`JPY`／`TWD`（本系統 0 位）→ `10,000`、`KWD` → `10.000`
SM30／畫面會自動依參考欄位顯示；**程式 `WRITE` 要自己加 `CURRENCY`／`UNIT`**

沒指定 → 啟用報 `specify reference table AND reference field`

SE11：**Currency/Quantity Fields** 頁籤填 **Reference table**（幣別／單位在哪張表）＋ **Ref. field**（哪個欄位）
參考表可以是別張表：`MARC-MINBE` → `MARA-MEINS`（基本單位）、`MARC-LOSFX` → `T001-WAERS`（公司幣別）；值要程式自己讀進來

```abap
@Semantics.amount.currencyCode : 'sbook.forcurkey'   " SBOOK 範例
forcuram  : s_f_cur_pr not null;
forcurkey : s_curr not null;
```

---

## 3. Header／Detail 關聯：外鍵與 Check Table

訂單－客戶、明細－產品……本質都是 **Header（1）／Detail（多）** 關聯
本課示範：班級（Header）－學生（Detail），跟講義 6 的 SCARR－SPFLI 同一種關係

- **Check Table**：被參考的表（`ZTR21_CLASS`），扮演「合法值清單」
- **外鍵表**：帶外鍵欄位的表（`ZTR21_STUD.KLASSE`），值必須存在於 Check Table

```abap
klasse : ztr21_klasse
  with foreign key [0..*,1] ztr21_class
    where mandt  = ztr21_stud.mandt
      and klasse = ztr21_stud.klasse;
```

`[0..*,1]`：多筆學生（外鍵表）對應 1 筆班級（檢查表）

---

<!-- _class: compact -->

## 基數（Cardinality）：幾對幾

SE11 填 **`n : m`**：

| 位置 | 問題 | 值 |
|---|---|---|
| 左 `n`（檢查表側） | 外鍵表每一筆，對到檢查表幾筆？ | `1` 剛好一筆／`C` 最多一筆 |
| 右 `m`（外鍵表側） | 檢查表每一筆，對到外鍵表幾筆？ | `1`／`C`／`N` 至少一筆／`CN` 任意 |

- 學生 → 班級：每個學生一個班級、每班任意多人 → **`1 : CN`**（DDL `[0..*,1]`）
- 加成設定 → `SCARR`：每家航空公司最多一筆 → **`1 : C`**（DDL `[0..1,1]`）
- DDL 順序相反：`[外鍵表側, 檢查表側]`
- 主要是文件用途；建 Maintenance View／Help View 時系統會看它

---

<!-- _class: compact -->

## 外鍵欄位類型（Foreign key field type）

外鍵欄位在自己這張表裡是不是主鍵：

| 選項 | 意思 | 例 |
|---|---|---|
| Not Specified | 不說明 | － |
| Non-key fields/candidates | 不是外鍵表的主鍵 | 學生表 `KLASSE` |
| Key fields/candidates | 是外鍵表主鍵的一部分 | `MARC-WERKS`、明細表 `ORDNO` |
| Key fields of a text table | 外鍵表是檢查表的**文字表** | `MAKT-MATNR`、`T005T-LAND1` |

- 前兩種只是文件用途
- **Text table 會改變行為**：F4 自動帶說明、依登入語言取文字；需同主鍵＋一個 `LANG` 欄位

---

<!-- _class: compact -->

## 文字表實例：`MARA`（物料）與 `MAKT`（物料說明）

| 表 | 主鍵 | 資料 |
|---|---|---|
| `MARA` | `MANDT`＋`MATNR` | 一個物料一筆 |
| `MAKT` | `MANDT`＋`MATNR`＋**`SPRAS`** | 一個物料、每種語言各一筆 |

- 說明要多語言，所以另外放一張表；外鍵 `MAKT-MATNR` → `MARA`，**Key fields of a text table**，`1 : CN`
- 系統：F4 自動帶登入語言的說明；Maintenance View 自動取登入語言

```abap
SELECT SINGLE maktx FROM makt INTO gv_maktx
  WHERE matnr = gv_matnr
    AND spras = sy-langu.     " 少了這行會讀到好幾種語言
```

---

<!-- _class: compact -->

## 外鍵只擋畫面，不擋程式！

`@AbapCatalog.foreignKey.screenCheck : true` **只影響 Dynpro 畫面**（SM30、Module Pool）

> **Open SQL 的 INSERT/UPDATE/MODIFY 完全不受外鍵約束**
> 程式塞一個 Check Table 沒有的班級代碼一樣 `sy-subrc = 0`

跟一般資料庫的 Foreign Key Constraint 不一樣：
那是資料庫引擎強制擋寫入；SAP DDIC 外鍵是**應用層／畫面層**機制

要在程式擋，得自己 `SELECT SINGLE` 檢查 Check Table

第 4 節在 SM30 實測「畫面會擋」

---

## Search Help：F4 選單哪裡來的

跟外鍵是兩件事：外鍵「擋不合法的值」、Search Help「幫你選合法的值」

- 只設外鍵沒設 Search Help：會擋錯，但沒 F4，要背代碼
- 只設 Search Help 沒設外鍵：F4 能選，但手動打錯的畫面不會擋

建立（SE11 → Search Help → Elementary Search Help）：
- **Selection Method**：資料來源表（`ZTR21_CLASS`）
- **Parameters**：`KLASSE`（Import+Export+SH field）、`KLNAME`（純顯示，僅 Export）
- 建好要**掛到 Data Element**（`ZTR21_KLASSE` → Search Help 欄位）才會全面生效

測 F4：SM30 按 F4，或 `PARAMETERS p_klasse TYPE ztr21_klasse.`

> **Parameter 欄位必須有 Data Element**！`KLNAME` 若只用內建型別會 Activate 失敗

---

## 4. SM30 維護畫面

讓使用者不寫程式就能維護表內容：

1. **先在 SE80 建 Function Group `ZFG_TR21`**（TMG 只能放進已存在的 FG；講義 25 練習建過 `ZFG_TR25`）
2. SE11 該表 → Utilities → **Table Maintenance Generator**
3. Authorization Group 練習用 `&NC&`（不檢核）
   Function Group `ZFG_TR21`（畫面程式的容器）
   Maintenance type：one step（單畫面）
4. 產生後 → SM30 輸入表名 → Maintain
   → 現成的新增/修改/刪除畫面

實務上參數表、對照表幾乎都配 SM30

---

## 在 SM30 驗證 DDIC 設定

| SE11 的設定 | 在 SM30 的效果 |
|---|---|
| Domain 值域 0～999 | 成績輸入 1000 被擋 |
| Data Element 欄位標籤 | 欄位標題顯示「學生成績」「班級代碼」 |
| `KLASSE` 外鍵＋Screen Check | 輸入不存在的班級，離開欄位就報錯 |
| Search Help 掛在 DE | 班級欄 F4 帶出清單 |

> 同樣是「班級不存在」：程式 `INSERT` 成功、SM30 輸入被擋
> → 外鍵只擋畫面、不擋 Open SQL

---

## 5. Open SQL 寫入四指令

全部**用 sy-subrc 回報結果**；`sy-dbcnt` 是影響筆數：

```abap
DATA gs_stud TYPE ztr21_stud.    " 表名直接當結構型別

* INSERT：新增；主鍵已存在 → sy-subrc = 4，不會蓋掉
INSERT ztr21_stud FROM gs_stud.

* UPDATE：改既有資料；找不到 → sy-subrc = 4
UPDATE ztr21_stud SET score = 90 WHERE id = 'S0001'.

* MODIFY：有就改、沒有就新增（upsert）——參數表最愛
MODIFY ztr21_stud FROM gs_stud.

* DELETE：刪除
DELETE FROM ztr21_stud WHERE id = 'S0001'.
```

---

## 批次寫入與兩個習慣

多筆版本：`INSERT ztr21_stud FROM TABLE gt_stud.`

> **INSERT FROM TABLE 遇任一筆主鍵重複就整批 dump**
> 除非加 `ACCEPTING DUPLICATE KEYS`（重複跳過、subrc = 4）

兩個習慣：

- MANDT 一樣**不要**自己塞——系統自動帶當前 client
- 寫入帶齊**稽核欄**（`sy-uname` 異動者、`sy-datum` 異動日）
  查問題時會感謝自己

---

## 6. LUW 與 COMMIT WORK

變更以 **LUW**（Logical Unit of Work）為單位，確認才落地：

```abap
INSERT ztr21_stud FROM gs_stud.
IF sy-subrc <> 0.
  ROLLBACK WORK.       " 整包撤銷：LUW 內所有寫入取消
  WRITE / '寫入失敗，已回復'.  " 正式程式用 MESSAGE（講義 10、22）
  RETURN.
ENDIF.
COMMIT WORK.           " 整包確認：全部永久生效
```

- 表頭＋明細必須「**全成功或全失敗**」——LUW 的意義
- 程式跑完系統會隱含 commit（練習沒寫也多半進去了）
  但**正式程式的寫入要明確 COMMIT／ROLLBACK**
- 多人同改一筆 → **Lock Object**（ENQUEUE/DEQUEUE）
  先認識名詞，實作在講義 27

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 表啟用不了 | Technical Settings 沒填；或金額／數量欄位沒指定參考欄位 |
| SE16N 看不到剛寫的資料 | sy-subrc 其實是 4；或在別的 client 查 |
| INSERT 一直 subrc = 4 | 主鍵重複——重跑前先清舊測試資料 |
| INSERT FROM TABLE 直接 dump | 沒加 ACCEPTING DUPLICATE KEYS |
| 自己塞 MANDT | 不用，系統自動處理 |
| 以為外鍵能擋程式寫入的髒資料 | 外鍵只管畫面輸入，Open SQL 不受影響 |
| SM30 說表不能維護 | 建表時維護選項不允許、或沒產畫面 |
| SM30 輸入不存在的班級沒被擋 | 外鍵沒開 Screen Check |
| Search Help Activate 失敗 | Selection Method 表的欄位沒引用 Data Element |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex21**：

建 Domain＋Data Element＋透明表 `ZTR21_STUD`＋班級主檔 `ZTR21_CLASS`
`KLASSE` 欄位設外鍵＋Search Help，產 SM30 維護畫面驗證值域／外鍵／F4

寫程式跑完 INSERT / UPDATE / MODIFY / DELETE
＋外鍵行為驗證，全流程並驗證 sy-subrc
