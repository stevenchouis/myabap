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
| cds01 | CDS View 是什麼、為什麼要用 | Open SQL 直接查表 vs. CDS View 的差異（語意豐富化、可重用、下推執行）；這系統的 `define view`（無 `entity`）語法限制說明；Eclipse ADT 建立 CDS View Step by Step；最基本的 `@AbapCatalog.sqlViewName`／`@AccessControl.authorizationCheck`／`@EndUserText.label` annotation；SE11/SE16 驗證查詢結果 |✅ 已完成（2026-08-18，`ZI_CDS01_CARRIER`＋`ZR_CDS01_DEMO`，`programrun` 驗證通過；SE16 一段是推論尚未經使用者實測確認）|
| cds02 | 欄位選取與運算 | 別名（`as`）、算術運算、字串/日期內建函數、`CASE WHEN`、常數欄位、`CAST` |待出題|
| cds03 | Association vs. JOIN | `association [cardinality] to <目標> as _別名 on ...`；path expression 何時才會真的轉成 SQL JOIN（只有被引用才轉譯）；跟直接寫 JOIN 的差異與取捨 |待出題|
| cds04 | Parameters 與 Session Variables | `with parameters` 語法、`$parameters.<name>`；內建 Session Variable（`$session.client`/`user`/`system_date` 等）；動態篩選的應用場景 |待出題|
| cds05 | CDS View 分層設計：Interface View → Composite View | View 命名分類慣例（I_/C_/P_/R_）；為什麼要分層（重用、單一職責）；Foreign Key 語法（`with foreign key`）；一個實戰練習：拿 cds01~cds04 疊出兩層 View |待出題|
| cds06 | CDS Access Control | `define role` 語法、`@AccessControl.authorizationCheck` 的合法值與差異（`#CHECK`/`#NOT_REQUIRED`/`#PRIVILEGED_ONLY`）、跟 `AUTHORITY-CHECK` 的分工 |待出題|
| cds07 | 聚合與分組 | CDS 內的 `SUM`/`AVG`/`COUNT`/`GROUP BY`，搭配 `@DefaultAggregation` 初探；跟應用層聚合（Open SQL 撈明細再迴圈算）的效能對比 |待出題|
| cds08（期中整合） | 綜合實作 | 用 cds01~cds07 教過的技巧疊一個「航線營收分析」多層 CDS View，取代一支既有的 Open SQL 報表程式，並比較兩者可讀性/維護性 |待出題|

### 進階篇：CDS View 深化主題

| # | 主題 | 內容重點 | 狀態 |
|---|---|---|---|
| cds09 | Extend View | `extend view <既有 View> with { ... }`：不修改原始碼、幫既有（含標準）CDS View 加欄位；跟 DDIC Append Structure／Customer Include（RAP 課程 en02 教過的機制）的類比與差異 |待出題|
| cds10 | Custom Entity | 資料來源不是 DB Table（例如 RFC/外部系統）時的 CDS 建模方式；`define custom entity`、Query Provider 實作類別的角色；**✅ 開課前已驗證 `define custom entity` 語法在這系統可編譯啟用**（`ZI_CDSPROBE_CE`） |待出題|
| cds11 | Analytical Annotation 深入 | `@Analytics.query: true`、`@DefaultAggregation`、`@Semantics.amount`/`@Semantics.quantity`、Dimension vs. Measure 的標記方式；跟 cds07 聚合的銜接 |待出題|
| cds12 | Virtual Element | `@ObjectModel.virtualElement`＋Exit Class（`IF_SADL_EXIT_CALC_ELEMENT_READ`）：執行期才計算、不存在資料庫的欄位 |待出題|
| cds13 | Value Help Annotation | `@Consumption.valueHelpDefinition`、`@ObjectModel.text.element`（文字欄位關聯）；**✅ 開課前已驗證這是純 CDS Annotation，不受 Classic Search Help（SHLP）GUI-only 限制影響**（`ZI_CDSPROBE_VH`，引用標準 `I_Country` 測試成功） |待出題|
| cds14 | Hierarchy CDS View | `@ObjectModel: { dataCategory: #HIERARCHY }`＋`@hierarchy.parentChild: { recurse: {...}, siblingsOrder: {...}, directory: ... }`：自遞迴模型（父子關係）的 CDS 建模方式；**✅ 開課前已用系統既有標準物件 `I_GLAccountHierarchyNode`（真實 active）確認語法可照抄**；練習用組織架構或料號 BOM 之類的自遞迴表 |待出題|
| cds15 | 效能與除錯 | ADT Data Preview／`EXPLAIN PLAN` 觀念（本系統 ADT SQL Console 沒有 Explain Plan 功能，RAP 課程已查證，這裡改用觀念說明＋執行時間量測）；常見效能地雷（Association 誤用成大量 JOIN、CDS 疊太多層） |待出題|
| cds16（期末整合） | 綜合實作 | 整合 Analytical Annotation＋Virtual Element＋Value Help＋Hierarchy，設計一個能直接被 Fiori Elements／分析工具消費的完整 CDS View（呼應 RAP 課程 `@UI.*` 但這裡聚焦資料建模而非 Behavior） |待出題|

## 出題工作流程（比照 RAP/AMDP 課程）

Claude 用 ADT API 建立 CDS View／Metadata Extension 驗證語法可行 → 使用者依講義在 Eclipse 動手做一次（cds01 起套用 RAP 課程「教學分工原則」，物件複雜度夠高時改由使用者建立、Claude 驗證）→ 語法檢查＋啟用 → `programrun`／`sap_sql_query`/`datapreview` 驗證資料正確 → 使用者驗收 → 快照 → 題目 md → `node tools/md2pdf.js src/ABAP_Training_CDS` 產 PDF → 更新本 README 狀態 → commit。每批 2–3 題、使用者驗收後再繼續。

## 已確認事項（2026-08-18）

- 課綱總題數確認為 **16 題**（基礎篇 8 題＋進階篇 8 題），維持完整份量，不合併
- cds10（Custom Entity）、cds13（Value Help）已查證可行，不受 GUI-only 限制影響
- Hierarchy CDS View 已加入課綱（cds14），並確認系統既有標準物件可直接參照出題

課綱定案，開始出題。

**cds01 已完成（2026-08-18）**：`ZI_CDS01_CARRIER`（基於 `SCARR` 的最基本 CDS Interface View）＋ `ZR_CDS01_DEMO`（驗證程式，Open SQL 直查表 vs. 查 CDS View 筆數比對）已建立、啟用、`programrun` 驗證通過。動手練習（基於 `SPFLI` 的基本 CDS View）留給使用者在 Eclipse 建立，尚待使用者實際操作＋驗收；講義裡的 SE16 驗證段落是根據 SE11 已驗證規則的推論，尚未經使用者實測確認，需要使用者回報實際畫面。下一步：等使用者驗收 cds01 後，依「每批 2–3 題」原則繼續出 cds02～cds03。
