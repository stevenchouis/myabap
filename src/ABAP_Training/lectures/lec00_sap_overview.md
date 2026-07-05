# 講義 0：SAP / ERP 背景知識——名詞與觀念建立

> 本講沒有對應練習題，目標是在寫第一行 ABAP 之前，建立整個工作環境的「地圖」：ERP 是什麼、SAP 系統長什麼樣子、團隊裡有哪些角色、ABAP 開發者站在哪個位置。

## 本講重點

- ERP 與 SAP：公司、產品、版本演進（R/3 → ECC → S/4HANA）
- 三層式架構與 SAP GUI、Client（MANDT）觀念
- 系統 Landscape：DEV / QAS / PRD 與傳輸請求（Transport Request）
- SAP 模組總覽：FI / CO / SD / MM / PP / QM…
- 團隊角色分工：Application Consultant（功能顧問）／ABAP Developer／Basis
- 標準 vs 客製：為什麼我們寫的東西都是 Z 開頭

## 1. ERP 是什麼

ERP（Enterprise Resource Planning，企業資源規劃）是把企業的**財務、銷售、採購、生產、庫存、人資**等流程整合在**同一套系統、同一份資料庫**上的軟體。整合的關鍵價值：

- **一筆交易，全流程連動**：業務接單 → 自動影響庫存預留 → 出貨 → 自動拋轉會計分錄。不用各部門各養一套系統再互相對帳。
- **即時、單一事實**：老闆看到的庫存數字跟倉庫看到的是同一筆資料。
- 代價是**流程被系統規範**：ERP 導入不只是裝軟體，更是把公司流程對齊到系統的最佳實務——這就是為什麼需要「顧問」這個行業。

SAP 是全球 ERP 市場的龍頭（德國公司，1972 年成立），大型製造業、傳產、外商幾乎都是 SAP 客戶。台灣常見的其他 ERP：Oracle、鼎新（Workflow ERP／TIPTOP）等；概念相通，但生態與技術完全不同。

## 2. SAP 產品與版本演進

| 名稱 | 年代 | 重點 |
|---|---|---|
| R/2 | 1980s | 大型主機（Mainframe）時代 |
| R/3 | 1992 | **三層式架構**成型，SAP 起飛的世代；「R/3」一詞至今仍常被老 SAP 人拿來泛稱 SAP |
| ECC（ERP Central Component） | 2004 | R/3 的後繼，目前市面上仍大量存在的版本（ECC 6.0） |
| S/4HANA | 2015 | 新世代：底層改用 SAP 自家的 **HANA** in-memory 資料庫，介面主推 **Fiori**（網頁式 UI） |

要點：

- 不管哪一代，**應用邏輯都是 ABAP 寫的**——你學的技能跨版本通用。ECC 維護（傳統語法為主）與 S/4 專案（新語法、CDS、OOP 比重高）都需要 ABAP 人。
- ECC 主流資料庫過去可以是 Oracle / SQL Server / DB2；S/4HANA **只能**跑 HANA。
- 本課程教的傳統報表技能，對應的主戰場是 ECC 與 S/4 中大量沿用的既有客製程式。

## 3. 三層式架構與 SAP GUI

SAP 系統分三層，這是理解「程式跑在哪裡」的基礎：

```
使用者端   Presentation Layer   SAP GUI / 瀏覽器(Fiori)
              ↓ 只負責畫面
伺服器     Application Layer    ABAP 程式在這裡執行（可多台 AP Server 分流）
              ↓ Open SQL
資料庫     Database Layer       所有資料集中一套 DB（HANA/Oracle/...）
```

- **SAP GUI** 是安裝在使用者電腦上的用戶端程式，只負責顯示畫面與收鍵盤滑鼠；你寫的 ABAP 全部在 Application Server 上跑。所以除錯、效能問題都發生在伺服器端，跟使用者的電腦快慢基本無關。
- **交易代碼（Transaction Code, T-code）**：SAP 功能的入口代號，在 GUI 的命令欄輸入。使用者用業務 T-code（如 `VA01` 建立銷售訂單），我們開發者常用的是工具類：

| T-code | 用途 |
|---|---|
| SE38 / SE80 | ABAP 編輯器／物件導覽 |
| SE11 / SE16N | 資料字典／看資料表內容 |
| SE37 | Function Module |
| SM30 | 維護表格資料（Table Maintenance） |
| ST22 | Dump 分析（程式當掉紀錄） |
| SM37 | 背景作業（Job）監控 |
| SPRO | 系統組態（Customizing，功能顧問的主戰場） |

- 命令欄小技巧：`/n` 結束目前畫面開新 T-code（`/nSE38`）、`/o` 開新視窗（`/oSE38`）。

## 4. Client（MANDT）觀念

同一套 SAP 系統裡可以劃分多個 **Client**（用 3 碼數字識別，如 130）：登入時要選 Client，各 Client 的**業務資料與大部分設定互相隔離**（資料表第一欄 MANDT 就是它，講義 6 會再遇到）。常見用途：同一套開發機裡，一個 Client 做組態、另一個做單元測試資料。

注意：**程式碼（Repository 物件）是跨 Client 共用的**——你在 130 改的程式，其他 Client 看到的是同一支。資料隔離、程式共用，這是初學最容易混淆的一點。

## 5. 系統 Landscape 與傳輸請求

正式環境絕不允許直接改程式。標準配置是三套系統一條龍：

```
DEV（開發機） → QAS（測試/品保機） → PRD（正式機）
   開發、單測      使用者驗收(UAT)      上線使用
```

程式與設定怎麼「搬」過去？靠 **Transport Request（傳輸請求，TR）**：

- 在 DEV 建立/修改物件時，系統要求掛在一個 TR 底下（練習用的 `$TMP` Local Object 除外——它**不會傳輸**，永遠留在本機）。
- 開發完成 → **Release（釋放）** TR → Basis 或自動排程把它 **import** 進 QAS → 測試通過再 import 進 PRD。
- TR 是稽核軌跡：誰、何時、改了什麼、搬去哪，全部有紀錄。
- 團隊紀律（本專案規範）：一個功能一個 TR、不混用；**沒有明確指示不擅自 Release**。

## 6. SAP 模組總覽

SAP 功能依業務領域切成模組（Module），這些縮寫是 SAP 圈的日常語言，必背：

| 模組 | 全名 | 管什麼 |
|---|---|---|
| FI | Financial Accounting | 財務會計：總帳、應收應付、資產 |
| CO | Controlling | 管理會計：成本中心、內部訂單、成本分析 |
| SD | Sales and Distribution | 銷售：報價、訂單、出貨、開票 |
| MM | Materials Management | 採購與庫存：請購、採購單、收貨、發票校驗 |
| PP | Production Planning | 生產計畫：BOM、工單、排程 |
| QM | Quality Management | 品質管理：檢驗批、品質通知（本專案 ZDQM 系列即 QM 周邊客製） |
| PM | Plant Maintenance | 廠務/設備維護 |
| WM / EWM | Warehouse Management | 倉儲管理（儲位層級） |
| HCM（HR） | Human Capital Management | 人資：組織、薪資、差勤 |
| PS | Project System | 專案系統：WBS、專案成本 |

模組之間高度整合：SD 出貨會動 MM 庫存、拋 FI 分錄、算 CO 成本——所以跨模組的報表需求（也就是你未來的日常）常常要 JOIN 好幾個模組的表。

技術面（非業務模組）則統稱 **BC（Basis Components）／NetWeaver**：ABAP、資料庫、系統管理都算這個領域。

## 7. 團隊角色分工

一個 SAP 專案/維運團隊的典型分工——搞清楚「誰負責什麼」，工作時才知道找誰、以及別人來找你要什麼：

| 角色 | 俗稱 | 負責 | 主要工具 |
|---|---|---|---|
| Application Consultant | 功能顧問（如 FI 顧問、SD 顧問） | 懂業務流程，用 **Customizing（SPRO 組態）** 把標準功能調成客戶要的樣子；寫功能規格（Spec）給開發 | SPRO、業務 T-code |
| ABAP Developer | 開發顧問／RD（你） | 依 Spec 開發客製：報表、介面、增強、表單 | SE38/SE80、SE37、除錯器 |
| Basis Consultant | 系統管理 | 系統安裝、效能、帳號權限、TR 搬版、資料庫與作業系統層 | SM 系列、STMS |
| Key User / End User | 使用者 | 提需求、做 UAT 驗收 | 業務 T-code |

日常協作長這樣：使用者提需求 → 功能顧問評估「標準功能能不能設定出來」→ 不能才開規格給 ABAP 開發客製 → 開發完成、顧問與使用者測試 → Basis 搬版上線。

給 ABAP 開發者的兩個提醒：

- **看得懂 Spec 的模組語言**是戰力的一半：顧問說「撈 MB51 那些資料」「BSEG 太大不要直接查」，你要接得住——模組知識會隨案子累積，第 6 節的表先混個臉熟。
- 客製類型有個常見縮寫 **RICEF**：Report（報表）、Interface（介面）、Conversion（轉檔）、Enhancement（增強）、Form（表單）。本課程主攻 R，其餘在實務中逐步接觸。

## 8. 標準 vs 客製：Z 命名空間

- **標準物件**：SAP 原廠交付的程式與資料表。原則上**不可直接修改**（升級會被覆蓋、失去原廠支援），要擴充只能走 SAP 預留的縫隙：Enhancement Point、BAdI、User-Exit（進階課題，先知道名詞）。
- **客製物件**：客戶自行開發的，一律以 **Z 或 Y 開頭**命名（SAP 保留給客戶的命名空間）——這就是課程裡所有程式都叫 `ZR_...`、資料表叫 `ZDQM...` 的原因。
- 判讀技巧：看到 Z/Y 開頭 → 這是自家寫的，出問題找開發；標準名稱 → 找顧問查設定或 SAP Note（原廠的修正/說明文件，透過 SAP Support Portal 查詢）。

## 9. 名詞速查表（遇到再回來查）

| 名詞 | 意思 |
|---|---|
| NetWeaver / ABAP Platform | SAP 的技術平台層，ABAP 執行環境的正式名稱 |
| Customizing / Configuration | 功能顧問在 SPRO 做的組態設定（不寫程式的客製） |
| IMG | Implementation Guide，SPRO 打開的那棵設定樹 |
| Dump（Short Dump） | ABAP 程式執行期錯誤中止，紀錄在 ST22 |
| Background Job | 排程在背景跑的程式（SM36 排、SM37 看） |
| BAPI | 標準提供的業務 API（本質是 RFC-enabled Function Module） |
| RFC | Remote Function Call，跨系統呼叫 FM 的協定 |
| IDoc | SAP 系統間/對外的標準電子文件格式（介面常用） |
| SAP Note | 原廠發布的修正與知識文件，有編號可查 |
| Fiori | S/4 世代的網頁式使用者介面 |
| CDS View | S/4 世代定義在資料庫層的 view（進階課題） |
| ADT / Eclipse | 新一代 ABAP 開發工具（Eclipse 外掛），與 SE80 並存 |

## 10. 課後任務（無程式作業）

1. 登入訓練系統，練習 `/n`、`/o` 切換 T-code；用 ST22 看看系統裡別人的 dump 長什麼樣。
2. 把第 6 節模組表抄一遍，找自家公司（或案子）實際用到哪些模組、各模組的顧問是誰。
3. 想一個你熟悉的業務流程（例如採購到付款），對照說出它經過哪些模組。

> 下一講（[lec00a](lec00a_gui_workbench.md)）動手準備環境：安裝 SAP GUI、登入系統、導覽 ABAP Workbench。
