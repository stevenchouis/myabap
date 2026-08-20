# SAP ABAP CDS View 課程

RAP 課程（`src/ABAP_Training_RAP/`，rap01–rap09）之後開的新課，2026-08-17 定案，2026-08-18 課綱確認、開課前查證完成，同日出題開始（cds01 已完成）。

## 開課前查證（2026-08-18）

進階篇三個主題（Custom Entity／Value Help／Hierarchy）出題前先在系統上驗證可行性，避免重蹈 RAP 課程「先假設可行、寫完講義才發現是 GUI-only」的覆轍：

- **✅ Custom Entity**：`define custom entity <name> { ... }` 語法在這系統完全可以編譯／啟用（用暫時性驗證物件 `ZI_CDSPROBE_CE` 測試，只有「Provider Class 還沒建」這種預期中的警告，不是錯誤）。
- **✅ Value Help Annotation**：`@Consumption.valueHelpDefinition` 是純 CDS Annotation（指向另一個 CDS View 當作值清單來源），跟 RAP 課程第 10 節記載的「Classic Search Help（SHLP）GUI-only」完全是兩回事，不會踩到那個限制（用 `ZI_CDSPROBE_VH` 測試，引用標準 `I_Country`，啟用成功）。
- **✅ Hierarchy CDS View**：不是靠自己建測試物件驗證，是直接讀這系統既有標準物件 `I_GLAccountHierarchyNode`（`adtcore:version="active"`，真的在跑），確認 `@ObjectModel: { dataCategory: #HIERARCHY }` ＋ `@hierarchy.parentChild: { recurse: { parent:..., child:... }, siblingsOrder:{...}, directory:... }` 這套語法在這系統上是有效、生產環境正在使用的寫法，可以直接照抄這個標準物件的結構出題。

三個主題全部確認可行，**已加入正式課綱**（Hierarchy 新增為 cds16），課綱總題數確認為 **16 題**（基礎篇 8 題＋進階篇 8 題）。

## 為什麼要開這門課

RAP 課程的 rap02 已經教過一部分 CDS View 基礎（Eclipse 建立步驟、DDL 語法、Association vs. Join、內建函數、Parameters/Session Variables），但那是「為了銜接 BDEF」的精簡版，不是完整的 CDS View 技能樹。從 Code-to-Data 的角度看，**CDS View 本身（不只是 RAP 的地基）就是 ABAPER 的核心技能**——分析型報表、Fiori Elements 畫面、甚至一般 Open SQL 查詢的效能，很大程度取決於 CDS View 設計得好不好。這門課要把 CDS View 獨立出來，從零開始教一次完整體系，並補上 rap02／AMDP 課程都沒碰過的進階主題。

**跟既有課程的關係與分工**：
- **rap02**：保留原樣，定位是「能看懂/建立一個給 BDEF 用的 CDS Interface View」的最小必要知識，不用回頭修改
- **AMDP 課程**：教的是 CDS **Table Function**（AMDP 包裝成 CDS 物件），不是本課程要教的一般 CDS View（`define view`），兩者互補、不重疊
- **本課程**：CDS View 本身的完整體系——語法基礎（有些跟 rap02 重疊，但講解更完整、練習更多）＋ rap02／AMDP 都沒教過的進階主題（Extend View、Custom Entity、Analytical Annotation、Virtual Element、Value Help 等）

## 課程定位

- **對象**：完成基礎 ABAP Training（ex01–ex28）的學員即可入門；不要求先修 RAP／AMDP 課程（進階篇部分主題會提到 RAP/AMDP 的關聯，但不要求動手做過那兩門課）
- **系統環境限制（已由 RAP 課程查證，直接沿用）**：這個系統（On-Premise S/4HANA 1909）的 CDS 編譯器**不支援 `define view entity`（新式 View Entity 語法）**，一律要用舊式 `define view`／`define root view`（無 `entity` 關鍵字）。這是目前 SAP 官方教材／認證預設使用的語法，本系統用不了，會在 cds01 開頭完整說明，之後每一課遇到都會提醒。
- **結業標準（草案）**：能獨立設計一組多層 CDS View（Basic/Interface View → Composite/Consumption View）取代直接寫 Open SQL 查表；能判斷什麼時候該用 Association、什麼時候該轉成實際 JOIN；能讀懂並修改標準 CDS View 的 Annotation（不誤觸只在特定情境生效的地雷，如 `@AbapCatalog.preserveKey`）；能設計一個 Analytical 用途的 CDS View（含聚合／維度／量值標記）；知道 Extend View／Custom Entity／Virtual Element 各自的適用情境與限制

## 教材慣例（比照 RAP/AMDP 課程）

- 每題三件套：題目 `cdsNN_主題.md` + PDF 講義（`node tools/md2pdf.js src/ABAP_Training_CDS`）+ 答案快照
- 每題 md 開頭（`## 學習目標` 之前）要有 `## Lecture` 完整背景知識講解
- **範例前一律先分段講解語法**（RAP 課程 2026-08-03 定案的寫作慣例，本課程沿用）：先條列講解會用到的語法元素/關鍵字，再給完整範例
- **每一課都要有「Eclipse ADT 建立/修改這課主要物件」Step by Step ＋ 動手練習**（RAP 課程 2026-08-03 定案的慣例，本課程沿用）；CDS View／DDLX 這類物件 Claude 可以用 ADT API 直接建立驗證語法，但仍要出一題讓學員自己在 Eclipse 動手做一次
- 答案物件命名：CDS View 沿用 RAP 課程的分類慣例——`ZI_CDSnn_*`（Interface View）／`ZC_CDSnn_*`（Consumption/Composite View）／`ZR_CDSnn_*`（分析用 Query View，若該課用得到）；Metadata Extension 跟 CDS View 同名不同型別（`DDLX/EX`）；驗證程式 `ZR_CDSnn_DEMO`，套件 `$TMP`
- 資料模型：優先沿用 SCARR/SFLIGHT/SBOOK 航班模型（跟 OOP/REST/AMDP 一致），除非某課主題需要換模型才特別造資料（例如 Hierarchy 需要自遞迴結構）

## 課綱（已確認，共 16 題，待逐題出題）

### 基礎篇：從零開始的 CDS View 完整體系

| # | 主題 | 內容重點 | 狀態 |
|---|---|---|---|
| cds01 | CDS View 是什麼、為什麼要用 | Open SQL 直接查表 vs. CDS View 的差異（語意豐富化、可重用、下推執行）；這系統的 `define view`（無 `entity`）語法限制說明＋新舊語法差異完整對照；Eclipse ADT 建立 CDS View Step by Step；最基本的 `@AbapCatalog.sqlViewName`／`@AccessControl.authorizationCheck`／`@EndUserText.label` annotation；SE11/SE16 驗證查詢結果 |✅ 已完成並驗收（2026-08-18/20，`ZI_CDS01_CARRIER`＋`ZR_CDS01_DEMO`，`programrun` 驗證通過；SE16 一段是推論尚未經使用者實測確認）|
| cds02 | 欄位選取與運算 | 別名（`as`）、算術運算（含這系統實測「除法只允許浮點數」的限制）、字串/日期內建函數、`CASE WHEN`（含這系統實測「條件不能用運算式/函數/同層別名」的限制）、常數欄位、`CAST` |✅ 已完成（2026-08-20，`ZI_CDS02_FLIGHT`＋`ZR_CDS02_DEMO`，`programrun` 驗證通過）|
| cds03 | Association vs. JOIN | `association [cardinality] to <目標> as _別名 on ...`；path expression 何時才會真的轉成 SQL JOIN（只有被引用才轉譯，本課用三個 View 兩兩對照實測證明）；跟直接寫 JOIN 的差異與取捨 |✅ 已完成（2026-08-20，`ZI_CDS03_FLIGHT_SCHEDULE`／`ZC_CDS03_FLIGHT_WITH_CARRIER`／`ZI_CDS03_FLIGHT_JOIN`＋`ZR_CDS03_DEMO`，`programrun` 驗證通過）|
| cds04 | Parameters 與 Session Variables | `with parameters` 語法、`$parameters.<name>`；內建 Session Variable（`$session.user`/`system_date` 等，含這系統實測「當函數參數用要先 CAST」的限制）；動態篩選的應用場景 |✅ 已完成（2026-08-20，`ZI_CDS04_FLIGHT`＋`ZR_CDS04_DEMO`，`programrun` 驗證通過）|
| cds05 | CDS View 分層設計：Interface View → Composite View | View 命名分類慣例（I_/C_/P_/R_）；為什麼要分層（重用、單一職責，並實戰示範第三個好處：繞過 cds02 發現的「CASE WHEN 不能引用同層別名」限制）；疊層傳參數用冒號語法（跟 Open SQL 等號語法對照）；澄清「Foreign Key」是 DDIC 建表語法非 CDS View 語法 |✅ 已完成（2026-08-20，`ZI_CDS05_FLIGHT`＋`ZC_CDS05_FLIGHT_REPORT`＋`ZR_CDS05_DEMO`，`programrun` 驗證通過）|
| cds06 | CDS Access Control | `define role` 語法（含這系統實測「一定要加 `@MappingRole: true`」的限制）、`@AccessControl.authorizationCheck` 的合法值與差異（`#CHECK`/`#NOT_REQUIRED`/`#PRIVILEGED_ONLY`）、跟 `AUTHORITY-CHECK` 的分工 |✅ 已完成（2026-08-20，`ZI_CDS06_FLIGHT`(DDLS)＋`ZI_CDS06_FLIGHT`(DCLS)＋`ZR_CDS06_DEMO`，`programrun` 驗證通過）|
| cds07 | 聚合與分組 | CDS 內的 `SUM`/`AVG`/`COUNT`/`GROUP BY`，搭配 `@DefaultAggregation` 初探；跟應用層聚合（Open SQL 撈明細再迴圈算）的效能對比 |✅ 已完成（2026-08-20，`ZI_CDS07_FLIGHT`＋`ZC_CDS07_ROUTE_STATS`＋`ZR_CDS07_DEMO`，`programrun` 驗證通過）|
| cds08（期中整合） | 綜合實作 | 用 cds01~cds07 教過的技巧疊一個「航線營收分析」多層 CDS View，取代一支既有的 Open SQL 報表程式，並比較兩者可讀性/維護性 |✅ 已完成（2026-08-20，三層 View＋`ZR_CDS08_LEGACY_REPORT`＋`ZR_CDS08_DEMO`，兩種寫法逐筆數字比對一致）|

### 進階篇：CDS View 深化主題

| # | 主題 | 內容重點 | 狀態 |
|---|---|---|---|
| cds09 | Extend View | `extend view <既有 View> with { ... }`：不修改原始碼、幫既有 CDS View 加欄位；跟 DDIC Append Structure／Customer Include 的類比與差異；實測發現不需要 `@Metadata.allowExtensions`（跟 Metadata Extension 的規則不同） |✅ 已完成（2026-08-20，`ZC_CDS09_CARRIER_EXT`＋`ZR_CDS09_DEMO`）|
| cds10 | Custom Entity | 資料來源不是 DB Table 時的 CDS 建模方式；`define custom entity`、`IF_RAP_QUERY_PROVIDER` Query Provider 類別；實測發現純 Open SQL 完全無法查詢 Custom Entity（編譯期錯誤），發明 Mock Request/Response 直接呼叫類別驗證邏輯的技巧 |✅ 已完成（2026-08-20，`ZCL_CDS10_STATUS_QUERY`＋`ZI_CDS10_FLEET_STATUS`＋`ZR_CDS10_DEMO`）|
| cds11 | Analytical Annotation 深入 | `@Analytics.query`／`@Analytics.dimension`／`@Analytics.measure`／`@Semantics.amount.currencyCode`；實測發現聚合函數參數不能是運算式（跟 cds02 CASE WHEN 限制同一類，靠 cds05 分層技巧解決） |✅ 已完成（2026-08-20，`ZI_CDS11_FLIGHT_REVENUE`＋`ZC_CDS11_ROUTE_ANALYTICS`＋`ZR_CDS11_DEMO`，數字與 cds08 交叉驗證一致）|
| cds12 | Virtual Element | `@ObjectModel.virtualElementCalculatedBy`＋Exit Class（`IF_SADL_EXIT_CALC_ELEMENT_READ`，這系統用舊式 SADL 機制非新式 RAP Projection View）；實測發現跟 Custom Entity 同一模式：純 Open SQL 不觸發 Exit Class | ✅ 已完成（2026-08-20，`ZCL_CDS12_DAYS_CALC`＋`ZI_CDS12_FLIGHT_VIRTUAL`＋`ZR_CDS12_DEMO`）|
| cds13 | Value Help Annotation | `@Consumption.valueHelpDefinition`、`@ObjectModel.text.association`；重用 cds01 的 `ZI_CDS01_CARRIER` 當 Value Help 來源，確認純中繼資料不影響查詢行為 |✅ 已完成（2026-08-20，`ZI_CDS13_FLIGHT_VH`＋`ZR_CDS13_DEMO`）|
| cds14 | Hierarchy CDS View | `@ObjectModel: { dataCategory: #HIERARCHY }`＋`@hierarchy.parentChild`，照抄標準物件 `I_GLAccountHierarchyNode`；新建自我參照表 `ZTCDS14_ORGUNIT`；誠實記錄 Open SQL `HIERARCHY_DESCENDANTS()` 巡覽語法六種嘗試皆失敗，樹狀呈現留給 Eclipse Data Preview 驗證 |✅ 已完成（2026-08-20，`ZTCDS14_ORGUNIT`＋`ZI_CDS14_ORGUNIT_HIER`＋`ZR_CDS14_SETUP`＋`ZR_CDS14_DEMO`）|
| cds15 | 效能與除錯 | `GET RUN TIME FIELD` 量測技巧；確認無 Explain Plan 工具；量到反直覺結果（小資料量下 CDS 聚合比手動迴圈慢）＋符合直覺結果（消費 Association 較慢）；整理 cds01~14 累積的效能地雷清單 |✅ 已完成（2026-08-20，`ZR_CDS15_DEMO`，重用 cds03/cds07 既有物件）|
| cds16（期末整合） | 綜合實作 | 整合 Analytical Annotation＋Virtual Element＋Value Help＋Hierarchy，設計一個能直接被 Fiori Elements／分析工具消費的完整 CDS View（呼應 RAP 課程 `@UI.*` 但這裡聚焦資料建模而非 Behavior） |✅ 已完成（2026-08-20，`ZI_CDS16_ORGUNIT_FINAL`＋`ZCL_CDS16_LABEL_CALC`＋`ZR_CDS16_DEMO`，四種技巧一次啟用成功無衝突）|

## 出題工作流程（比照 RAP/AMDP 課程）

Claude 用 ADT API 建立 CDS View／Metadata Extension 驗證語法可行 → 使用者依講義在 Eclipse 動手做一次（cds01 起套用 RAP 課程「教學分工原則」，物件複雜度夠高時改由使用者建立、Claude 驗證）→ 語法檢查＋啟用 → `programrun`／`sap_sql_query`/`datapreview` 驗證資料正確 → 使用者驗收 → 快照 → 題目 md → `node tools/md2pdf.js src/ABAP_Training_CDS` 產 PDF → 更新本 README 狀態 → commit。每批 2–3 題、使用者驗收後再繼續。

## 已確認事項（2026-08-18）

- 課綱總題數確認為 **16 題**（基礎篇 8 題＋進階篇 8 題），維持完整份量，不合併
- cds10（Custom Entity）、cds13（Value Help）已查證可行，不受 GUI-only 限制影響
- Hierarchy CDS View 已加入課綱（cds14），並確認系統既有標準物件可直接參照出題

課綱定案，開始出題。

**cds01 已完成（2026-08-18）**：`ZI_CDS01_CARRIER`（基於 `SCARR` 的最基本 CDS Interface View）＋ `ZR_CDS01_DEMO`（驗證程式，Open SQL 直查表 vs. 查 CDS View 筆數比對）已建立、啟用、`programrun` 驗證通過。動手練習（基於 `SPFLI` 的基本 CDS View）留給使用者在 Eclipse 建立，尚待使用者實際操作＋驗收；講義裡的 SE16 驗證段落是根據 SE11 已驗證規則的推論，尚未經使用者實測確認，需要使用者回報實際畫面。cds01 已於 cds02 開課前驗收通過。

## 環境決策（2026-08-20 確認）：課程主體維持地端 S4H，不切換 BTP Cloud

cds02 開課前，使用者提出：目前專案除了地端 S4H（1909），也已經有一個 BTP ABAP Cloud Trial（RAP Cloud／Fiori Elements 課程用的環境），新版 CDS 語法（`define view entity`／`strict`）在那裡才支援，想確認這門課要鎖定哪個環境。討論後決定**維持地端 S4H，不切換**，理由：

- **語法差異比想像中小**：這門課規劃的 16 題（欄位運算、Association、Parameters、分層設計、權限、聚合、Extend View、Custom Entity、Analytics、Virtual Element、Value Help、Hierarchy）幾乎全部是 CDS DDL 表達式語言／Annotation 框架本身的能力，跟 `entity` 關鍵字無關——地端既有標準物件 `C_SalesOrderManage` 用**舊語法**就寫出了 Composition，證實 Association/Composition 機制新舊語法完全通用。真正會因新舊語法而寫法不同的，只有 `@AbapCatalog.sqlViewName`（舊語法強制要指定一個 ≤16 碼的底層 SQL View 名稱，新語法不需要）跟 `@AbapCatalog.preserveKey: true`（舊語法 Root View 需要這個 annotation，新語法鍵值語意是語言原生保證的）這兩個「包裝層」annotation，`strict`／`redirected to` 這類差異則主要屬於 RAP／BDEF 銜接範疇，不是 CDS View 建模本身的差異。
- **BTP Cloud Trial 的操作成本明顯更高**：物件建立功能整個故障（`CREATION_FAILED`，`abap-remote-fs` MCP 工具跟 VS Code 原生一樣），16 題全部要使用者先手動在 Eclipse 建空殼 Claude 才能接手；是公開／多人共用的社群 Trial（套件命名要防碰撞、資料有被重置風險）；資料模型是 `/DMO/*`，跟本專案其他課程（OOP/REST/AMDP/RAP）沿用的 SCARR/SFLIGHT/SBOOK 不一致（詳見 [[cloud-rap-exploration]]）。
- **沿用本專案既有先例**：RAP 課程（rap01~09，地端舊語法）結案後才**另開一門 RAP Cloud（rc01~08）**在 BTP 上重講新語法，不是把 RAP 課程整個搬過去重寫。cds01 目前的寫法（在地端建立，內文明確標注語法限制）正是同一個模式的起手式，之後如果真的需要，可以比照這個先例另開「CDS Cloud」對照課，不需要現在就切換。

**已落實**：cds01 補充了新舊語法差異的完整對照說明（見 `cds01_what_is_cds.md` 的「新舊語法差異對照」段落），確立本課程的一貫立場——之後每一課只要教到會受新舊語法影響的內容（目前只知道 `sqlViewName`／`preserveKey` 這兩處），會用同樣格式標注對照，其餘內容不特別重複提醒（因為差異不存在）。

## cds02～cds03 已完成（2026-08-20）

- **cds02**（欄位選取與運算）：`ZI_CDS02_FLIGHT`（基於 `SFLIGHT`，含別名／算術運算／CAST／字串函數／日期函數／CASE WHEN／常數欄位）＋ `ZR_CDS02_DEMO` 已建立、啟用、`programrun` 驗證通過。過程中實測發現兩個這系統獨有的真實限制，已寫入講義：① 除法運算子 `/` 只允許浮點數型別（`abap.decfloat34`），整數/定點小數欄位要先 `CAST` 才能相除，直接對整數欄位除法會報 `Division x/y is only allowed for float numbers`；② `CASE WHEN` 判斷條件完全不支援運算式（`Unexpected word "*"` / `"/"`）跟函數呼叫（含 CDS 內建函數，`User-defined functions are not supported in the SEARCHED CASE WHEN clause`），也不能引用同一句 SELECT 清單裡其他欄位的別名（`The column XXX is unknown`）——只能寫純欄位／常數比較，這一課已據此設計了合規的 `OccupancyStatus` 分類邏輯，並在講義裡完整記錄四種錯誤嘗試的除錯過程。
- **cds03**（Association vs. JOIN）：`ZI_CDS03_FLIGHT_SCHEDULE`（宣告 `_Carrier` Association 但不消費）／`ZC_CDS03_FLIGHT_WITH_CARRIER`（消費 Association，觸發 JOIN）／`ZI_CDS03_FLIGHT_JOIN`（直接 INNER JOIN 對照組）＋ `ZR_CDS03_DEMO` 已建立、啟用、`programrun` 驗證通過，用兩兩對照的方式實測證明「Association 宣告但不引用不會產生 JOIN，只有真正取用底下欄位才會轉譯成 SQL JOIN」這個核心觀念，並確認 Association 路徑與直接 JOIN 路徑查出的資料完全一致。

兩課動手練習（基於 `SPFLI` 的計算欄位 View、基於 `SFLIGHT`→`SPFLI` 的 Association View）留給使用者在 Eclipse 建立，尚待使用者實際操作＋驗收。

## cds04～cds05 已完成（2026-08-20）

- **cds04**（Parameters 與 Session Variables）：`ZI_CDS04_FLIGHT`（基於 `SFLIGHT`，`with parameters p_carrid`＋`$session.system_date`／`$session.user`）＋ `ZR_CDS04_DEMO` 已建立、啟用、`programrun` 驗證通過（`p_carrid = 'AA'`／`'LH'` 兩種參數值查出不同資料集，`QueriedByUser` 正確顯示 `MONICA`）。實測發現一個真實限制：`$session.system_date` 直接當內建函數參數會報 `Function DATS_DAYS_BETWEEN: At position 1, only Expressions,Literals,Columns,P allowed`，要先 `CAST`（即使型別不變）才會被接受；純比較（不當函數參數）則不需要 CAST，且證實 Session Variable 可以安全放進 cds02 發現有限制的 `CASE WHEN` 條件（因為它不是運算式或函數呼叫）。直接回答了 cds02 思考題 2（用 `$session.system_date` 取代寫死參考日）。
- **cds05**（分層設計：Interface View → Composite View）：`ZI_CDS05_FLIGHT`（Layer 1，含 Parameters／算術運算／Association 不消費）＋ `ZC_CDS05_FLIGHT_REPORT`（Layer 2，消費 Layer 1 的計算欄位＋Association）＋ `ZR_CDS05_DEMO` 已建立、啟用、`programrun` 驗證通過，實戰證明分層設計能繞過 cds02 發現的「CASE WHEN 不能引用同層別名」限制（Layer 1 算好的 `OccupancyRatePercent` 在 Layer 2 變成合法的來源欄位，可以直接被 `CASE WHEN` 引用）。同時確認疊層傳遞參數要用冒號語法（`view( p1: $parameters.p1 )`），跟 Open SQL 呼叫的等號語法（`view( p1 = 'X' )`）不同；並澄清課綱草案原列的「Foreign Key 語法」實際上是 DDIC 建表語法，CDS View 表達關聯用的是 Association，已更正講義內容。

四課動手練習皆留給使用者在 Eclipse 建立，尚待使用者實際操作＋驗收。

## cds06～cds08（期中整合）已完成，基礎篇正式結束（2026-08-20）

使用者指示直接做到 cds08、動手練習稍後補、最後再一起 push，因此這一批一次做完基礎篇剩下的三題：

- **cds06**（CDS Access Control）：`ZI_CDS06_FLIGHT`（CDS View，`#CHECK`）＋ `ZI_CDS06_FLIGHT`（DCL Role，同名不同型別 `DCLS/DL`）＋ `ZR_CDS06_DEMO` 已建立、啟用、`programrun` 驗證通過。實測發現這系統的硬性限制：DCL Role 一定要加 `@MappingRole: true`，缺了報 `DCLs without annotation "@MappingRole: true" are not supported`（照抄系統既有標準物件 `I_CAPaymentOrder` 驗證出正確寫法）。驗證程式證實核心觀念：完全沒寫 `WHERE` 條件的查詢，`#CHECK`＋DCL Role 的 View 依然被自動篩選到只剩 `carrid='AA'`（25 筆），對照 `#NOT_REQUIRED` 的 `ZI_CDS02_FLIGHT` 同樣查詢正常回傳 356 筆橫跨 8 家航空公司——證實 Access Control 是系統強制套用的隱性篩選，不是呼叫端自己加的條件。DCL Role 物件建立走 ADT API 直接 POST `/sap/bc/adt/acm/dcl/sources`（`sap_set_source`/`sap_create_object` 都不支援 DCLS 型別），LOCK 用舊式 `Accept: application/vnd.sap.as+xml;...`，跟 DDIC 物件同一套 workaround（詳見 `.claude/rules/sap-adt-mcp.md` 待補的 DCL 章節）。
- **cds07**（聚合與分組）：`ZI_CDS07_FLIGHT`（明細層級，帶 `@DefaultAggregation` 提示）＋ `ZC_CDS07_ROUTE_STATS`（`GROUP BY carrid`＋`COUNT`/`SUM`/`AVG`）＋ `ZR_CDS07_DEMO` 已建立、啟用、`programrun` 驗證通過，CDS 聚合結果跟應用層手動迴圈累加結果逐項比對一致（`FlightCount`/`TotalSeatsOccupied`/`AvgPrice`），並量測傳輸筆數差異（聚合 8 列 vs. 單一航空公司明細 25 列）佐證「push-down 聚合減少傳輸資料量」的原則，明確不聲稱做過執行時間 Benchmark（測試資料量太小，時間差異沒有意義）。
- **cds08（期中整合）**：三層 View——`ZI_CDS08_ROUTE_REVENUE`（Layer 1，Parameters＋雙重 Association＋算術運算）→ `ZC_CDS08_ROUTE_REVENUE_STATS`（Layer 2，疊層參數轉傳＋`GROUP BY` 聚合）→ `ZR_CDS08_ROUTE_REVENUE_REPORT`（Layer 3，引用 Layer 2 聚合欄位的 `CASE WHEN` 分級）——完整疊了 cds01~cds05、cds07 的技巧（cds06 Access Control 因跟 Parameters 設計意圖衝突，刻意不疊，講義有說明原因）。另建 `ZR_CDS08_LEGACY_REPORT`（等效傳統 Open SQL 報表，手動 `LOOP`/`READ TABLE`/`MODIFY...WHERE` 累加＋逐筆 `SELECT SINGLE` 查關聯資料）跟 `ZR_CDS08_DEMO`（比對驗證程式），兩種寫法對 `p_carrid='LH'` 的五條航線逐筆數字（`TotalRevenue`/`FlightCount`/`AvgSeatsOccupied`/`RevenueTier`）完全一致，證實正確性等價、差異純粹在程式碼組織方式。**實測新發現**：乘法（`price * seatsocc`，`CURR × INT2`）完全不需要 CAST 就能編譯，跟 cds02 學到的「除法要先 CAST 成 decfloat34」不同（甚至嘗試把 CAST 加上去反而報錯 `CAST PRICE of type CURR to type DECFLOAT34 is not possible`）——證實運算子限制因運算子而異，不能無條件套用前面學到的 workaround。

**基礎篇（cds01～cds08）全部完成、全部 `programrun` 驗證通過，已 commit（本地）**。所有動手練習依使用者指示暫緩，等這批全部完成後再一起處理／驗收。

## 進階篇 cds09～cds15 全部完成，全課程 16 題只剩 cds16 期末整合（2026-08-20）

使用者指示「cds09～cds15 也請一併進行，練習待後續補做」，一次做完整個進階篇（除了 cds16 期末整合）：

- **cds09**（Extend View）：`ZC_CDS09_CARRIER_EXT` 擴充 cds01 的 `ZI_CDS01_CARRIER`，確認目標物件原始碼完全不受影響；實測發現不需要 `@Metadata.allowExtensions`（跟 fe08 學到的 Metadata Extension 規則不同，兩種擴充機制各自獨立）。
- **cds10**（Custom Entity）：`ZI_CDS10_FLEET_STATUS` + `ZCL_CDS10_STATUS_QUERY`（`IF_RAP_QUERY_PROVIDER`）。實測發現 Custom Entity **完全不能用 Open SQL 查詢**（編譯期錯誤 `Entities like "..." cannot be used here`，不是執行期才發現），只有透過 RAP 框架存取才會觸發 Query Provider。**發明 Mock Request/Response 直接呼叫類別驗證邏輯**的技巧（自己實作 `IF_RAP_QUERY_REQUEST`/`IF_RAP_QUERY_RESPONSE` 最小化版本），繞過需要 Service Binding 才能測試的限制，這個技巧之後任何 RAP Query Provider 情境都能重用。
- **cds11**（Analytical Annotation 深入）：`ZI_CDS11_FLIGHT_REVENUE` + `ZC_CDS11_ROUTE_ANALYTICS`（`@Analytics.dimension`/`@Analytics.measure`/`@Semantics.amount.currencyCode`）。實測發現聚合函數參數不能是運算式（`Expressions cannot be used as parameters of aggregate functions`），跟 cds02 的 CASE WHEN 限制同一類模式，一樣靠 cds05 分層技巧解決；驗證數字與 cds08 交叉比對完全一致。
- **cds12**（Virtual Element）：`ZCL_CDS12_DAYS_CALC`（`IF_SADL_EXIT_CALC_ELEMENT_READ`）+ `ZI_CDS12_FLIGHT_VIRTUAL`。**重要澄清**：這系統用的是舊式 SADL-based Virtual Element 機制（`@ObjectModel.virtualElementCalculatedBy`），不是新式 RAP Projection View 專屬的 Virtual Element（那個需要 `define view entity ... as projection on`，這系統不支援）。實測發現跟 Custom Entity 同一模式：純 Open SQL 只看得到佔位值，Exit Class 不會被觸發；沿用 cds10 的 Mock 技巧驗證類別邏輯本身正確。踩到一個小坑：`sadl_entity_element` 型別是 STRING，`VALUE #(('FLDATE'))` 要改用反引號字串字面值才能通過型別檢查。
- **cds13**（Value Help）：`ZI_CDS13_FLIGHT_VH`（`@Consumption.valueHelpDefinition` + `@ObjectModel.text.association`），重用 cds01 的 `ZI_CDS01_CARRIER` 當 Value Help 來源，確認純中繼資料不影響一般查詢（跟 cds10/cds12 的框架依賴機制形成對比）。
- **cds14**（Hierarchy CDS View）：新建自我參照表 `ZTCDS14_ORGUNIT`（組織架構）+ `ZI_CDS14_ORGUNIT_HIER`（`@ObjectModel: {dataCategory: #HIERARCHY}` + `@hierarchy.parentChild`，照抄標準物件 `I_GLAccountHierarchyNode`），DDL 建模完整驗證成功。**誠實記錄**：Open SQL 的 `HIERARCHY_DESCENDANTS()` 樹狀巡覽語法嘗試了六種變體全部失敗（詳細錯誤訊息見講義），結論是這系統的 Open SQL Hierarchy 巡覽函數只支援 `CHILD TO PARENT ASSOCIATION` 變體，不支援直接把已有 DDL Hierarchy annotation 的實體當 bare SOURCE 使用——這是 cds10/cds12 那個「DDL annotation 只服務特定框架」模式的第三次印證。樹狀呈現效果留給使用者在 Eclipse Data Preview 驗證。
- **cds15**（效能與除錯）：`GET RUN TIME FIELD` 量測技巧示範，量到一個**違反直覺的真實結果**——小資料量（356 筆）下 CDS 聚合（23,240 微秒）反而比手動 ABAP 迴圈聚合（7,131 微秒）慢三倍多，講義誠實保留這個「對 CDS 不利」的數字並解釋原因（多層解析的固定成本 vs. 資料量太小無法體現下推效益）；Association 消費 vs. 不消費的量測則符合直覺（消費較慢）。整理 cds01~14 累積的完整效能地雷清單。

**進階篇 cds09～cds15 全部完成、全部 `programrun`（或 Mock 測試）驗證通過，已 commit（本地，尚未 push）**。

## cds16（期末整合）完成，全課程 16 題正式結案（2026-08-20）

以 cds14 的組織架構（`ZTCDS14_ORGUNIT`）為基礎，補上 `HeadCount` 欄位，把 cds11（Analytical）／cds12（Virtual Element）／cds13（Value Help）／cds14（Hierarchy）四種進階技巧疊進同一個 `ZI_CDS16_ORGUNIT_FINAL`：`ParentId` 的 Value Help 指向自己（自我參照階層資料的常見模式）、`OrgUnitName`/`HeadCount` 標 Dimension/Measure、`DisplayLabel` 用 `ZCL_CDS16_LABEL_CALC`（SADL Exit）執行期組合顯示字串、整個 View 仍保留 Hierarchy annotation。**四種技巧一次啟用成功，完全沒有相容性衝突**，證明前面各課分開驗證過的每項技巧都是可以自由組合的積木。

驗證延續全課程一貫的誠實邊界：Hierarchy／Analytics／Value Help 三項不影響 Open SQL，`programrun` 直接驗證（`HeadCount` 加總 61 正確）；Virtual Element 沿用 cds10/cds12 發明的 Mock 直接呼叫技巧驗證類別邏輯（正確組出 `ZROOT - CEO Office (5 staff)`），純 Open SQL 只看得到佔位空白值；樹狀展開／F4 下拉選單的真實呈現效果留給使用者在 Eclipse Data Preview 驗證。

**CDS View 課程（cds01～cds16）全部完成、全部驗證通過，已 commit（本地，尚未 push）。全部動手練習依使用者指示暫緩，留給使用者後續在 Eclipse 補做並驗收。下一步：使用者確認 push 時機。**
