# SAP ALE／IDoc 整合開發課程

企業間／系統間資料整合的經典技術——**ALE（Application Link Enabling）** 是分散式流程整合框架（決定「誰跟誰之間、什麼時候該同步什麼資料」），**IDoc（Intermediate Document）** 是 ALE 選定的標準資料載體格式。本課程教這一整套機制：從環境設定（Distribution Model／Partner Profile／Port／Change Pointer）、IDoc 基礎架構與監控，到自訂擴充與 Outbound/Inbound 客製化開發，最後用兩個真實企業情境（集團內部關聯交易自動對帳）收尾。**課綱為草案，尚未出題。**

## 課程定位

- **對象**：完成基礎課（尤其 ex15 Function Module、ex23 LUW）的學員；強烈建議先修過 **Enhancement 課程**（`src/ABAP_Training_Enhancement/`）——en02/en04 教的 BTE／Enhancement 掛勾技巧，是本課程自訂 Outbound 觸發時機的關鍵前置技能。
- **技術範圍**：
  1. **ALE 基礎環境設定**（Customizing，非 ABAP 開發）：Distribution Model（`BD64`）、Partner Profile（`WE20`）、Port（`WE21`）、Change Pointers（`BD61`/`BD50`/`BD52`）
  2. **IDoc 基礎架構與監控**：Control/Data/Status Record、`WE02`/`WE05`/`WE19`
  3. **Master Data vs Transaction Data 兩種觸發機制**：前者靠 Change Pointer 框架自動化，後者靠 Output Determination（`NAST`）或手動/Enhancement 觸發——本課程刻意分開處理，避免學生誤以為只有一種模式
  4. **自訂 IDoc 擴充＋Outbound/Inbound 客製化開發**：Segment 擴充、自訂 Function Module、錯誤處理與重送（`BD87`）
  5. **期末兩個真實整合案例**：集團內部關聯交易的自動對帳情境（見課綱表 ale09/ale10）
- **✅ 系統環境限制（2026-08-24 已用 `sap-adt`/`sap-adt-home` MCP 實測查證，見 ale01 與 `.claude/rules/sap-adt-mcp.md` 第 58 節）**：本課程只適用 **on-premise 系統**（連線 `SAP_Bridge`／`sap-adt`／`sap-adt-home`），ALE/IDoc 這類經典 Customizing／Dynpro 技術在 **ABAP Cloud 限制語法**下完全不存在。`BD64`／`WE20`／`WE21`／`BD61`／`BD50`／`BD52`／`WE19`／`WE02`／`WE05`／`BD87` 十個交易碼皆確認 TADIR 型別為 `TRAN`，無 ADT API，一律 GUI-only。**IDoc 三個核心物件的 ADT 支援程度完全不同、出乎意料**：Message Type（`WE81`）連 TADIR 個別登記都沒有，是純 `EDMSG` 字典資料，無 API；Basic Type／IDoc Type（`WE30`，TADIR 型別 `IDOC`）有登記但無任何 ADT 曝光；**🏆 Segment Type（`WE31`）的 TADIR 型別其實是 `TABL`——本質就是一張一般 DDIC Structure**，已用 `sap_get_source(objectType=STRU)` 對標準 Segment `E1MARAM`/`E1EDK01` 實測成功完整讀出原始碼！**（ale06 出題時已修正細化）**：Segment 是 `E1xxx`（扁平字元）＋`E2xxx###`（引用 Data Element）兩層 DDIC Structure，中繼資料在 `EDISDEF`/`EDSAPPL`；ADT 可讀取但**不能靠自建 Structure 註冊 Segment**，ale06 的 Segment 建立一律走 `WE31` GUI，Claude 只做事後驗證。
- **結業標準（草案）**：分得清 ALE（框架/決策）與 IDoc（資料載體）的關係；能講出 Master Data（Change Pointer）與 Transaction Data（Output Determination／手動觸發）兩種分送機制的差異與各自適用情境；能在 Partner Profile 正確判斷「這個訊息在這台系統上該設 Outbound 還是 Inbound」，不會把 Source/Target 跟 Outbound/Inbound 搞混；能設計一個自訂 IDoc 擴充並完成 Outbound→Inbound 端對端驗證；能看懂並重現一個標準 ALE 情境（STO Intercompany Billing）。

## ⚠️ 教學重點提醒：Partner Profile 的 Inbound/Outbound 判斷原則（2026-08-22 使用者明確要求強調）

這是 ALE 學習曲線中最容易搞混的環節，**課程中會反覆講解＋反覆動手配置，不只在 ale02 講一次觀念就結束**：

- **判斷原則只看「這個訊息在這台系統上是送出還是接收」，跟「我是 Source 還是 Target」無關**：A 系統要送出 IDoc 給 B，就在 A 系統的 `WE20`、對著 Partner＝B，填 **Outbound Parameters**（Port、Output Mode）；B 系統要接收處理，就在 B 系統的 `WE20`、對著 Partner＝A，填 **Inbound Parameters**（Process Code）。
- **兩筆設定分別存在兩台不同系統上，不是同一張畫面、也不是互相複製**——新手常誤以為「A 系統也要設 Inbound」或「B 系統也要設 Outbound」，但單向流程（A 送給 B、沒有回頭訊息）只需要 A 設 Outbound、B 設 Inbound。
- **唯一雙方都要設 Outbound+Inbound 的情況**：流程本身雙向（如開啟 ALE Audit／`ALEAUD` 確認 IDoc 回送，或業務流程本身有回頭訊息如 `ORDRSP`）——這是**另一個訊息類型**的雙向配置，不是同一個訊息類型自己雙向跑。
- **口訣**：「我送出＝設定我方 Outbound（填 Port，對方是誰）；我接收＝設定我方 Inbound（填 Process Code，怎麼處理）」
- ale02（環境設定）會用兩系統/Client 對照圖＋常見誤區 Q&A 講解一次；ale04（Master Data）、ale07（Outbound 客製化）、ale08（Inbound 客製化）會要求學生實際在兩邊各自配置一次，透過重複動手練熟，不是只講一次觀念。

## 教材慣例（比照 RAP/Enhancement/CDS 課程）

- 每題三件套：題目 `aleNN_主題.md` + PDF 講義（`node tools/md2pdf.js src/ABAP_Training_ALE`）+ 答案快照（GUI-only 步驟無法快照的部分，至少快照呼叫端／自訂 Function Module 程式碼）
- 每題 md 開頭（`## 學習目標` 之前）要有 `## Lecture` 完整背景知識講解
- 答案物件命名：自訂 Function Module `Z_ALEnn_*`，自訂 Segment/Message Type `ZALEnn_*`，驗證用程式 `ZR_ALEnn_DEMO`
- 兩個期末案例會用兩個 Client（或兩個 Logical System 定義）模擬「兩家公司」，不需要真的有第二套實體系統
- **⚠️ Schema 設計硬性規則（2026-08-22 使用者明確要求，呼應專案既有規則 `.claude/rules/abap-style.md`）**：本課程幾乎每個情境都對應一張真實標準表／標準單據（Master Data：`KNA1`/`MARA`/`LFA1`；Transaction Data：`MIRO` 底層的 `RBKP`/`RSEG`、Billing 的 `VBRK`/`VBRP`、會計憑證的 `BKPF`/`BSEG`）。**自訂 Segment（`WE31`）、自訂 Table、驗證程式用的本地結構，欄位一律要直接引用對應標準表既有欄位的 Data Element**，不可以另外用 `abap.char(...)` 這類內建型別或自建 Domain/DE 平行複製一份長得很像的型別——先用 quickSearch／讀標準表定義查出實際 Data Element 再引用，不要憑記憶猜。**能整段重用標準 Structure 更好**（例如 Segment 描述的剛好是某張標準單據的欄位子集，直接 `INCLUDE TYPE` 或引用該標準 Structure，不要逐欄位手動重新宣告），目的是讓自訂物件跟標準表在型別層級保持一致，日後串接 JOIN／BAPI 呼叫不需要額外轉換。

## 課綱（草案，待逐題出題與驗收）

| # | 主題 | 內容重點 | 銜接前面課程 | 狀態 |
|---|---|---|---|---|
| ale01 | 為什麼要用 ALE/IDoc？環境查證 | ALE 在企業整合架構中的定位（對比已學過的 REST／RAP／BAPI）；IDoc 五層概念總覽（Control/Data/Status Record、Message Type、Basic Type、Segment）；Master Data vs Transaction Data 兩種觸發機制的觀念對照表；**用 ADT discovery/quickSearch/TADIR 反查實測查證** `WE30`/`WE31`/`WE81` 是否有 API、`BD64`/`WE20`/`WE21`/`BD61`/`BD52` 確認是否為純 GUI-only；本題只講觀念+查證，不建物件 | 呼應基礎課、Enhancement 課程對「不改標準物件」規則的鋪墊 | **✅ 已出題並完成查證**（`ale01_overview_and_discovery.md`：Master Data vs Transaction Data 對照、情境判斷、ALE vs REST 比較表、**環境查證結果**〔Segment Type＝`TABL`、Basic Type＝`IDOC`〔無曝光〕、Message Type 無 TADIR 登記〕全部完成，2026-08-24） |
| ale02 | ALE 環境設定實戰 | `SM59`（RFC Destination）→ `WE21`（Port）→ `WE20`（Partner Profile，**含 Inbound/Outbound 判斷原則詳細講解＋常見誤區 Q&A**）→ `BD64`（Distribution Model）→ `BD61`（Change Pointer 全域啟用）——GUI-only 操作指引；**因使用者僅有單一 Client（130）存取權限，改用「自我迴圈測試」設計**（Logical System／RFC Destination／Port 都指向自己），結尾用 `WE19` 送測 `MATMAS` IDoc 驗證整條管線 | 承 ale01 | **✅ 已出題**（`ale02_environment_setup.md`；驗證用字典表 `EDIPORT`/`EDIPOA`/`EDP13`/`EDP21` 已查證正確表名與欄位，見規則檔第 58.4 節；等待使用者完成 GUI 操作後回報結果） |
| ale03 | IDoc 基礎結構與監控 | Control/Data/Status Record 結構拆解（`EDIDC`/`EDID4`/`EDIDS` 字典表逐欄說明）；常見狀態碼對照表；監控交易 `WE02`/`WE05` 使用情境差異；測試工具 `WE19`（Existing IDoc 模式，複製既有 IDoc 修改後用 Inbound Processing 重送）；沿用 ale02 已建好的自我迴圈管線與已送出的 `MATMAS` IDoc 觀察端對端結果 | 承 ale02 | **✅ 已出題**（`ale03_idoc_structure_monitoring.md`；全程 GUI 操作＋監控查詢，等待使用者完成後回報 IDoc 號碼與狀態碼供驗證） |
| ale04 | Master Data 分送實戰——Change Pointer 機制端對端 | Change Document vs. Change Pointer 概念釐清；`BD61`（已於 ale02 開）→`BD50`（訊息類型層級）→`BD52`（欄位層級，用 `MATMAS`/`MARC-EISBE` 安全庫存量）三層開關；`MM02` 異動主資料→`BD21`/`RBDMIDOC` 觸發→沿用 ale02 既有 Outbound/Inbound 管線送出→用 ale03 學到的 `WE02` 監控驗證；**沿用 ale02 自我迴圈設定，說明為何本題不需要重新配置 Partner Profile** | 承 ale03 | **✅ 已出題**（`ale04_master_data_change_pointer.md`；全程 GUI 操作，會真實異動一筆物料安全庫存量並要求還原，等待使用者完成後回報 IDoc 號碼與狀態碼供驗證） |
| ale05 | Transaction Data 觸發機制 | Output Determination（`NAST`／條件技術／`NACE`／輸出類型如 `RD04`）vs. 手動/Enhancement 觸發（`MASTER_IDOC_DISTRIBUTE`）；三種觸發機制（Change Pointer／Output Determination／手動-Enhancement）完整對照表；全程唯讀觀察既有標準設定，不新增 Customizing | 承 ale04 | **✅ 已出題**（`ale05_transaction_data_triggers.md`；`NACE`/`VF03` 唯讀觀察步驟等待使用者回報實際畫面內容以核對講義措辭） |
| ale06 | 自訂 IDoc 擴充 | Part A：Extension（`WE31` 建 `Z1ALE06`→`WE30` 建 Extension `ZALE06_MATEXT` 掛在 `MATMAS05` 的 `E1MARAM` 底下→`WE82` 指派）；Part B：自訂完整 Z 訊息類型骨架（`WE81` `ZALE06`＋表頭/明細 Segment＋`WE30` Basic Type `ZALE06_BT01`＋`WE82`）；兩條路線取捨表；Segment 兩層解剖（`E1` 扁平字元 vs. `E2` 引用 Data Element，中繼資料 `EDISDEF`/`EDSAPPL`）；欄位一律引用標準 DE（含 `MATNR18`、`ELIFN` 兩個易錯例子）。**待驗證項目已有結論：Claude 不能代建 Segment**（自建 Structure 不會寫入 `EDISDEF`/`EDSAPPL`），只能事後驗證。只定義結構，不送資料 | 承 ale03 | **✅ 已出題**（`ale06_custom_idoc_extension.md`；全程 GUI，等使用者建好後用 `EDISDEF`/`EDSAPPL`/`EDIMSG`/`EDBAS` 驗證並快照生成的 Structure） |
| ale07 | Outbound 客製化開發 | 觸發時機設計：Change Pointer 驅動 vs. Enhancement/BTE 掛勾手動觸發（銜接 Enhancement 課程 en02/en04 技巧）；自訂/標準 Function Module 組 IDoc、呼叫 `MASTER_IDOC_DISTRIBUTE` 發送；**再次練習 Partner Profile Outbound 設定** | 承 ale05/ale06 | 未出題 |
| ale08 | Inbound 客製化開發＋錯誤處理 | 自訂 Inbound Function Module（`WE57`/`BD51` 註冊 Process Code）；呼叫標準 BAPI 完成過帳；IDoc 狀態碼（51 錯誤／53 成功）；`BD87` 重新處理失敗 IDoc；**再次練習 Partner Profile Inbound 設定** | 承 ale07 | 未出題 |
| ale09 | 期末案例一：MIRO 觸發 Paper Company 自動記 AR | 自訂 Z 訊息類型端對端；Outbound 觸發點用 Enhancement／BTE 掛在 `MIRO` 存檔；Inbound 呼叫 `BAPI_ACC_DOCUMENT_POST` 用 Customer 科目過帳出 AR（Company A 做 Invoice Verification 認列 AP，Paper Company 鏡射記 AR） | 承 ale06～ale08 全部技巧 | 未出題 |
| ale10 | 期末案例二：STO Delivery Billing（`IV`）觸發對方 AP | 標準流程講解（`STO`→`Delivery`→`Billing IV`→輸出 `RD04`→標準 `INVOIC`／`IDOC_INPUT_INVOIC`→自動 AP，幾乎全靠 Customizing）；加客製化轉折（自訂 Z-Segment 擴充帶額外欄位，或掛 BAdI/User-Exit 做金額門檻覆核）——刻意跟 ale09（從零自訂）對照，示範「站在標準流程上加值」 | 承 ale06～ale09 | 未出題 |

> ale01 環境查證已完成（2026-08-24），詳細方法與結果見 `.claude/rules/sap-adt-mcp.md` 第 58 節；後續逐題踩坑記錄會持續累積寫進同一份規則檔。
