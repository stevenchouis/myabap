# 整合練習 9（期末綜合實作）：混合批次資料轉換——BAPI 優先、BDC 補位

## Lecture

這是整合課程的收尾，把 if01～if05 教過的技巧全部串起來：**一批來源資料（模擬資料轉換情境的匯入檔），逐筆判斷該走 BAPI 還是 BDC，各自處理，最後統一決定這批資料整體 COMMIT 還是 ROLLBACK**。

**整合了哪些前面學過的東西**：

- **if01（BAPI vs FM）**：路由判斷的本質就是「這個項目有沒有對應的 BAPI」——有，就走穩定、有結構化錯誤回報的 BAPI 介面；沒有，才退而求其次走 BDC。
- **if02（怎麼找 BAPI）**：`route_item` 這個方法把「找到 BAPI 了沒」這件事，簡化成一個可以寫進程式邏輯的判斷條件（`item_type = 'BOOKING'` 就對應到已經找到、驗證過的 `BAPI_FLBOOKING_CREATEFROMDATA`）。
- **if03（COMMIT／ROLLBACK 與 LUW）**：整批項目跑完才一次決定 `BAPI_TRANSACTION_COMMIT` 或 `BAPI_TRANSACTION_ROLLBACK`，不是每筆各自提交——這是 if03 教過的「多步驟、要嘛全部生效要嘛全部不生效」LUW 邊界設計。
- **if04（Data Conversion 觀念）**：這整支程式的骨架就是 if04 比較表裡「BAPI-based conversion」那一列的具體實作，`route_item` 的分流邏輯呼應 if04 情境判斷題教的「先看有沒有 BAPI，才決定要不要退回 BDC」。
- **if05（BDC Program）**：沒有 BAPI 的項目，實務上會交給 if05 建的 `ZCL_IF05_BDC_RUNNER`（`run_via_call_transaction`／`run_via_session`）處理；這題因為沒有真實 `BDCDATA`（`SHDB` 錄製的 GUI-only 限制，if05／if09 都遇到同一個邊界），只示範路由判斷本身，程式碼裡有註解清楚標明「實務上這裡要接 if05 的類別」。

**架構**：`ZCL_IF09_CONVERSION_RUNNER` 兩個方法——

- **`route_item`**：純邏輯，依 `item_type` 決定路由（`'BOOKING'` → `'BAPI'`，其餘一律 `'BDC'`），附 ABAP Unit 測試（含空字串輸入的防呆測試——沒有型態資訊時安全預設是「沒有 BAPI」而不是誤判成有）。
- **`run_conversion`**：主流程，逐筆呼叫 `route_item` 分流，`BAPI` 路徑直接呼叫 `BAPI_FLBOOKING_CREATEFROMDATA`（跟 REST 課 rs10 一模一樣的呼叫模式）並收集 `RETURN` 訊息，`BDC` 路徑目前只記錄路由決定；全部處理完才依「是否全數成功」決定 `COMMIT`／`ROLLBACK`。

## 學習目標

- 能設計一支「依資料型態分流到不同介面技術」的資料轉換程式骨架
- 能正確安排多筆、多種介面技術混合呼叫時的 LUW 邊界（整批統一 COMMIT/ROLLBACK，不是逐筆各自決定）
- 能講出這支程式如何呼應 if01～if05 各題學到的概念，建立完整的知識連結
- 認清「示範程式」跟「生產可用程式」的差距在哪裡（這題的 BDC 路徑只做到路由判斷，沒有真的接上 if05 的執行邏輯）

## 事前準備

不需要既有物件，這題新建：

- `ZCL_IF09_CONVERSION_RUNNER`——路由與批次處理邏輯
- `ZR_IF09_CAPSTONE_DEMO`——呼叫端示範，混合 2 筆 `BOOKING`（走 BAPI）+ 1 筆 `LEGACY_MASTER_DATA`（走 BDC）

## 題目需求

1. 對照 `ZCL_IF09_CONVERSION_RUNNER=>run_conversion`，指出程式碼裡對應 if01～if05 各題概念的具體位置（可以直接引用 Lecture 的整合清單，練習把技巧跟程式碼段落一一對應）。
2. 如果批次裡第一筆 `BOOKING` 成功、第二筆因為 `carrid` 不合法而失敗，程式最終應該是 `COMMIT` 還是 `ROLLBACK`？為什麼即使第一筆已經呼叫成功，最後還是可能整批撤銷？
3. 延伸設計（只需要寫設計，不用真的實作）：如果要讓 `BDC` 路徑真的接上 `ZCL_IF05_BDC_RUNNER`，`run_conversion` 的介面需要怎麼調整才能把「哪個交易碼、哪組 `BDCDATA`」這些資訊從呼叫端傳進來？

## 答案

見 `zcl_if09_conversion_runner.clas.abap`（含 `zcl_if09_conversion_runner.clas.testclasses.abap`，SAP 端物件 `ZCL_IF09_CONVERSION_RUNNER`）與 `zr_if09_capstone_demo.prog.abap`（SAP 端物件 `ZR_IF09_CAPSTONE_DEMO`），套件皆為 `$TMP`。已在系統上實際建立、啟用，`sap_run_unit_test` 3/3 通過，並用 `programrun` 執行完整端對端驗證：

```
if09 期末綜合實作：混合批次（BAPI + BDC 路由）結果
------------------------------------------------------------------------------------
         1  BAPI OK 訂位建立成功，單號 00019802
         2  BAPI OK 訂位建立成功，單號 00019803
         3  BDC OK
已判定走 BDC 路徑，交給 ZCL_IF05_BDC_RUNNER 處理（本示範未實際執行，需真實 BDCDATA）
```

兩筆 `BOOKING` 都成功建立訂位（真實訂位單號 `00019802`／`00019803`，`BAPI_TRANSACTION_COMMIT` 以 `wait = 'X'` 同步提交，已確認寫入 `SBOOK`），第三筆正確路由到 `BDC`。整批因為沒有任何失敗項目，最終走 `COMMIT` 分支。

## 團隊實務備註

- 測試資料 `carrid='LH' connid='0400' fldate='20270101' customid='00000001' counter='00000001'` 沿用 REST 課 rs10 md 文件裡記載的「已驗證有效」組合（`rs10_batch_bapi.md` 有記錄這組值的驗證過程與 `counter` 欄位的隱性業務規則），沒有重新從頭摸索，直接省了一輪試錯。
- `run_conversion` 目前的 `BDC` 分支是**刻意的半成品**：真的要接上 `ZCL_IF05_BDC_RUNNER`，`ty_item` 需要擴充成能帶「目標交易碼＋一組 `BDCDATA`」（或更彈性地，讓呼叫端在建立 `ty_item` 時就把要用的路由方式跟對應資料都準備好，`route_item` 只負責「判斷」不負責「生成執行所需的資料」），這是思考題 3 的設計題，這份講義沒有先給答案，讓學員自己想過一輪。
- 整個 Interface 課程（if01～if09）至此全部完成並在系統上驗證過，是課程系列裡少數幾乎每一題都做到「不只寫程式、還真的在系統上執行驗證」的一門課——只有 if05／if09 的 BDC 執行本身因為 `SHDB` 錄製的 GUI-only 限制沒有做到端對端，其餘每一題（if01 的介面查證、if02/if03 的 QM/MM 真實物件查證、if04 的 Direct Input 程式查證、if06 的 Native SQL、if07 的 RFCDES/DBCON 讀取、if08 的 ADBC）都用真實系統資料或真實執行結果佐證，沒有停留在憑空舉例的階段。

## 思考題

1. 這支程式的 `BAPI` 路徑目前只認 `item_type = 'BOOKING'` 這一種型態；如果之後要新增第二種有 BAPI 的項目型態（例如 if02/if03 教過的 QM 檢驗批過帳），`route_item` 該怎麼改，才不會變成一長串 `IF...ELSEIF...ELSEIF...`？（提示：可以想想用一個「型態→路由」的對照表（`TYPES: ... TYPE HASHED TABLE`，或 `CASE` 陳述式）取代硬寫的比較邏輯，型態一多，維護會輕鬆很多）
2. `run_conversion` 目前把 BAPI 呼叫的細節（`BAPISBONEW` 欄位組裝）寫死在方法裡，如果之後 `BAPI` 路徑要支援不只一種 BAPI（不只訂位，還有其他有 BAPI 的物件），這個方法的設計會遇到什麼問題？（提示：目前的寫法假設「走 BAPI 路徑的項目都是訂位」，這個假設一旦不成立，`run_conversion` 就要重新設計成更通用的「呼叫哪個 BAPI、怎麼組參數」都能被替換的結構，這其實是一個對照 if01～if03「認識 BAPI」跟「設計一個可擴充的 BAPI 呼叫框架」之間的落差，值得討論但不要求這題就寫出完整答案）
3. 回顧整個 Interface 課程 if01 到 if09，如果要用一句話總結這門課想教的核心觀念，你會怎麼說？（提示：沒有標準答案，這是收斂複習題——可以參考的方向是「先確認有沒有現成、穩定的官方介面（BAPI）可用，沒有才退而求其次用模擬畫面（BDC）或繞過應用層直接動資料庫（Native SQL/ADBC），而且不管走哪條路，LUW 邊界／Client 過濾／錯誤處理這幾件事都要自己扛起來」）
