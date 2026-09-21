# ALE 課程 10：期末案例二——STO Delivery Billing（`IV`）觸發對方 AP

## Lecture

ale09 是「從零自訂」——Message Type、Segment、Outbound、Inbound 全部自己寫。這題是刻意的對照：**站在標準流程上加值**。

集團內兩家公司之間的**跨公司庫存調撥（STO，Stock Transport Order）**，SAP 標準就有一整條現成流程，**幾乎不用寫一行 ABAP**：

```text
STO（供貨方為 Supplying Plant）
  → Delivery（出貨）
  → Billing（計費類型 IV：Intercompany Billing，向收貨方開立內部發票）
  → 計費文件存檔時 Output Determination（Application V3，輸出類型 RD04）判斷要不要產生輸出
  → 輸出媒介為 EDI（媒介 6）→ 標準 IDoc 訊息類型 INVOIC
  → 收貨方系統 Inbound：標準 Function Module 自動過帳成應付帳款（AP）
```

回顧 ale05 的三種觸發機制：這條流程用的是「**Output Determination（半自動）**」——觸發時機（計費文件存檔）是系統原生的、要不要送由條件記錄決定，沒有任何自訂掛勾點。所以這題的重點跟 ale09 完全不同：**不是開發，而是讀懂並驗證一條標準流程，再用最小的擴充點為它加值**。

### 這個系統已經有這條流程的真實歷史（2026-09-21 實測）

用 `datapreview/freestyle` 查這個系統的 `INVOIC` 訊息類型，會發現**這條標準流程以前真的被人跑過**——不需要憑空設想，可以直接拿真實資料當教材：

- `EDIDC` 有 115 筆 `INVOIC` IDoc，建立日期 2020-08-23 至 2023-04-07；Outbound（`DIRECT`＝`1`）8 筆狀態 `03`；Inbound（`DIRECT`＝`2`）共 107 筆：**`53` 成功 7 筆、`51` 應用層失敗 91 筆、`56` 結構／設定失敗 9 筆**
- Outbound Partner Profile（`EDP13`）：Partner `A1000`（Partner Type `KU`＝客戶）、Port `A000000003`、Basic Type `INVOIC01`；Inbound（`EDP21`）：Partner Type `LI`（供應商 `A2000`）與 `LS`（`S4HCLNT100`），Process Code `INVF`／`INVL`
- **`NAST`** 有大量 `KAPPL`＝`V3`、`KSCHL`＝`RD04`、`NACHA`＝`6` 的記錄——證實 Output Type `RD04` 屬於 **Application `V3`（Billing）**，媒介 `6` 就是 EDI／ALE 路徑（ale05 已據此更正 Application 編號：`V1`＝Sales、`V2`＝Shipping、`V3`＝Billing）
- **`EDIFCT`（`WE57` 的資料表）**：`INVOIC` 的 Inbound Function Module 有 `IDOC_INPUT_INVOIC_FI`（連結物件 `BKPF`／`BUS2020`，直接記財務憑證）與 `EDX_INPUT_INVOIC_MRM`（連結物件 `BUS2081`，走**物流發票驗證**，也就是 `MIRO` 那條路）

### 兩個 Process Code：`INVF` 與 `INVL`

Inbound 用哪個 Process Code，決定「收進來的發票怎麼入帳」：

- **`INVF`**（FI 路徑）：直接在財務模組記帳，不經過採購訂單
- **`INVL`**（Logistics 路徑）：走物流發票驗證，發票會**對照採購訂單／收貨記錄**——STO 情境的收貨方本來就有對應的 STO 採購訂單，`INVL` 才能做到三方比對

### 從真實失敗學除錯：`56` 與 `51`

`EDIDS` 實測這個系統的真實失敗訊息（原文為中文介面）：

- IDoc `…20019`（狀態 `56`）：**「EDI：內傳夥伴設定檔不存在」**——Inbound Partner Profile 沒設，屬於 **ale08 講的「56＝設定或結構問題」**
- IDoc `…20001`（狀態 `51`）：狀態歷程 `50`→`64`→`62`→`51`，訊息 **「文件 & 不存在」**——IDoc 順利進入處理邏輯（`62` Passed to application）但應用層找不到某份文件，屬於「51＝資料問題」
- 對照成功的 IDoc `…19098`（狀態 `53`）：歷程 `50`（IDoc added）→`64`（Ready to be passed to application）→`62`（Passed to application）→`53`，訊息「文件號 & 已建立」。**這是完整成功路徑的標準狀態序列**（補充 ale03 常見狀態碼表：`50`＝IDoc added、`62`＝IDoc passed to application）

### INVOIC IDoc 的結構

成功的 IDoc `…19098` 共 58 個 Segment、20 種 Segment 類型（`EDID4` 實測）：

| Segment | 出現次數 | 業務意義 |
|---|---|---|
| `E1EDK01` | 1 | 發票表頭（幣別 `CURCY`、單據編號 `BELNR` 等，全域唯一的根） |
| `E1EDKA1` | 5 | 夥伴資訊（賣方、買方、送貨對象、付款人……用 `PARVW` 限定詞區分角色） |
| `E1EDK02` | 4 | 參考單號（`QUALF` 限定詞區分：訂單號、送貨單號……） |
| `E1EDK03` | 7 | 日期（`IDDAT` 限定詞區分：開立日、到期日……） |
| `E1EDK14` | 7 | 組織資料（銷售組織、公司代碼……） |
| `E1EDP01` | 1 | 明細項目（每個項次一筆，底下掛 `E1EDP02` 參考單號、`E1EDP03` 日期、`E1EDP04` 稅、`E1EDP26` 金額……） |
| `E1EDS01` | 5 | 彙總（總金額、稅額合計……） |

（表中只列主要類型，其餘為明細與稅務的附屬 Segment。）注意一個重要的**結構規律**：`E1EDK01`、`E1EDKA1`、`E1EDK02` 在 `EDID4` 裡 `PSGNUM` 都是 `000000`——它們是**同一層的兄弟 Segment**，不是父子關係。

### 站在標準流程上加值：Customer Exit

標準 SD 發票 Outbound 程式提供 SMOD 增強 **`LVEDF001`**（2026-09-21 實測：`EXIT_SAPLVEDF_001`～`004` 四個 Function Exit，Include 分別是 `ZXEDFU01`～`ZXEDFU04`）。這題用其中兩個：

- **`EXIT_SAPLVEDF_001`**：可以改 **Control Record**（`control_record_out`）——我們在這裡告訴系統「這筆 IDoc 用了 Extension `ZALE10_INVEXT`」。它還有 `DATA_NOT_RELEVANT_FOR_SENDING` 例外，可以直接**取消這筆 IDoc 的產生**
- **`EXIT_SAPLVEDF_002`**：可以改 **IDoc 資料表**（`int_edidd`）——我們在這裡插入自己的 Segment。收到的 `xvbdkr` 是計費文件表頭（含 `vbeln`、`netwr`、`waerk`、`vkorg`）

**加值需求（金額門檻標記）**：集團財務要求「內部調撥發票金額達門檻者，接收方要人工覆核」。我們**不改標準流程、不攔截發票**，只是在**達門檻的發票**的 IDoc 上多帶一個 **Extension Segment `Z1ALE10`**，內含計費文件號碼、淨額、幣別，以及一個**覆核旗標**——是否達門檻由控制表 `ZALE10_CTRL`（依銷售組織）決定，沒登記的銷售組織完全不加 Segment（沿用一貫的安全閘）。接收方要不要據此攔截覆核，屬於接收方的另一段開發，本題不展開。

> **⚠️ 插入位置很重要**：`Z1ALE10` 在 `WE30` 是掛在 `E1EDK01` 底下的子節點，IDoc 資料表裡就**必須緊接在 `E1EDK01` 之後**，不能像 ale07 的 `MATMAS` 那樣「Exit 被呼叫的當下 APPEND 到表尾」——INVOIC 的 Exit 是**整張 IDoc 都組好之後**才呼叫的，表尾已經是明細與彙總 Segment。所以 `fill_segment` 要先找到 `E1EDK01` 的位置，再 `INSERT ... INDEX`。ale06 的 `WE60` 檢視會告訴你 `Z1ALE10` 排在兄弟 Segment 的哪個位置；IDoc 資料順序必須與結構定義的順序一致，否則語法檢查失敗（狀態 `26`）。

## 學習目標

- 能畫出並說明 STO 跨公司計費→EDI→對方 AP 的標準流程，指出每個環節用了 ALE 課程的哪個機制（Output Determination、Partner Profile、Process Code、`WE57`）
- 能用 `EDIDC`／`EDIDS`／`EDID4`／`EDIFCT`／`NAST` 分析一條真實的標準 IDoc 流程，分辨 `53`／`51`／`56` 並解讀失敗訊息
- 能說出 `INVF` 與 `INVL` 的差異及適用情境
- 能用 Customer Exit（`EXIT_SAPLVEDF_001`／`002`）在標準流程上加值，並正確處理 Extension Segment 的插入位置
- 能對比 ale09（從零自訂）與本題（標準加值）在開發量與風險上的差異

## 事前準備

- ale06 的 Extension 建立流程已熟練
- Part A、B 為**唯讀分析**，不需要任何異動；Part C（端對端）是選做，需要有權限且有測試資料的 STO 情境（STO→Delivery→`IV` 計費）

## 題目需求

### Part A：分析真實的標準 IDoc（唯讀）

1. `WE02` 查 Message Type `INVOIC`，找出成功（`53`）與失敗（`51`／`56`）各一筆 Inbound IDoc（系統上例如 `…19098`、`…20001`、`…20019`）
2. 對成功的那筆，展開 Data Records，記下 Segment 類型與次數，說明 `E1EDK01`／`E1EDKA1`／`E1EDK02`／`E1EDP01` 各自代表什麼；找出 `E1EDKA1` 有哪幾種夥伴角色（`PARVW`）
3. 對失敗的兩筆，展開 Status Record，記下狀態歷程與訊息文字，分類成「設定問題（`56`）」或「資料問題（`51`）」，並說明各自該去哪裡修
4. `WE20` 檢視 Partner `A1000`（`KU`）的 Outbound 與 Partner `A2000`（`LI`）的 Inbound 設定；說明為什麼 Outbound 的 Partner Type 是 `KU`（客戶）、Inbound 的是 `LI`（供應商）

### Part B：讀懂 Output Determination 那一半（唯讀）

1. `NACE`：Application `V3`、Output Type `RD04`，確認 Processing Routines 有 EDI 媒介的那一列（延續 ale05 步驟 1）
2. `VF03` 開一張計費類型 `IV` 的既有文件（用 `VF05` 篩 `FKART`＝`IV`），看 Output 頁籤裡 `RD04` 的處理狀態與 Processing Log，找出對應的 IDoc 號碼
3. 回答：從計費文件存檔到 IDoc 產生，中間**有沒有任何一行自訂 ABAP**？如果有人說「我們要在發票存檔時送 IDoc」，你要問他哪三件事？（答案方向：條件記錄有沒有維護、`RD04` 的 EDI 媒介設定、Partner Profile）

### Part C：Customer Exit 加值（ABAP＋GUI）

1. **資料表** `ZALE10_CTRL`：Key＝`mandt`／`vkorg`（`vkorg`）；欄位＝`netwr`（`netwr`，門檻金額）、`waerk`（`waerk`，門檻幣別）、`active`（`xfeld`）
2. **Segment**（`WE31`，Field name 與 Data element 同名）：`Z1ALE10`＝`VBELN_VF`／`NETWR`／`WAERK`／`XFELD`；記下 `WE31` 顯示的各欄位匯出長度（尤其 `NETWR`）並回報
3. **Extension**（`WE30`）：`ZALE10_INVEXT`，連結 Basic Type `INVOIC01`，在 `E1EDK01` 底下新增 `Z1ALE10`（Min `0`／Max `1`）；Set Release；`WE82` 指派（`INVOIC`＋`INVOIC01`＋`ZALE10_INVEXT`）；`WE60` 記下 `Z1ALE10` 相對於兄弟 Segment 的位置
4. **Class `ZCL_ALE10_INVOIC_EXT`**：`get_ctrl`（讀控制表，沒有 `active` 就回傳空）、`build_segment`（純邏輯：組出 `Z1ALE10` 資料列，淨額 `>=` 門檻時覆核旗標為 `X`）、`fill_control`（有 `active` 對應時把 `cimtyp` 設成 `ZALE10_INVEXT`）、`fill_segment`（有 `active` 對應時，找到 `E1EDK01` 的位置並在其後插入 `Z1ALE10`）
5. **`CMOD`**：建專案 `ZALE10`→指派 `LVEDF001`→雙擊 `EXIT_SAPLVEDF_001`／`002` 生成 Include `ZXEDFU01`／`ZXEDFU02`（生成後由 Claude 寫入呼叫 Class 的程式碼）→ **Activate Project**
6. **ABAP Unit**：`build_segment`（門檻上下的旗標、欄位內容）
7. （選做，需要測試資料）`WE20` 的 `INVOIC` Outbound 填入 Extension、`ZR_ALE10_CTRL` 類似的方式維護 `ZALE10_CTRL`（可以直接用 `SE16N` 或自己仿照 `ZR_ALE08_CTRL` 寫維護報表）登記你的銷售組織，走一次 STO 計費，用 `WE02` 確認 Outbound IDoc 的 Control Record 有 Extension、資料裡有 `Z1ALE10`

## 參考答案（驗證方式）

**參考答案程式碼**已快照在本目錄：`zale10_ctrl.tabl.abap`、`zcl_ale10_invoic_ext.clas.abap`（＋`.clas.testclasses.abap`）、`zxedfu01.prog.abap`、`zxedfu02.prog.abap`。

> **⚠️ 狀態：草稿，尚未經 SAP 語法檢查與執行驗證**（依賴 `Z1ALE10` Segment，且 Exit 的插入位置與 IDoc 語法順序尚待用真實 STO 計費驗證）。待驗證清單見 README。

Part A／B 的參考答案：

- **Segment 結構**：見 Lecture 表格；`E1EDKA1` 的角色用 `PARVW` 區分（賣方／買方／付款人／送貨對象等），請以你在 `WE02` 實際看到的值為準
- **失敗分類**：「內傳夥伴設定檔不存在」（`56`）→ 去 `WE20` 補 Inbound Partner Profile；「文件不存在」（`51`）→ 檢查被引用的採購訂單／收貨文件是否已建立、是否對到正確的公司代碼
- **`KU` vs. `LI`**：Outbound 站在供貨方角度，對方是「向我買東西的客戶」→`KU`；Inbound 站在收貨方角度，對方是「賣東西給我的供應商」→`LI`。**同一條交易，兩邊系統看對方的身分不同**（呼應 README 的 Inbound/Outbound 判斷提醒）
- **Part B 第 3 題**：沒有任何自訂 ABAP；要問的三件事＝條件記錄有沒有維護、`RD04` 的 EDI 媒介設定、Partner Profile

驗證要點（Part C 完成後回報）：`SELECT MESTYP, IDOCTP, CIMTYP FROM EDIDC WHERE MESTYP = 'INVOIC' ORDER BY DOCNUM DESCENDING`（新 IDoc 的 `CIMTYP`）；`SELECT SEGNUM, SEGNAM, PSGNUM FROM EDID4 WHERE DOCNUM = '<IDoc號>' ORDER BY SEGNUM`（`Z1ALE10` 在 `E1EDK01` 之後、`PSGNUM` 指向它）；`SELECT * FROM EDSAPPL WHERE SEGTYP = 'Z1ALE10'`。

## 思考題

1. ale09 與 ale10 都是「發票→對方帳務」，一個從零自訂、一個站在標準上加值。如果你是專案負責人，什麼情況下你會選 ale09 的路線，什麼情況選 ale10？（提示：想想標準流程能不能滿足 90% 的需求，以及升級時各自的維護成本）
2. `EXIT_SAPLVEDF_001` 可以 `RAISE DATA_NOT_RELEVANT_FOR_SENDING` 取消整筆 IDoc。這個能力很強也很危險——如果有人在裡面寫了一個寫死的條件，會有什麼後果？你會怎麼設計，讓「哪些發票不送」可以被財務人員看見與審計？
3. Part A 的真實資料裡 `51` 有 91 筆、`56` 有 9 筆，成功的只有 7 筆。從這個比例，你會對這條流程的「上線前測試」與「監控機制」得出什麼結論？
4. 覆核旗標是加在 Outbound 的。如果接收方**不開發任何東西**，這個旗標有沒有價值？（提示：想想 `WE02` 人工檢視、以及 IDoc 資料本身作為稽核軌跡的價值）

## 答案

Part A／B 為唯讀分析，答案見上方；Part C 的參考答案程式碼見快照檔，`CMOD` 專案與 Activate Project 為 GUI-only（見 `.claude/rules/sap-adt-mcp.md` 第 20／21 節）。選做的端對端請回報 IDoc 號碼與 `WE60` 觀察到的 Segment 位置。
