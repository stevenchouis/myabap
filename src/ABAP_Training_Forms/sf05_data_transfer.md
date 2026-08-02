# 表單設計練習 5：資料傳遞與動態內容

## Lecture

sf01～sf04 的表單內容全部是**設計期就打死的靜態文字**（`Hello Smartform!`、固定的檢查清單……）。這題開始才是 Smartform 真正的核心用途：**把 ABAP 程式的資料表傳進表單，讓表單自己跑迴圈輸出、依條件顯示不同內容**。都已用 `mcp__sap-docs__search` 查證官方文件《Defining the Form Interface》《Processing Output Repeatedly》《Branching Within the Form》《Page Numbering》。

**Form Interface：表單的「參數介面」**：

- 路徑：`Global Settings → Form Interface`，可以定義 **Import／Export／Tables 三種參數**，外加 Exceptions——官方文件明講：**「表單介面沒有 Changing 參數」**（跟一般 Function Module 的四種參數不同，這是 Smart Form 介面的天生限制，不是漏教）
- **參數名稱是表單自己的，不用跟呼叫端 ABAP 程式的變數名一樣**——但呼叫端在 `CALL FUNCTION lv_fm_name EXPORTING ...` 時，**參數名稱要打對**，因為這是動態呼叫（sf01 就學過的 `SSF_FUNCTION_MODULE_NAME` 模式），語法檢查**沒辦法**幫你檢查這個字串參數名稱對不對，打錯只會在執行期噴 `PARAMETER_ERROR` 之類的例外，這是這題很容易踩的雷
- 其實 sf01～sf04 都已經在用 Form Interface 了，只是用的是**系統內建的標準參數**（`control_parameters`／`output_options`，就是一直在用的那兩個），這題第一次自己新增**自訂的 Import 參數**

**Global Definitions：表單自己的全域變數/型別**：

- 路徑：`Global Settings → Global Definitions`，可以宣告額外的 **Data（全域變數）**跟 **Types（型別）**，作用範圍是整張表單，任何節點都能存取——這題會用一個全域變數存「總筆數」，展示這個機制

**LOOP 節點：逐筆處理內部表格**（官方文件《Processing Output Repeatedly》）：

- 建立 Loop 節點，在它的 **Data 分頁**指定要讀哪個內部表格（可以是 Form Interface 傳進來的 Import 參數），系統會把每一筆讀進一個**工作區（Work Area）**
- Loop 底下的子節點（Text／Table／Alternative……）可以直接用 `&工作區-欄位名&` 這種語法引用當前這一筆的欄位值
- 官方文件的範例情境正好示範了巢狀用法：「用 Loop 讀客戶資料，Loop 裡面再放一個 Table 用客戶編號去讀訂單」——這題不會巢狀那麼深，但這是同一套機制的延伸

**Alternative 節點：條件分支**（官方文件《Branching Within the Form》）：

- 建立 Alternative 節點，`General Attributes` 分頁的 **Node Conditions** 設條件（跟 `Conditions` 分頁的 `Output Conditions` 用同一套機制）
- Alternative 節點**天生就有兩個子節點：`TRUE` 跟 `FALSE`**，條件成立走 `TRUE` 底下的內容，不成立走 `FALSE`

**系統欄位做頁碼**（官方文件《Page Numbering》）：

- `&SFSY-PAGE&`：目前頁次；`&SFSY-FORMPAGES&`：這張表單總共幾頁——兩者都可以直接當文字符號寫進 Text 節點，例如 `第 &SFSY-PAGE& 頁，共 &SFSY-FORMPAGES& 頁`
- Page 節點的 `General Attributes` 分頁有 **Format**（阿拉伯數字/羅馬數字/字母）跟 **Mode**（Initialize／Increase／Leave Unchanged）兩個設定，控制頁碼怎麼計算——這題用系統預設值即可，不深入客製
- ⚠️官方文件裡還有一個「所有表單的總頁數」系統欄位，兩份文件對它的確切名稱寫法不完全一致（`&SFSY-JOBPAGE&` vs `&SFSY-JOBPAGES&`），這題**刻意不使用**這個有疑義的欄位，只用查證结果一致的 `&SFSY-PAGE&`／`&SFSY-FORMPAGES&`，避免教一個自己都不確定的東西

## 學習目標

- 能在 Form Interface 定義一個 Import 參數（表格型別），並在呼叫端正確傳值進去
- 知道 Form Interface 沒有 Changing 參數、動態呼叫時參數名稱打錯語法檢查抓不到，這兩個限制/風險
- 能用 Loop 節點讀一個內部表格、逐筆輸出欄位值
- 能用 Alternative 節點依條件輸出不同內容
- 能用 `&SFSY-PAGE&`／`&SFSY-FORMPAGES&` 做頁碼

## 事前準備

沿用 sf02 已建立的 Smart Style `ZSTY_02_LAYOUT`（第三次重複使用，呼應 sf03 提過的「Smart Style 是共用資源」）。資料模型沿用課程慣用的 SCARR（航空公司主檔），不需要另外建表。

## 題目需求

1. **建立新表單 `ZSF_05_FLIGHTS`**，Style 指派 `ZSTY_02_LAYOUT`，Page Format 沿用 `DINA4`。

2. **Form Interface** 新增一個 Import 參數：
   - 名稱：`IT_CARRIER`
   - 參考型別：`TYPE STANDARD TABLE OF SCARR`

3. **Global Definitions** 新增一個 Data：
   - 名稱：`GV_COUNT`，型別 `TYPE I`

4. **在 MAIN Window 之前**（例如 HEADER Window 或 MAIN 裡的第一個節點）加一個 **Program Lines 節點**，寫一行 ABAP 算出總筆數：
   ```abap
   DESCRIBE TABLE IT_CARRIER LINES GV_COUNT.
   ```

5. **HEADER Secondary Window**（Position/Size 比照 sf02，或自訂）：Text 節點顯示 `ZSF_05_FLIGHTS 練習 - 航空公司清單（共 &GV_COUNT& 家）`。

6. **MAIN Window 裡建立 Loop 節點**，Data 分頁指到 `IT_CARRIER`，工作區自訂名稱（例如 `WA_CARRIER`）。Loop 底下：
   - 一個 Text 節點輸出 `&WA_CARRIER-CARRID& - &WA_CARRIER-CARRNAME&`
   - 一個 **Alternative 節點**，條件 `WA_CARRIER-CURRCODE = 'USD'`：
     - `TRUE` 底下放 Text `（美金計價）`
     - `FALSE` 底下放 Text `（其他幣別：&WA_CARRIER-CURRCODE&）`

7. **FOOTER Secondary Window**（新建，放在頁面下緣，例如 Position Y-Origin `27`cm）：Text 節點顯示 `第 &SFSY-PAGE& 頁，共 &SFSY-FORMPAGES& 頁`。

8. **啟用**整組物件。

9. **呼叫端程式**：Claude 建立 `ZR_SF05_DEMO`，這次**不能只是查名稱就呼叫**，要先 `SELECT` 出 `SCARR` 資料填進內部表格，再把這個表格當 `it_carrier` 參數傳給動態呼叫的 Function Module。

10. **驗證**：Print Preview 或執行 `ZR_SF05_DEMO`，確認：
    - 每家航空公司都印出一行 `代碼 - 名稱`
    - 美金計價（`CURRCODE = 'USD'`）的航空公司後面接「（美金計價）」，其他的接「（其他幣別：xxx）」
    - 頁尾看得到頁次
    - `HEADER` 顯示的總家數跟 Loop 實際印出的行數一致

## 思考題

1. 如果呼叫端程式把參數名稱打錯（例如寫成 `it_carriers`，多一個 `s`，但表單介面定義的是 `it_carrier`），語法檢查會抓到嗎？執行時會發生什麼事？（提示：回顧 Lecture 提到的「動態呼叫，語法檢查沒辦法檢查字串參數名稱」）
2. 如果 `SELECT` 出來的 `IT_CARRIER` 是空表格（一筆都沒有），Loop 節點底下的內容會印出什麼？`GV_COUNT` 會是多少？表單本身會不會出錯？
3. Form Interface 沒有 Changing 參數——如果你想讓表單「執行時修改」一個傳進來的值、再傳回給呼叫端程式，Smart Form 做得到嗎？（提示：想想 Import 跟 Export 兩種參數是不是可以間接做到類似 Changing 的效果，各自的限制是什麼）

## 答案

`ZR_SF05_DEMO` 快照見 `zr_sf05_demo.prog.abap`（已建立、語法檢查通過，內含 `SELECT FROM SCARR` 邏輯）。`ZSF_05_FLIGHTS` 表單本體（含 Form Interface／Global Definitions／Loop／Alternative／頁碼設定）需要你在 `SMARTFORMS` 手動建立（原因見 sf01／`.claude/rules/sap-adt-mcp.md` 第 19 節），`ZSTY_02_LAYOUT` 沿用既有物件。完成後請回報結果，或執行 `ZR_SF05_DEMO` 搭配 Print Preview 確認動態內容是否正確。
