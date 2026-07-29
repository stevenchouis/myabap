# SAP ABAP Enhancement Framework 增強技術課程

前面幾門課補齊了 RICEFW 裡的 **R**eports（基礎課）、**I**nterfaces／**C**onversions（Interface 課程）、**F**orms（Smartform 課程），唯獨少了 **E**nhancement 這一塊——同時也是 CLAUDE.md 開發流程明訂「不可修改 SAP 標準物件，只能透過 Enhancement／BAdI／User-Exit」規則背後的具體技術手段，目前教材都還沒有系統性教過怎麼做。本課程補上這條線：從最舊的 Function Exit（`SMOD`/`CMOD`）、物件導向化的 BAdI（classic 單一實作與新式 Enhancement Spot 多重實作），到 Enhancement Framework 的 Explicit／Implicit Enhancement Point。**課綱為草案，尚未出題。**

**✅ 已查證的工具支援範圍**（2026-07-28 用 ADT discovery＋quickSearch 實測，非猜測）：

- **Enhancement Spot（`ENHS`，新式 BAdI 定義）／Enhancement Implementation（`ENHO`，涵蓋 BAdI 實作與 Explicit Enhancement 的插入實作）／Source Code Plugin（`ENHOXHH`，Implicit Enhancement Point 的插入實作）都有正式 ADT collection**（`/sap/bc/adt/enhancements/enhsxs`、`/sap/bc/adt/enhancements/enhoxh`、`/sap/bc/adt/enhancements/enhoxhh`），quickSearch 也能正常查到系統既有的標準 Enhancement Spot（如 `ES_ACE_DOCUMENT`）並取得可用的物件 URI——這三類走**跟 Domain/DE/Table Type 一樣的 stateful session 流程**（LOCK → PUT → UNLOCK → activation，見 `.claude/rules/sap-adt-mcp.md` 第 5／8／14 節），`sap_get_source`/`sap_set_source` 的 objectType enum 目前沒有對應項目，要走 ADT API workaround，實際 XML schema 待出題時逐題查證。
- **Classic User-Exit（`SMOD`／`CMOD`，物件型別 `CMOD/XP`）沒有可寫入的 ADT collection**，quickSearch 查到的既有 Project（如 `ZSD00001`）只落在 `/sap/bc/adt/vit/wb/object_type/cmodxp/...` 這種唯讀 metadata stub 路徑——跟本檔第 10 節 Search Help、第 12 節 T-code 是同一類「GUI-only，只能 SE38/CMOD 手動維護」的物件，指派 Enhancement 到 Project、Activate Project 這兩步都要使用者在 SAP GUI 操作。**但有個重要例外待驗證**：實測查詢一個標準 Function Exit（`V05E`）發現它底層的「使用者可寫程式碼」的地方（如 `V05EZZAG`）其實是**普通的 `PROG/I` Include**，理論上可以套用第 1 節「INCLUDE 讀寫 workaround」用 `sap_get_source`/`sap_set_source` 直接讀寫——也就是說 CMOD **專案指派**是 GUI-only，但 Function Exit **程式碼本體**可能是 Claude 能自動讀寫的，這點只是根據系統既有物件結構觀察到的推論，尚未實際寫入驗證，出題到 en02 時要先實測確認再下結論。
- **另外查到 `/sap/bc/adt/businesslogicextensions/badis`（Business Logic Extensions／Key User Extensibility BAdI）**——這是 S/4HANA Cloud／ABAP Cloud 導向的簡化 BAdI 實作管道（含 `badinameproposals` 命名建議 API），跟本課程主軸的 classic／new BAdI（SE18/SE19、Enhancement Spot）是不同世代的機制，本課程不涵蓋，列為下一階段候選（需先確認這套系統是否走 ABAP Cloud 開發模式）。

## 課程定位

- **對象**：完成基礎課（尤其 ex15 Function Module、ex23 LUW）與 OOP 課（Interface、抽象類別）的學員；Interface 課程（BAPI／整合開發）與 Smartform 課程非必要前提，但建議至少上過其中一門，體會過「呼叫別人寫好的標準物件」的手感。
- **技術範圍**：Enhancement Framework 四大分類——① Classic User-Exit（`SMOD`/`CMOD`，含 Function Exit／Menu Exit／Screen Exit 概念）；② Classic BAdI（`SE18`/`SE19`，單一實作、Filter-dependent）；③ 新式 BAdI／Enhancement Spot（多重實作、Fallback Class）；④ Enhancement Point/Section（Explicit，原開發者刻意留下的插入點）與 Implicit Enhancement Point（Source Code Plugin，任何 FORM/METHOD/FUNCTION 頭尾都有的隱式插入點）。**不含** Business Add-Ins Cloud／Key User Extensibility（上面已查到 API，但屬於不同世代機制，列下一階段候選）與 Workflow（RICEFW 最後一塊拼圖，另立課程）。
- **⚠️ 已知工具限制**：見上方「已查證的工具支援範圍」，Classic User-Exit 的專案指派／Activate 步驟預期要使用者在 SAP GUI 手動操作，Claude 從旁指導與核對結果；ENHS/ENHO/ENHOXHH 三類雖有 API，但沒有 MCP 工具直接支援，每題都要先查證正確的 XML schema（比照 Domain/DE 建立時「先 GET 既有物件當範本」的做法，本課程可以直接 quickSearch 標準 Enhancement Spot 當範本）。
- **結業標準（草案）**：分得清四大增強技術的適用時機與差異；能找到一個標準交易/程式有哪些可用的增強點；能自己定義一個 Enhancement Spot＋BAdI Interface 並寫出至少一個實作；能在既有程式插入 Implicit Enhancement 修改邏輯而不碰觸原始碼本身；理解為什麼這整套機制的存在，就是「不改標準物件」這條專案鐵律能夠落地的原因。

## 教材慣例（比照 OOP/REST/AMDP/Interface/Forms 課程）

- 每題三件套：題目 `enNN_主題.md` + PDF 講義（`node tools/md2pdf.js src/ABAP_Training_Enhancement`）+ 答案快照（GUI-only 步驟無法快照的部分，至少快照呼叫端／實作類別程式碼）
- 每題 md 開頭（`## 學習目標` 之前）要有 `## Lecture` 完整背景知識講解
- 答案物件命名：Enhancement Spot／BAdI Interface 沿用 `ZIF_ENnn_*`，Enhancement Implementation／實作類別 `ZCL_ENnn_*`，呼叫端程式 `ZR_ENnn_*`
- 資料模型：優先沿用前面課程用過的 SCARR/SFLIGHT 航班模型或 Interface 課程 if09 的 Conversion Runner 情境，方便串連「客戶可自訂邏輯」的教學情境

## 課綱（草案，待逐題出題與驗收）

| # | 主題 | 內容重點 | 銜接前面課程 | 狀態 |
|---|---|---|---|---|
| en01 | 增強技術總覽與尋找方法 | Enhancement Framework 四大分類總覽與適用時機對照表；怎麼找一個交易/程式有哪些可用增強點（程式編輯器 Edit→Enhancement Operations 切換顯示、`SE18`/`SE19` 尋找 BAdI、`SPRO` 的 Business Add-Ins 節點、`SE80` 物件清單的 Enhancements 子節點）；呼應 CLAUDE.md「不可修改標準物件，只能透過 Enhancement/BAdI/User-Exit」規則，講清楚這條規則在技術上具體對應哪些工具。本題只講觀念，不建物件 | 呼應 CLAUDE.md 開發流程規則 | **已完成**（`en01_overview_and_discovery.md`；已用 `sap-adt` MCP 查證真實案例 `MB_MIGO_BADI` 同時存在 `SXSD/XD`〔舊式 Classic BAdI Definition，GUI-only stub〕與 `ENHS/XS`〔新式 Enhancement Spot，完整可讀，`singleUse="false"`〕兩種身分，證實「NetWeaver 7.0 把舊 BAdI 包一層新外殼」不是文件推論而是真實系統行為；順便讀出 Interface `IF_EX_MB_MIGO_BADI` 的 `CHECK_ITEM`/`POST_DOCUMENT` 等方法佐證教學） |
| en02 | Classic User-Exit 實戰：批號自動給號＋Number Range Object | 真實案例（非虛構）：SAP 標準批號自動給號（`VB_NEXT_BATCH_NUMBER`）同一流程疊了三代擴充技術（Classic User-Exit `EXIT_SAPLV01Z_001`/`_002`、新式 BAdI `BADI_BATCH_NUMBER_INT`、S/4HANA Cloud BAdI），本題正規實作兩支 Function Exit（`_001` 重導向自建 Number Range Object `ZEN02BAT`，`_002` 加工成 `YYMMDD`+4碼流水號，`MCHA-CHARG` 只有 CHAR10 故不用完整日期+時間），並講解 Internal／External 批號給號政策的差異；順帶證實「ZX 開頭 Include 保留給 Exit Function Group、CMOD 裡雙擊 Component 可觸發生成」「Include 原始碼寫好啟用≠Enhancement 生效，一定要走 CMOD 建 Project＋Assign＋Activate」「Number Range 取號是非交易性的，跳號是正常現象」 | 承 en01 | **已完成，端對端驗證成功**（`en02_classic_user_exit_batch_number.md`；`ZEN02BAT`／`ZXVBZU01`〔套件 `$TMP`〕／`ZXVBZU02`〔套件 `ZPP`，傳輸 `S4HK901982`〕／`ZR_EN02_BATCH_DEMO`〔`$TMP`〕均已建立啟用；CMOD Project `ZBATCHNO` 已建立、Assign、Activate；使用者用真實採購單 `4500001919` 做 Goods Receipt 實測，過帳 Log 顯示「Creating batch 2607290004」，批號格式完全正確，證實 Enhancement 對真實貨物移動確實生效） |
| en03 | Classic BAdI 觀念與尋找 | BAdI 是 User-Exit 的物件導向後繼者：Definition（`SE18`）／Implementation（`SE19`）分工、Interface 為什麼一定要繼承 `IF_BADI_INTERFACE`、Single/Multi Use 與 Filter-dependent、`GET BADI`＋`CALL BADI` 呼叫語法；用真實案例 `BADI_MM_MATNR`（Multi Use，有 SAP 標準 Implementation `CL_IM_BADI_MM_MATNR` 但 `isActive=false`）示範「Implementation 存在≠生效」，並與 en01/en02 查證過的 `MB_MIGO_BADI`／`BADI_BATCH_NUMBER_INT` 做三案例對照 | 承 en01/en02，對照 Interface 課程 if01 FM vs BAPI 的「找標準物件」手感 | **已完成**（`en03_classic_badi_concept_and_discovery.md`；不建物件，純觀念與真實查證，`BADI_MM_MATNR`／`IF_EX_BADI_MM_MATNR`／`CL_IM_BADI_MM_MATNR` 均已用 `sap-adt` MCP 查證存在並讀出真實內容） |
| en04 | 建立 Enhancement Spot 與 BAdI Definition | 動手用 ADT API 建立自己的 `ZIF_EN04_*` Interface＋掛上 Enhancement Spot（`ENHS`）成為 BAdI Definition；Fallback Class 的用途（沒有任何實作時的預設行為）；多重實作（Multiple Use）vs 單一實作（Single Use）的宣告差異 | 承 en03 | 待出題 |
| en05 | 實作 BAdI（Enhancement Implementation） | 建立 `ENHO` 實作 en04 定義的 BAdI Interface；呼叫端程式 `GET BADI`＋`CALL BADI` 驗證；示範多個實作同時存在時的執行順序與 Filter 過濾效果 | 承 en04 | 待出題 |
| en06 | Explicit Enhancement Point/Section | 在自訂的 Z 程式中安插 `ENHANCEMENT-POINT`／`ENHANCEMENT-SECTION`（含 `INCLUDE BOUND`／`REPLACE` 的差異），再建一個 Enhancement Implementation 掛上去；講清楚「插入 Implementation」跟「修改原始碼」的差別，呼應「不可修改標準物件」規則裡 Explicit Enhancement 的角色 | 承 en04/en05 | 待出題 |
| en07 | Implicit Enhancement Point（Source Code Plugin） | 任何 FORM／METHOD／FUNCTION 頭尾都有的隱式插入點，不需要原開發者事先宣告；建立 `ENHOXHH` Source Code Plugin 插入程式碼；對照 en06：Explicit 需要原開發者刻意留下插入點，Implicit 到處都有但只能加程式碼不能改變介面 | 承 en06 | 待出題 |
| en08 | 期末綜合實作 | 整合前面技巧：在一個資料處理情境（可呼應 Interface 課程 if09 的 Conversion Runner）上，同時提供一個 BAdI Hook 點讓「客戶自訂驗證邏輯」可以外掛、並用 Implicit Enhancement 示範不改動既有程式碼也能追加一段記錄動作 | 呼應 Interface 課程 if09、整合 en01～en07 | 待出題 |

> 課綱為草案，尚未出題；en02（Classic User-Exit 底層 Include 是否真能用既有 INCLUDE workaround 讀寫）與 en04～en07（ENHS/ENHO/ENHOXHH 的實際 XML schema）都需要在出題時逐一用 ADT API 實測查證，不能只憑本檔的推論直接寫程式，查證結果要回頭更新 `.claude/rules/sap-adt-mcp.md`。
