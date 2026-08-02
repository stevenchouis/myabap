# SAP ABAP RAP（RESTful Application Programming Model）後端開發課程

本課程教 **RAP 的後端 OData Service 開發**——資料模型（CDS）、商業邏輯（Behavior Definition：CRUD／Determinations／Validations／Actions）、服務發布（Service Definition／Service Binding）。**真正的 Fiori Elements 畫面設計（List Report／Object Page 版面配置、Draft 編輯體驗）不在本課程範圍內**，但因為要銜接後續規劃中的 Fiori Elements 課程，**CDS View 的 `@UI.*` Annotation 語法（Metadata Extension／`annotate view ... with { }`）會在 rap02 教到基礎語法**，讓學生知道怎麼寫、寫在哪裡，深入的畫面設計技巧留給 Fiori Elements 課程。課綱規劃中，**rap01～rap03 已出題**（2026-08-02）。

**⚠️ 開課前已實測查證的環境限制**（見 `.claude/rules/sap-adt-mcp.md` 第 40 節）：這個系統的 RAP 框架屬於**較舊世代（Classic RAP）**，CDS 編譯器不支援 `define view entity`（新式 View Entity 語法），BDEF 不支援 `strict` 子句——這兩者是目前 SAP 官方教材／認證預設使用的語法，本系統用不了。此外，**Service Binding 這個物件一律要由使用者在 Eclipse 用官方精靈手動建立＋Publish**（第 40.9 節已確認：用 ADT REST API 手動建的 Service Binding 缺少精靈才會觸發的後端註冊步驟，Publish 永遠失敗），Claude 只能建到 Service Definition 這一層為止。**✅ 已實測成功**：Eclipse 精靈建立＋Publish＋Preview 可以正常跑出 Fiori Elements List Report；發布成功後，**OData 端點外網可以直接用瀏覽器/Postman 測試**（只要用系統對外的正確主機名稱＋Port，不需要內網或 VPN——這點連帶更正了 REST 課程原本記載的「只能內網測試」，見第 15 節 2026-08-02 更正）。這些差異會在 rap01 開頭完整說明，之後每一課遇到都會再次提醒。

**⚠️⚠️ rap03 發現的重大限制（見 `.claude/rules/sap-adt-mcp.md` 第 43／44 節）：這個系統的 RAP Managed Runtime（CUD 寫入部分）被 SAP 官方標記為「尚未對外釋出」，任何 Managed BDEF 的 create/update/delete 執行到底層一律 Dump**（`CL_CSP_MD_METADATA_FACTORY` 的套件白名單機制，程式碼裡留著開發者自己寫的註解「csp isn't released for public usage until now」；SAP Community 一篇 2019-11 的貼文一字不差回報同樣問題，時間點跟這套系統的 S/4HANA 1909 高度吻合）。**因此課程從 rap03 起改成 Managed／Unmanaged 兩者都教**：Managed 語法當知識儲備（銜接未來 ABAP Cloud RAP 課程），**Unmanaged 是這系統上唯一能真正端對端執行、驗證的版本**（已用 EML＋`programrun` 完整驗證成功）。這個發現也連帶更正了先前「EML 沒辦法無頭驗證」的誤判——問題從來不是 EML，是 Managed Runtime 的致命 Dump 透過 RFC Bridge 傳回時卡住了連線。

## 課程定位

- **對象**：完成基礎課（`src/ABAP_Training/`）ex08 模組化、ex15 CHANGING+Table Type 的學員，需要能看懂 DDIC Table／CDS View／Class 的基本語法；不要求先修 OOP 課程，但有 OOP 基礎（`src/ABAP_Training_OOP/`）會更容易理解 Managed BDEF 背後「框架自動生成 Runtime 邏輯」的概念。
- **技術範圍**：DDIC Table → CDS Interface View（含基礎 `@UI.*` Annotation 語法，為銜接 Fiori Elements 課程鋪路）→ Behavior Definition **Managed 與 Unmanaged 兩者對照教學**（CRUD／Determinations／Validations／Actions／Associations，Managed 當語法知識儲備、Unmanaged 是這系統上真正能執行驗證的版本，見下方「Managed 與 Unmanaged 並行教學」）→ Service Definition → Service Binding（OData V2 為主，V4 只教概念不強求發布）。**不含**：Fiori Elements 完整畫面設計（List Report／Object Page 版面配置技巧、Draft 編輯體驗——這些留給後續規劃中的 Fiori Elements 課程）／真正的 ABAP Cloud 語言版本 RAP（見下方「與未來課程的關係」）。
- **結業標準（草案）**：能獨立設計一個 Header-Item 兩層式 Managed RAP BO（含 Determination 自動衍生欄位、Validation 擋非法資料、一個自訂 Action），寫出正確的 CDS／BDEF／Service Definition，並在系統允許的範圍內驗證服務可以發布。

## 與未來課程的關係：這是「Classic RAP」，不是「ABAP Cloud RAP」

RAP 框架本身從 SAP 導入以來就分成兩種寫法：
1. **Classic RAP**（本課程教的）：CDS 用舊式 `define view`（無 `entity` 關鍵字），BDEF 無 `strict` 模式，可以存取任何 DDIC 物件與 ABAP 語法，不受 ABAP Cloud 語言限制——這是**目前這個系統唯一能寫得出來、啟用得了**的版本（已實測驗證，見下方 rap01）。
2. **ABAP Cloud RAP**（SAP 現在主推、官方教材/認證的預設版本）：CDS 用新式 `define view entity`，BDEF 支援 `strict(2)` 等新語言特性，且**必須**搭配 ABAP Cloud 限制語法（只能用 Released API，見下方 rap01 對這個限制的完整說明），套件要啟用 ABAP Cloud 語言版本——這需要 S/4HANA 2022 以後的 On-Premise 系統，或 SAP BTP ABAP Environment（Cloud）。

這個落差不是本課程能解決的（受限於目前連線的系統版本），**待日後設定好一個支援 ABAP Cloud 語言版本的系統（Cloud ABAP Environment 或更新版 On-Premise）、建立對應的 MCP 連線之後，會另開一門課專門教 ABAP Cloud RAP，把兩者的語法差異、遷移注意事項講清楚**。本課程結束時學生會清楚知道「我學的是哪個版本、跟官方教材的落差在哪裡」，不會誤以為兩者完全一樣。

## Managed 與 Unmanaged 並行教學（rap03 起的重大調整）

原本規劃只教 Managed（見上面「不含 Unmanaged RAP」的舊決定），但 rap03 出題時發現：**這系統的 RAP Managed Runtime（CUD 寫入部分）被 SAP 官方標記為「尚未對外釋出」**——`CL_CSP_MD_METADATA_FACTORY` 這個類別會檢查 CDS Entity 所在的套件是否在一份硬編碼白名單裡（`SBOI_RAP_CSP_TST%` 等 SAP 內部套件），不在清單裡就用致命訊息（`MESSAGE ... TYPE 'X'`）擋下來，程式碼裡甚至留著開發者自己的英文註解「csp isn't released for public usage until now」。SAP Community 一篇 **2019-11** 的貼文一字不差回報同樣問題，時間點跟這套系統的 **S/4HANA 1909**（Eclipse Project 顯示的系統代號 `S4D_1909`）高度吻合，判斷是這個版本世代 Managed Runtime 寫入功能尚未對客戶套件開放的已知限制（詳細技術細節見 `.claude/rules/sap-adt-mcp.md` 第 43 節）。

**因應調整**：從 rap03 起，**Managed 與 Unmanaged 兩者都教，並列比較**：

- **Managed**：語法教學＋能啟用，但明確告知「這系統執行不了」，當作**知識儲備**——語法跟官方教材／未來的 ABAP Cloud RAP 課程一致，銜接用
- **Unmanaged**：語法教學＋**已用 EML＋`programrun` 完整驗證成功**（含資料庫寫入確認），這系統上真正能讓學生看到「資料真的寫進去了」的路徑；份量比原計畫重（需要自己寫實作類別的 `LOCK`/`CREATE`/`READ` 方法），但既然 Managed 走不通，這是必要的取捨

這個發現還有一個意外收穫：原本第 42 節記錄的「EML 沒辦法用 `programrun` 無頭驗證」是誤判——用 Unmanaged BDEF 測試完全無頭驗證成功，證實問題從來不是 EML 這個語言機制，是 Managed Runtime 的致命 Dump 透過 RFC Bridge 傳回時卡住了連線（已更正）。

**對 rap05～rap07 的影響**：Determination／Validation／Action 在 Unmanaged 模式下沒有 Managed 那種宣告式語法（`determination ... on save` 這類），邏輯要自己寫在實作類別裡——這幾課出題時要重新評估教法，屆時再定案。

## 教材慣例（比照 OOP/REST/AMDP/Enhancement 課程）

- 每題三件套：題目 `rapNN_主題.md` + PDF 講義（`node tools/md2pdf.js src/ABAP_Training_RAP`）+ 答案快照
- 每題 md 開頭（`## 學習目標` 之前）要有 `## Lecture` 完整背景知識講解
- 物件命名慣例（沿用查證階段已驗證可行的模式）：
  - DDIC Table：`ZRAPnn_<實體>`（如 `ZRAP02_TASK`）
  - **欄位型別（見 `.claude/rules/abap-style.md` 硬性規則）**：語意對應標準表既有欄位一律直接引用標準 Data Element（如 `TEXT100`），先用 quickSearch 查證不要憑記憶猜；沒有合適標準 DE 才自己建 `ZRAPnn_<欄位>` 命名的 Domain＋Data Element（同名），不可以留著 `abap.char(...)` 這類內建型別
  - CDS Interface View：`ZI_RAPnn_<實體>`，Behavior Definition 直接綁在同名 CDS View 上（本系統是單層模式，Interface View 直接掛 BDEF，不強制要有獨立的 Projection View 兩層架構，除非題目要示範多消費場景）
  - Metadata Extension（UI Annotation）：跟系統既有標準物件命名慣例一致，**直接沿用同名**（如 `ZI_RAPnn_<實體>`）——DDLX 跟 DDLS 是不同物件型別，同名不衝突，Eclipse 建立精靈選擇要擴充的 CDS View 之後會自動帶出這個名稱
  - Service Definition：`ZRAPnn_SD`；Service Binding：`ZRAPnn_SB`
  - EML／其他驗證用程式：`ZR_RAPnn_DEMO`（Managed 版本）／`ZR_RAPnn_DEMO_UM` 或類似後綴（Unmanaged 版本，沿用 sf／rs 課程 `ZR_<課程代碼>nn_DEMO` 的命名慣例再加註記）
  - **Unmanaged 實作類別**：`ZBP_I_RAPnn_<實體>`，Global 類別本體只是空殼＋`FOR BEHAVIOR OF <view>` 子句，真正的 Handler 邏輯寫在 Local Types Include（PUT 到 `/sap/bc/adt/oo/classes/<class>/includes/implementations`，可以完全交給 ADT API 自動建立，不需要 Eclipse 精靈，見第 44 節）
- 每題原始碼快照：Table 用 `.tabl.abap`、CDS View 用 `.ddls.abap`（沿用第 16 節 DDLS 快照慣例）、Metadata Extension 用 `.ddlx.abap`、BDEF 用 `.bdef.abap`、Service Definition 用 `.srvd.abap`、驗證用程式用 `.prog.abap`、Unmanaged 實作類別用 `.clas.abap`（Global 本體）＋`.clas.locals_imp.abap`（Local Handler 實作，沿用 abapGit 慣例）；Domain／Data Element 是結構化物件（非 source-based），存 `.doma.xml`／`.dtel.xml`；Service Binding 同樣結構化（見查證階段第 40.5 節），存 `.srvb.xml`
- **✅ 已更正（第 42／44 節）：EML 完全可以用 `programrun` 無頭驗證**——原本第 42 節記錄「EML 沒辦法無頭驗證」是誤判，真正卡住的原因是 Managed Runtime 的致命 Dump（見上方「Managed 與 Unmanaged 並行教學」），Unmanaged BDEF 的 EML 已用 `programrun` 完整驗證成功。**Managed BDEF 的 EML 驗證程式則反過來——不要嘗試用 `programrun` 或請使用者在 SAP GUI 執行，一律會 Dump，這是預期中的已知限制，只需確認語法正確、成功啟用即可**

## 課綱（規劃中，rap01～rap03 已出題）

| # | 主題 | 內容重點 | 銜接前面課程 | 狀態 |
|---|---|---|---|---|
| rap01 | 為什麼用 RAP？環境限制聲明 | RAP 在 SAP 開發架構中的定位（對比 Function Module／BAPI／classic report／既有課程學過的技術）；Managed vs Unmanaged 概念對照（系統既有標準物件 `C_SalesOrderManage` 就是 Unmanaged；⚠️原本規劃只教 Managed，rap03 發現這系統 Managed CUD 執行不了後改成兩者並教，見 README「Managed 與 Unmanaged 並行教學」）；**完整說明已查證的環境限制**：Classic RAP vs ABAP Cloud RAP 語法差異（無 `view entity`、無 `strict`）、ABAP Cloud 限制語法是什麼（Released API／禁用 Classical Dynpro 等）、OData V2 vs V4 發布能力差異；RAP 五層架構總覽（Table→Interface View→BDEF→Service Definition→Service Binding） | 呼應基礎課 ex08 模組化、REST 課程（`src/ABAP_Training_REST/`）的服務導向概念 | **已出題** |
| rap02 | CDS Interface View 資料模型基礎＋Metadata Extension（UI Annotation）入門 | **Part A－資料模型**：DDIC Table 設計（沿用第 34/39 節的 annotation 慣例）；**欄位型別一律引用 Data Element 的硬性規則**——有標準 DE 直接重用（`description` 用 `TEXT100`），沒有合適標準 DE 就自建 Domain＋DE（`task_id`／`status`／`priority`／`due_date` 各建一組，`status`/`priority` 示範固定值清單語法，並澄清固定值只在 UI 層生效不是資料庫約束）；CDS 舊式 `define root view`（本系統適用版本）；必要 annotation：`@AbapCatalog.preserveKey`／`@ObjectModel.compositionRoot`／`@AccessControl.authorizationCheck`；欄位別名與 `mapping for` 的取捨。**Part B－Metadata Extension（獨立小節，第 40.10 節已查證：`@UI.*` 跟 Classic/ABAP Cloud RAP 語法版本無關，這個系統完全支援）**：CDS View 要先開 `@Metadata.allowExtensions: true` 才能被擴充；Metadata Extension（DDLX）是**獨立物件**，跟 CDS View 同名但不同物件型別（`DDLX/EX`）；本系統適用的舊式語句 `annotate view ZI_XXX with { ... }`（不是新式的 `annotate entity`）；教三個最常用的 `@UI.*` 標記——`@UI.headerInfo`（Object Page 標題）／`@UI.lineItem`（List Report 表格欄位）／`@UI.selectionField`（篩選欄位）；**這一節只教語法本身跟寫在哪裡（DDLX 物件怎麼建、annotate 語句怎麼寫），不深入 List Report／Object Page 版面設計邏輯**，完整畫面配置留給 Fiori Elements 課程 | 承基礎課 DDIC 表格設計、AMDP 課程 CDS Table Function 的 DDLS 建立流程 | **已出題**（`ZRAP02_TASK` 表格＋4 組 Domain/DE＋`ZI_RAP02_TASK` View＋Metadata Extension 均已建立啟用，`sap_inactive_objects` 確認 0 筆殘留） |
| rap03 | Behavior Definition 基礎——Managed 與 Unmanaged 對照 | **Part A－Managed（知識儲備）**：`managed;` header（本系統不支援 `strict`）；`persistent table`／`lock master`；CRUD 操作宣告；`field ( readonly )`／`field ( mandatory )` 欄位控制；ETag 語法（第 40.11 節：這系統是 `etag <欄位>`，不帶 `master`）；語法正確但**這系統執行不了**（第 43 節：`CL_CSP_MD_METADATA_FACTORY` 套件白名單機制，Managed Runtime 尚未對客戶套件開放，判斷跟 S/4HANA 1909 版本有關，SAP Community 2019-11 貼文佐證）。**Part B－Unmanaged（這系統真正能跑的版本）**：`implementation unmanaged in class ... unique;`（無 `persistent table`）；實作類別繼承 `cl_abap_behavior_handler`，`FOR LOCK`/`FOR MODIFY`/`FOR READ` 方法綁定語法（照抄標準物件 `CL_SD_BEHV_SALESORDERMANAGE` 的真實寫法）；**已用 EML＋`programrun` 完整驗證成功**（資料真的寫進資料庫，且證實 EML 本身完全支援無頭執行，第 42 節原本的「EML 會卡住」誤判已更正，真正原因是 Managed Runtime Dump）。**Part C**：Managed vs Unmanaged 差異總表 | 承 rap02 | **已出題**（Managed：`ZI_RAP02_TASK` BDEF＋`ZR_RAP03_DEMO`；Unmanaged：`ZRAP03_UMTEST`／`ZI_RAP03_UMTEST`／`ZBP_I_RAP03_UM4`／`ZR_RAP03_UMTEST`，全部建立啟用，Unmanaged 已驗證執行成功） |
| rap04 | Service Definition／Binding 與發布流程 | `define service`／`expose ... as ...`；**Service Binding 一律由使用者在 Eclipse 用官方精靈手動建立**（第 40.9 節已確認：用 ADT REST API 手動建的 Service Binding 缺少精靈才會觸發的後端註冊步驟，Publish 永遠失敗且錯誤訊息極具誤導性，Claude 不再嘗試 API workaround）；Claude 負責前面四層（Table／CDS View／BDEF／Service Definition）的建立與驗證，Service Binding 建立＋Publish 是操作指引，由使用者截圖回報（比照 Smartform 課程模式）；OData V2 技術服務名稱＝ Binding 物件名稱；**已實測成功**：Eclipse 精靈建立＋Publish＋內建 Preview 開出 Fiori Elements List Report；就算發布成功，外部（Postman/瀏覽器）連線是否可達仍取決於使用者當下網路位置，需要每次確認；**⚠️ 出題時要考慮**：如果要示範「Publish 後真的能在 Fiori Elements 畫面上 Create 一筆資料」，底層 BDEF 要用 rap03 的 Unmanaged 版本，Managed 版本 Publish／Preview（唯讀）沒問題，但畫面上按 Create 一樣會 Dump | 承 REST 課程對 OData／服務發布概念的鋪墊、rs07 的 `cl_http_client` 自我呼叫驗證手法（V2/V4 都適用，作為 Claude 端無頭驗證的備案） | 待出題 |
| rap05 | Determinations（自動衍生欄位） | `determination ... on save`／`on modify`；典型情境：建立時自動填當前時間戳、由其他欄位算出衍生值；跟 Trigger／資料庫層自動欄位的差異（Determination 是應用層邏輯，跑在 RAP Runtime）；**⚠️ 出題時要重新評估**：Managed 的宣告式 `determination` 語法這系統執行不了，Unmanaged 模式下要怎麼示範等效邏輯（直接寫在 `CREATE`/`UPDATE` 方法裡，或是否有其他掛勾點）待查證 | 承 rap03 | 待出題 |
| rap06 | Validations（資料完整性檢查） | `validation ... on save`；`report failed`／`message` 語法回報錯誤給前端；跟傳統 `AUTHORITY-CHECK`／手動 `SELECT` 檢查的角色區隔；**⚠️ 出題時要重新評估**：同 rap05，Unmanaged 模式下的等效教法待查證 | 承 rap05 | 待出題 |
| rap07 | Actions（自訂操作） | `action`／`static action`／`factory action`；`parameter`／`result`子句；跟標準 CRUD 操作的差異；**⚠️ 出題時要重新評估**：Unmanaged BDEF 的 Action 語法／實作類別對應寫法待查證（第 40 節查證階段讀過的 `C_SalesOrderManage` 標準物件本身就有多個 Action，可以參考它的實作模式） | 承 rap03 | 待出題 |
| rap08 | Associations／Compositions（多層結構） | Header-Item 兩層式設計；`composition [0..*] of`（本系統的 Classic RAP 語法）；Cascading Delete；巢狀 CRUD（一次呼叫同時處理 Header 與 Item） | 承 rap02～rap07 全部技巧 | 待出題 |
| rap09 | 期末綜合實作（Capstone） | 整合全部技巧，設計一個「訂單」情境（Header-Item＋一個 Determination＋一個 Validation＋一個 Action），完整跑過 Table→CDS→BDEF→Service Definition→（能發布則發布，否則驗證到語法/啟用為止）的全流程 | 呼應各課程 Capstone 慣例（`sf06`／`ex28`） | 待出題 |

> 開課前查證的完整技術細節（含每個踩到的錯誤訊息、workaround 語法）記錄在 `.claude/rules/sap-adt-mcp.md` 第 40 節，rap01 會摘要說明給學生，出後續題目時遇到新狀況會持續補充該節。
