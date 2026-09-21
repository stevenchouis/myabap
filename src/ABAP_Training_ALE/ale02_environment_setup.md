# ALE 課程 2：ALE 環境設定實戰

## Lecture

ale01 講過 ALE 的三大設定：Distribution Model（`BD64`）、Partner Profile（`WE20`）、Port（`WE21`），外加 Master Data 分送要用到的 Change Pointer 全域開關（`BD61`）。這四個交易碼在 ale01 已查證**全部是 `TRAN` 型別、完全沒有 ADT API**（見 `.claude/rules/sap-adt-mcp.md` 第 58 節），本題**全程走 SAP GUI 操作指引**，Claude 負責寫清楚每一步的畫面/欄位，並在你操作完成後用 `datapreview/freestyle` 查字典表（`EDIDC`／`TBDLS` 等）幫你驗證結果。

### 為什麼要先建 RFC Destination（`SM59`）——ALE 環境設定其實是四件事，不是三件事

ale01 沒提到 `SM59`，但實務上 ALE 要能真的「送出去」，**Port（`WE21`）背後一定要有一個可用的通訊管道**——如果 Port 類型選 `A`（tRFC，最常見的系統對系統類型），這個 Port 就要指向一個**已經設定好的 RFC Destination**（`SM59`）。所以完整的 ALE 環境設定順序其實是：

```text
SM59（建 RFC 連線）→ WE21（Port，引用 SM59 那個連線）→ WE20（Partner Profile，引用 WE21 那個 Port）→ BD64（Distribution Model，宣告誰跟誰同步什麼）
```

`SM59` 同樣是純 Customizing 交易碼（`TRAN` 型別），這裡直接查證一併確認：

### ✅ 已查證：`SM59` 也是 `TRAN` 型別，無 ADT API

（查證方式同 ale01：`SELECT OBJECT, OBJ_NAME FROM TADIR WHERE OBJ_NAME = 'SM59'` → `OBJECT = 'TRAN'`）——這題的四個交易碼（`SM59`／`WE21`／`WE20`／`BD64`）加上 `BD61`，全部同一類，本題所有步驟都是 GUI 操作。

### 本題的特殊設計：單一 Client 自我迴圈測試（Self-Loop）

正常 ALE 情境是兩個不同系統（或至少兩個不同 Client）互傳，但這門課只有 `130` 這個 Client 的存取權限，所以本題採用 SAP 官方教材也常用的**自我迴圈測試法**：讓這個系統的 RFC Destination／Port／Partner Profile 都**指向自己**，IDoc 送出去之後繞一圈回到同一個 Client 被處理。

**這個設計對 Inbound/Outbound 判斷原則反而是更好的練習機會**：因為只有一個 Client，你會在**同一個 Partner Profile 畫面**裡把 Outbound 跟 Inbound 兩個區塊**都填一遍**——這正好讓你清楚看到這兩個區塊本質上是完全獨立的兩組設定（一組管「送出去要走哪個 Port」，一組管「收進來要用哪個 Process Code 處理」），只是這次剛好同時發生在同一張畫面上。**在真實的兩個系統情境下，這兩個區塊會分別出現在兩台不同系統各自的 `WE20` 畫面上**（A 系統只填 Outbound、B 系統只填 Inbound）——ale04／ale07／ale08 會提醒你回頭對照這一題的自我迴圈設定，體會「單 Client 兩區塊都填」跟「雙系統各填一半」的對應關係。

### 系統現況（已查證，2026-08-24）

- 這個系統（`S4H`）目前有 10 個 Client：`000`/`100`/`110`/`120`/**`130`（屏科大，本課程使用中）**/`135`/`140`/`150`/`200`/`400`
- `TBDLS`（Logical System 登記表）**已經有** `S4HCLNT130` 這筆資料（SAP 標準命名慣例：`<SID>CLNT<Client>`），代表 Logical System 的**名稱**已經存在，但不代表它已經被**指派**成 Client 130 自己的 Logical System（這是兩件事，見下方步驟 2）
- 找了一個既有物料 `000000000000000021`（物料類型 `FERT`，成品）供本題結尾的 IDoc 送測使用——用「現有物料的現有資料」送一次 `MATMAS` IDoc 給自己，等於是把它現在的資料再存一次，不會產生任何實質資料變動，是安全的測試方式

## 學習目標

- 能獨立完成 ALE 環境設定四件事（`SM59`／`WE21`／`WE20`／`BD64`）＋Change Pointer 全域開關（`BD61`）
- 能在 Partner Profile 正確分辨 Outbound／Inbound 兩個區塊各自負責什麼、什麼時候該填哪一個
- 理解「自我迴圈測試」為什麼是有效的 ALE 驗證手法，以及它跟真實雙系統情境的對應關係
- 能用 `WE19` 測試工具送出一筆 IDoc，並用 `WE02`/`WE05` 確認狀態

## 事前準備

不需要新建任何 SAP 物件，但**本題全部步驟都要在 SAP GUI 操作**，Claude 這邊沒有 ADT 工具可以代勞。操作前請先確認：

- 用 SAP GUI／Eclipse 已登入系統，Client `130`
- 有 `SM59`／`WE21`／`WE20`／`BD64`／`BD61`／`WE19` 這幾個交易碼的執行權限（一般開發者帳號通常都有，若卡在權限不足，需要請 Basis 開權限）

## 題目需求

### 步驟 1：`SM59` 建立 RFC Destination（自我迴圈）

1. 交易碼 `SM59` → 左側樹狀節點選 **ABAP Connections**（連線類型 3）→ 工具列 **Create**
2. **RFC Destination** 欄位填 `S4HCLNT130`（沿用 Logical System 命名慣例，方便辨識）
3. **Connection Type** 選 `3`（ABAP Connection）
4. **Description** 填 `Self-loop for ALE training (client 130)`
5. 切到 **Technical Settings** 頁籤：
   - **Target Host**：填這個系統自己的 Application Server 主機名稱（可以在 SAP GUI 狀態列或 `SM51` 查到，通常跟你現在登入用的主機一樣）
   - **System Number**：填這個系統的 Instance Number（同樣可從登入畫面/`SM51` 查到）
6. 切到 **Logon & Security** 頁籤：
   - **Client**：`130`
   - **User**：你自己的登入帳號
   - **Authorization for Logon**：選 **Current User**（沿用目前登入的認證）或填死帳密皆可，訓練用途選 Current User 較方便
7. 存檔，按工具列 **Connection Test**——出現連線成功的回應時間資訊即代表正確；若失敗，最常見原因是 Target Host／System Number 填錯，回頭用 `SM51` 核對

### 步驟 2：`SALE`／`BD54` 確認並指派 Logical System

1. 交易碼 `BD54`（顯示既有 Logical System 清單，等同 `SALE` 選單路徑 **Sending and Receiving Systems → Logical Systems → Define Logical System**）
2. 確認清單裡已經有 `S4HCLNT130`（ale02 事前查證已確認存在）——**不用重新建立**，這步只是核對
3. 交易碼 `SALE` → 選單路徑 **Sending and Receiving Systems → Logical Systems → Assign Logical System to Client**（或直接交易碼 `SCC4` 顯示 Client 維護畫面，檢查 `Logical system` 欄位）
4. 確認 Client `130` 的 **Logical system** 欄位已指派為 `S4HCLNT130`；如果是空的，才需要維護補上（**這一步屬於 Client 層級設定，異動前務必跟系統管理者確認過**，這不是一般開發物件，影響範圍是整個 Client）

### 步驟 3：`WE21` 建立 Port

1. 交易碼 `WE21` → 左側選 **Transactional RFC** 分類 → 工具列 **Create**
2. Port 名稱可以讓系統自動產生（建議格式）或自訂，例如 `SL130`
3. **Description** 填 `Self-loop port for ALE training`
4. **RFC Destination** 欄位填步驟 1 建立的 `S4HCLNT130`
5. 存檔

### 步驟 4：`WE20` 建立 Partner Profile（本題重點——Inbound/Outbound 詳細練習）

1. 交易碼 `WE20` → 左側樹狀 **Partner Type LS**（Logical System）→ 工具列 **Create**
2. **Partner No.** 填 `S4HCLNT130`（這個自我迴圈情境下，Partner 就是自己）
3. **Post processing: permitted agent** 頁籤可以先跳過（進階設定，非必要）

**4a. 填 Outbound Parameters**（代表「這個 Client 要送出 IDoc 給 S4HCLNT130」這件事）：

1. Outbound Parameters 區塊按 **Create**（綠色加號）
2. **Message Type** 填 `MATMAS`
3. **Receiver Port** 填步驟 3 建立的 Port（如 `SL130`）
4. **Output Mode** 選 **Transfer IDoc Immediately**（訓練用途選即時，不用等批次排程）
5. **Basic type** 填 `MATMAS05`
6. 存檔

**4b. 填 Inbound Parameters**（代表「這個 Client 要接收處理 S4HCLNT130 送來的 IDoc」這件事）：

1. Inbound Parameters 區塊按 **Create**
2. **Message Type** 填 `MATMAS`
3. **Process Code** 填 `MATM`（標準物料主檔 Inbound 處理碼，對應標準 Function Module `IDOC_INPUT_MATMAS01`）
4. **Processing by Function Module** 通常會自動帶出、選 **Trigger Immediately**
5. 存檔

> **⚠️ 常見誤區 Q&A（回應 Partner Profile 學習重點的具體提醒）**：
> - **Q：這個自我迴圈情境，Outbound 跟 Inbound 是不是同一份設定，只是畫面上分兩區塊顯示？**
>   A：不是。它們是**兩組完全獨立的參數**（一組決定送出去走哪個 Port，一組決定收進來用哪個 Process Code），只是這次剛好「發送方」跟「接收方」是同一個 Partner（自己），所以兩組設定都出現在同一張 `WE20` 畫面、同一個 Partner No. 底下。真實雙系統情境下，這兩組設定會分別出現在兩台系統各自的 `WE20` 畫面。
> - **Q：如果我只填了 Outbound、沒填 Inbound，IDoc 會發生什麼事？**
>   A：IDoc 送出去會成功（狀態會停在 `03`／`12` 之類代表「已送出/已交遞」的狀態），但因為接收端（這裡剛好也是自己）找不到對應的 Inbound Process Code 設定，IDoc 會卡在錯誤狀態（如 `56`／`64`），這正是 ale08 會深入處理的「Inbound 客製化」情境。
> - **Q：Process Code 填錯會怎樣？**
>   A：IDoc 送達後，系統找不到對應的處理邏輯，一樣會卡在錯誤狀態，錯誤訊息通常會明講「找不到 Process Code 對應的 Function Module」——這是排查 Inbound 問題最先要檢查的地方（ale08 詳細教）。

### 步驟 5：`BD64` 建立 Distribution Model

1. 交易碼 `BD64` → 工具列 **Create Model View**
2. **Short text** 填 `ALE Training Self-Loop`，**Technical name** 填 `ZALE02_MODEL`
3. 選取剛建立的 Model View → 工具列 **Add Message Type**
4. **Sender**：`S4HCLNT130`；**Receiver**：`S4HCLNT130`；**Message Type**：`MATMAS`
5. 存檔

### 步驟 6：`BD61` 開啟 Change Pointer 全域開關

1. 交易碼 `BD61`
2. 勾選 **Change pointers activated - generally**
3. 存檔——這一步是給 ale04（Master Data 分送）預先做好準備，本題不會馬上用到，但屬於「環境設定」範圍一併完成

### 步驟 7：`WE19` 送測，驗證整條管線

1. 交易碼 `WE19`
2. **Existing Data** 頁籤 → **Message Type** 填 `MATMAS`，**Object** 填物料 `000000000000000021` → **Execute**（系統會用這個既有物料的現有資料組出一筆測試 IDoc）
3. 確認畫面上 Control Record 的 **Receiver Port** 是空的（因為還沒指定），這時要手動在 Control Record 分頁填入 **Receiver**（Partner No.＝`S4HCLNT130`，Partner Type＝`LS`）
4. 工具列 **Standard Outbound Processing**（或選單 **IDoc → Outbound Processing**）送出

## 參考答案（驗證方式）

操作完成後回報 Port／Partner Profile／Distribution Model 是否都存檔成功，我會用以下**已查證正確的字典表**幫你驗證（2026-08-24 用 `DD02T` 反查 `DDTEXT` 找到的真實表名，不是猜測）：

- `datapreview/freestyle` 查 `SELECT PORT, PORTTYP, DESCRI FROM EDIPORT` 確認 Port 主檔已建立；再查 `SELECT PORT, LOGDES FROM EDIPOA` 確認這個 Port 的 `LOGDES`（Logical Destination）欄位正確指向你在 `SM59` 建的 RFC Destination 名稱
- `datapreview/freestyle` 查 `SELECT MESTYP, RCVPRN, RCVPRT, RCVPOR, OUTMOD, IDOCTYP FROM EDP13` 確認 Outbound Partner Profile 記錄（`RCVPOR`＝收件方 Port，`IDOCTYP`＝Basic Type）
- `datapreview/freestyle` 查 `SELECT MESTYP, SNDPRN, SNDPRT, METHOD FROM EDP21` 確認 Inbound Partner Profile 記錄（**`METHOD` 欄位就是畫面上的 Process Code**，SAP 內部欄位命名跟畫面標籤不一致，這裡先幫你對照好）
- `WE19` 送測後，查 `SELECT DOCNUM, MESTYP, STATUS, RCVPRN FROM EDIDC ORDER BY DOCNUM DESCENDING` 確認新產生的 IDoc 狀態——理想結果是看到狀態 `53`（Application document posted，代表完整跑完 Outbound→Inbound 全程）；如果卡在其他狀態，把狀態碼告訴我，我可以查 `SELECT * FROM EDIDS WHERE DOCNUM = '<你的 IDoc 號碼>'` 幫你看實際的錯誤訊息文字

## 思考題

1. 這一題所有設定都指向「自己」，如果之後要改成真的兩個系統對接，你覺得哪些設定**完全不用改**、哪些**一定要改**？（提示：想想 RFC Destination 的 Target Host、Partner No. 的命名、Message Type 的選擇這三者的性質分別是什麼）
2. `BD64` 的 Distribution Model 明明已經宣告了「誰跟誰同步什麼」，為什麼 `WE20` Partner Profile 還要重複填一次 Message Type？兩者是不是資訊重複？（提示：想想 `BD64` 回答的是「業務上該不該同步」，`WE20` 回答的是「技術上怎麼送/怎麼收」，這是不是兩個不同層次的問題）

## 答案

本題全程為 SAP GUI 操作，沒有可快照的 ABAP 原始碼。完成後請回報：① `SM59` 連線測試是否成功 ② `WE19` 送出的 IDoc 最終狀態碼，我會用 `datapreview/freestyle` 查 `EDIDC`／`EDIDS` 等字典表協助確認結果並排查問題。
