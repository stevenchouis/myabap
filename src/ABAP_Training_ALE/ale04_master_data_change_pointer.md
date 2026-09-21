# ALE 課程 4：Master Data 分送實戰——Change Pointer 機制端對端

## Lecture

ale02／ale03 已經證實了整條自我迴圈管線（`SM59`→`WE21`→`WE20`→`BD64`）能正常運作，但送出 IDoc 的方式是**手動**用 `WE19` 組一筆——這在真實場景裡完全不現實：沒有人會每次物料主檔改個安全庫存量，就手動跑一次 `WE19`。這題要補上 ale01 對照表裡 Master Data 那一格的**真正自動觸發機制：Change Pointer**。

### Change Document 與 Change Pointer：兩層不同的機制，容易混為一談

- **Change Document（變更文件）**：這是比 ALE 更底層、範圍更廣的通用機制——很多主資料物件（客戶、物料、供應商……）只要有掛「Change Document Object」（可以在 `SCDO` 查到，物料主檔對應的是 `MATERIAL`），**任何欄位**的異動都會自動記一筆到 `CDHDR`（表頭：誰、什麼時候、改了哪個物件）＋`CDPOS`（明細：改了哪個表、哪個欄位、舊值/新值）。這個機制跟 ALE 完全無關，是 SAP 通用的稽核軌跡（Audit Trail）基礎設施，`MM02` 改任何欄位都會產生 Change Document，不管你有沒有做任何 ALE 設定。
- **Change Pointer（ALE 變更指標）**：是**疊在 Change Document 上的一層過濾器**——因為一張物料主檔可能有幾百個欄位，每天被改的次數可能上千次，但真正需要同步給其他系統的欄位可能只有寥寥幾個（例如安全庫存量），如果每次任何欄位異動都觸發一次分送，會產生大量沒必要的流量。所以 ALE 額外做了一層「白名單」機制：只有**你明確在 `BD52` 登記過**的「訊息類型＋表格＋欄位」組合，異動時才會多寫一筆 Change Pointer 記錄，等著被打包成 IDoc。

**這代表 Change Pointer 是建立在 Change Document 之上的，不是取代它**——`MM02` 改欄位時，系統背後同時做兩件事：① 一定會寫一筆 `CDHDR`/`CDPOS`（不管有沒有 ALE 設定）② **只有**被 `BD52` 登記過的欄位，才會**額外**多寫一筆 Change Pointer 記錄。

### 三層開關：`BD61`（全域）→ `BD50`（訊息類型層級）→ `BD52`（欄位層級）

ale02 已經開過 `BD61`（全域總開關，整個系統要不要用 Change Pointer 機制）。這題要補齊剩下兩層，缺任何一層都不會產生 Change Pointer：

1. **`BD50`——訊息類型層級開關**：即使全域開了，每個 Message Type 也要各自被勾選「Active」，才會真正記錄該類型的 Change Pointer（例如你可能只想追蹤 `MATMAS`、不想追蹤 `DEBMAS`）。
2. **`BD52`——欄位層級白名單**：針對某個訊息類型，明確指定「表格＋欄位」的組合要被追蹤。標準訊息類型通常已經預先登記好一批常用欄位，但也可能沒有你想要的那個欄位，需要自己用 **New Entries** 加上去。

### 誰負責把 Change Pointer 打包成 IDoc？——`BD21`／`RBDMIDOC`

Change Pointer 記錄本身只是「這筆資料被改過、還沒送出」的待處理清單，**不會自動變成 IDoc**——需要有人（或排程）主動執行 `BD21`（這個交易碼背後跑的正是 ale01 提過的標準報表 `RBDMIDOC`）：

1. 依你指定的 Message Type，找出所有還沒處理過的 Change Pointer
2. 把同一筆主資料的多次異動去重、合併
3. 呼叫該訊息類型登記好的擷取邏輯，組出正式的 IDoc（**這一步跟 `WE19` 手動組 IDoc 本質上做的是同一件事，只是資料來源從「你手動指定」換成「Change Pointer 告訴它該抓哪一筆」**）
4. 沿用 Distribution Model／Partner Profile 正常送出——**這代表 `BD21` 送出的 IDoc，走的是跟 ale02 完全一樣的 Outbound 管線**，不需要另外設定 Partner Profile 或 Distribution Model
5. 把處理過的 Change Pointer 標記起來，避免下次 `BD21` 重複處理同一筆

實務上 `BD21` 通常是排程 Job（例如每小時跑一次），這題手動執行是為了馬上看到結果。

### 這題為什麼不用另外設定 Partner Profile？

README 課綱原本設計「在兩個 Client 各自配置 Partner Profile」——但這門課只有 Client `130` 的存取權限，ale02 已經用自我迴圈的方式把 `MATMAS` 的 Outbound＋Inbound Partner Profile **都設定好了**。既然 `BD21` 送出 IDoc 走的管線跟 `WE19` 完全一樣，**這題直接沿用 ale02 的設定，不需要重新配置**——這題的教學重點從「怎麼設定管線」換成「怎麼觸發管線」，兩者是互補而非重複的練習。

## 學習目標

- 能分辨 Change Document（通用稽核機制）跟 Change Pointer（ALE 專屬過濾層）的差異與關係
- 能講出 `BD61`／`BD50`／`BD52` 三層開關各自負責什麼，缺哪一層會導致 Change Pointer 完全不會產生
- 理解 `BD21`／`RBDMIDOC` 的角色：把「待處理的異動」轉成「正式送出的 IDoc」，並且沿用既有的 Outbound 管線
- 完成一次端對端驗證：改一筆真實主資料的欄位 → 觸發 Change Pointer → `BD21` 送出 → 用 ale03 學到的 `WE02` 監控確認結果

## 事前準備

延續 ale02／ale03 的自我迴圈環境（`SM59`／`WE21`／`WE20`／`BD64` 皆已完成，`BD61` 全域開關已開），本題只需要新增 `BD50`／`BD52` 兩層設定，不需要新建任何 Partner Profile 或 Distribution Model。

**⚠️ 本題會真實異動一筆物料主檔的資料（安全庫存量）**——這是這個共用訓練系統上的真實業務資料，操作前請先記下原始值，操作驗證完成後記得改回去（步驟 5 會提醒）。

## 題目需求

### 步驟 1：`BD50` 啟用 `MATMAS` 訊息類型層級開關

1. 交易碼 `BD50`
2. 找到 `MATMAS` 這一列，確認／勾選 **Active** 欄位（如果本來就是勾選狀態，代表系統已經預設開啟，不用改，直接記錄現況即可）
3. 存檔

### 步驟 2：`BD52` 確認／新增欄位層級追蹤——`MARC-EISBE`（安全庫存量）

1. 交易碼 `BD52`
2. **Message Type** 填 `MATMAS`，Execute，看目前已經登記的表格/欄位清單
3. 確認清單裡有沒有 `MARC` 表的 `EISBE` 欄位：
   - 如果**已經有**，確認 **Active** 有勾選即可，不用重複新增
   - 如果**沒有**，按 **New Entries**，填 **Table Name** = `MARC`、**Field Name** = `EISBE`，勾選 **Active**
4. 存檔

### 步驟 3：記錄現況並異動主資料（`MM02`）

1. 交易碼 `MM03`（先用 Display 模式確認），輸入 ale02 用過的物料 `000000000000000021` → **Extras → Plant Data**（或畫面上的 Organizational Levels 彈窗）確認這個物料在哪個 Plant 有維護 `MARC` 資料
2. 記下該 Plant 目前的 **Safety Stock**（`MARC-EISBE`）現有值——這一步很重要，等驗證完成後要改回來
3. 交易碼 `MM02`，同一個物料、同一個 Plant，進入 **MRP 1** 頁籤（Safety Stock 欄位通常在這裡），把數值改成一個明顯不同的測試值（例如原值 +5）
4. 存檔——這一步會同時：① 產生 Change Document（不管有沒有 ALE 設定都會發生）② 因為步驟 1/2 已經開好開關，額外產生一筆 Change Pointer 記錄

### 步驟 4：`BD21` 觸發分送

1. 交易碼 `BD21`
2. **Message Type** 填 `MATMAS`，Execute
3. 畫面應該會顯示處理了幾筆 Change Pointer、產生了幾筆 IDoc（如果顯示 0 筆，回頭檢查步驟 1/2 是否真的存檔成功，或步驟 3 的異動是否真的針對 `MARC-EISBE` 這個欄位）

### 步驟 5：用 `WE02` 驗證結果，並還原資料

1. 交易碼 `WE02`（沿用 ale03 學到的技巧），**Message Type** = `MATMAS`，**Direction** = Outbound，**Created On** 填今天，找到 `BD21` 剛產生的新 IDoc
2. 展開 **Data Records**，找到物料 Plant 資料的 Segment（通常是 `E1MARCM`），確認裡面的安全庫存量欄位值，是不是你在步驟 3 改的那個新值
3. 展開 **Status Record**，確認最終狀態是否走到 `53`（因為自我迴圈的 Inbound Partner Profile 在 ale02 已經設成 Trigger Immediately，理論上會自動接著跑完 Inbound）
4. **還原資料**：回到 `MM02`，把安全庫存量改回步驟 3 記錄的原始值，存檔——這次異動同樣會產生新的 Change Pointer，你可以選擇要不要再跑一次 `BD21` 讓還原動作也同步出去（保持系統一致），或者這次先跳過（本題重點已經驗證完成，是否補跑這一步留給你判斷）

## 參考答案（驗證方式）

操作完成後回報：① `BD21` 顯示處理了幾筆 Change Pointer、產生了哪個 IDoc 號碼 ② 該 IDoc 最終狀態碼。我會用以下查詢協助確認（`EDIDC`/`EDIDS`/`EDID4` 已在 ale03 驗證過表名與欄位正確）：

- `SELECT DOCNUM, MESTYP, STATUS, CREDAT, CRETIM FROM EDIDC WHERE MESTYP = 'MATMAS' AND CREDAT = '<今天日期>' ORDER BY CRETIM DESCENDING`——找出今天新產生的 IDoc
- `SELECT DOCNUM, COUNTER, STATUS, STATXT FROM EDIDS WHERE DOCNUM = '<IDoc號>' ORDER BY COUNTER`——確認完整狀態歷程
- `SELECT SDATA FROM EDID4 WHERE DOCNUM = '<IDoc號>' AND SEGNAM = 'E1MARCM'`——核對安全庫存量的新值是否正確出現在 Data Record 裡（如果 Segment 名稱跟我猜的 `E1MARCM` 不同，把你在 `WE02` 實際看到的名稱告訴我）

## 思考題

1. 如果哪天 `BD21` 執行後顯示「0 筆待處理」，但你確定剛剛真的改過 `MARC-EISBE`，你會怎麼排查？（提示：從 `BD61`→`BD50`→`BD52` 三層開關，加上「改的欄位真的是 `MARC-EISBE` 嗎」逐一往回推）
2. 這題示範的是「改一次、送一次」，但真實情境常常是「一天內同一筆物料被改了 5 次安全庫存量」。你覺得 `BD21` 執行時，應該送出 5 筆 IDoc（每次異動各一筆）還是 1 筆 IDoc（合併成最終結果）？哪一種對接收端的系統負擔更小？（提示：想想接收端如果收到 5 筆，會不會有 5 次重複處理的成本，跟「最終結果是否正確」是不是兩件不同的事）
3. 如果真實情境是兩個獨立系統（不是自我迴圈），Change Pointer／`BD21` 這一段（發生在**發送方**系統）跟 Partner Profile 的 Outbound 設定（也在**發送方**）合起來看，跟接收方系統完全無關——這代表發送方要不要同步一筆資料，接收方有沒有辦法「拒絕」或「要求」？如果沒有，這個設計的風險是什麼？（提示：回顧 ale01 提過的「廣播式」整合特性）

## 答案

本題全程為 SAP GUI 操作與監控查詢，沒有可快照的 ABAP 原始碼（Change Pointer／`BD21` 都是標準 SAP 交易與報表，不需要自訂任何物件）。完成後請回報 `BD21` 的處理結果與新 IDoc 號碼/狀態碼，我會用 `datapreview/freestyle` 查 `EDIDC`／`EDIDS`／`EDID4` 協助確認，並在確認完成後提醒你是否已經把安全庫存量改回原值。
