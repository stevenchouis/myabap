# 講義 8a：Package 與傳輸請求——SE80／SE10／STMS（授課順序：接在講義 8 之後、講義 15 之前）

> 對應練習：[ex08a](../ex08a_package_transport.md)｜本講沒有答案程式，驗收方式是 SE10 的傳輸記錄與 STMS 的匯入狀態

## 本講重點

- **Package（套件）**：物件的歸屬與傳輸路線；`$TMP` 與正式 Package 的差別（SE80）
- **傳輸請求（Transport Request，TR）**：Request 與 Task 兩層結構（SE10）
- **釋放順序**：先釋放 Task，再釋放 Request
- **TR 與版本**：釋放時系統替物件存一個版本，可比對、可回復
- **釋放後再修改**：一定要掛**新的 TR**
- **STMS**：在匯入佇列（Import Queue）用篩選找到自己的 TR、確認有沒有匯入、執行匯入

## 1. 為什麼要有 Package 與 TR

到目前為止，所有練習都建在 `$TMP`（Local Object），建立時系統不會問 TR。這是刻意的：`$TMP` 的物件**只存在這台系統、永遠不會被傳輸**，適合練習。

正式開發不一樣。典型的 SAP 系統環境有三台：

| 系統 | 用途 | 誰在用 |
|---|---|---|
| DEV（開發） | 寫程式、改設定 | 開發人員 |
| QAS（測試） | 使用者驗收測試 | 關鍵使用者 |
| PRD（正式） | 每天營運 | 全公司 |

**正式機不能直接改程式**。程式在 DEV 寫好，要靠 TR 把「這次改了哪些物件」打包，一路送到 QAS、PRD。所以：

- **Package** 決定物件「屬於哪個專案、要走哪條傳輸路線」
- **TR** 記錄「這一次改了哪些物件」，是傳輸的單位

> **傳輸路徑是 Basis 設定好的**：TR 釋放後，系統依設定決定它要送到哪一台（Target System），並自動排進那台的匯入佇列。ABAPer 不用管路徑怎麼設，只要會「釋放 → 在佇列找到它 → 匯入」。
>
> 本課程的系統是**單一系統**（`S4H`），沒有 QAS／PRD，所以 STMS 練習是把 TR 匯入 `S4H` 自己——畫面與按鈕跟正式三台環境完全相同。

## 2. 建立 Package（SE80）

**步驟**：

1. SE80 → 左上方下拉選單選 **Package**，輸入新套件名稱（客戶套件一律 `Z` 或 `Y` 開頭）→ Enter
2. 系統問「Package 不存在，要建立嗎？」→ **Yes**
3. 在建立畫面填欄位：

| 欄位 | 填什麼 | 本系統的值 |
|---|---|---|
| Package | 套件名稱 | 課堂實例：`ZMM1`、`ZMM2` |
| Short Description | 套件說明 | 自訂 |
| Application Component | 所屬應用模組 | 可留空或選對應模組 |
| Software Component | 軟體元件 | `HOME`（客戶自開發） |
| Transport Layer | 傳輸層：決定這個套件的物件要送去哪裡 | `ZS4H` |
| Package Type | 一般選 Not a Main Package | |

4. 按 Save → 系統要求指定 TR（**Package 本身也是要被傳輸的物件**）→ 建立新 TR（見第 3 節）或選既有的

> 課堂實例：`ZMM1`、`ZMM2` 的 Software Component 都是 `HOME`、Transport Layer 都是 `ZS4H`（2026-09-24 查 `TDEVC` 表確認）。

**Package 命名**：本專案慣例是 `ZPKG_xxx`（見 CLAUDE.md），實務上各公司多半依模組分（如 `ZMM`、`ZSD`），重點是**團隊統一**。

### 2.1 把 `$TMP` 的物件搬進正式 Package

練習建在 `$TMP` 的程式，之後若要正式上線，可以改掛到正式 Package：

SE38 開啟程式 → 選單 **Goto → Object Directory Entry** → 切換到修改模式 → Package 欄位改成正式套件 → Save → 系統要求指定 TR。

反過來也成立：物件一旦掛進正式 Package，之後每次修改都會要求 TR。

## 3. 傳輸請求：Request 與 Task（SE10）

### 3.1 兩層結構

```
S4HK901984  Inventory Report          ← Request（傳輸請求，傳輸的單位）
  └ S4HK901985  Inventory Report      ← Task（工作，屬於某個開發人員）
        R3TR DEVC ZMM1
        R3TR PROG ZS_0000001
        R3TR PROG ZS_0000003
```

- **Request**：傳輸的單位，整張一起送到下一台系統。
- **Task**：掛在 Request 底下，**每個參與的開發人員各一個 Task**。你修改物件時，物件記錄在**你自己的 Task** 裡。
- TR 號碼格式是 `<系統 ID>K<流水號>`，本系統是 `S4HK......`。

> 以上是今天課堂的真實資料（查 `E070`／`E071` 表確認）。

### 3.2 建立 TR

有兩種時機：

1. **被動**：在正式 Package 建物件或存檔時，系統跳出「Prompt for transportable Workbench request」→ 按 **Create Request**（新建）→ 填 Short Description → Save。系統會同時建 Request 與你的 Task。
2. **主動**：SE10 → **Create** → 選 **Workbench Request** → 填說明 → Save。

| TR 類型 | 放什麼 | 由誰建 |
|---|---|---|
| **Workbench Request** | 開發物件：程式、Class、FM、DDIC… | 開發人員（本講） |
| Customizing Request | SPRO 組態設定 | 功能顧問 |

**好習慣**：一個功能或修正對應一張 TR，說明要寫得讓別人看得懂（功能簡述＋需求單號）。不要把不相干的修改混在同一張 TR。

### 3.3 物件被 TR「鎖住」

物件一旦記錄在某張**尚未釋放**的 TR 裡，它就被這張 TR 鎖住：別人改同一個物件時，只能加入同一張 TR（系統會提示），不能另外掛自己的 TR。這是 SAP 防止兩個人的修改被拆開傳輸、造成正式機版本錯亂的機制。

## 4. 釋放順序：先 Task，再 Request（SE10）

**步驟**：

1. SE10 → 勾選 **Modifiable**（還沒釋放的）→ **Display**
2. 展開自己的 Request，看到底下的 Task
3. 游標放在 **Task** 上 → 按 **Release**（卡車圖示）
4. Task 全部釋放後，游標放在 **Request** 上 → 再按 **Release**

**為什麼有順序**：Request 要等底下所有 Task 都釋放（所有參與者都確認改完）才能釋放。Task 還沒釋放時，Request 的 Release 會被擋下來。

釋放 Task 時，Task 裡的物件會合併到 Request 裡；釋放 Request 時，系統把物件內容匯出（Export）成傳輸檔，排進下一台系統的匯入佇列。

> 課堂實例：`S4HK901984` 的物件清單第一列是 `CORR RELE S4HK901985 ...`——這就是「Task `S4HK901985` 已釋放、內容併進 Request」的記錄。

**⚠️ 釋放後就收不回來**。實務上什麼時候該釋放，要跟團隊（或專案負責人）確認，不要自己寫完就釋放。

## 5. TR 與版本

TR 釋放時，系統會替 TR 裡的程式**存一個版本**。之後可以：

- **看版本清單**：SE38 開啟程式 → **Utilities → Versions → Version Management**，每個版本都標示對應的 TR 號碼
- **比對差異**：勾兩個版本 → **Compare**，看這次改了哪幾行
- **回復舊版**：選舊版本 → **Retrieve**，舊內容變成新的修改版（仍要存檔、啟用，而且一樣要掛 TR）

> 課堂實例：`ZB_01` 在 `S4HK901986` 釋放後，版本清單多了一個版本、對應的 TR 就是 `S4HK901986`（查 `VRSD` 表確認）。

所以 **TR 不只是「傳輸的箱子」，也是物件的「修改履歷」**：看版本清單就知道這支程式歷經哪幾張 TR、每張改了什麼。

## 6. 釋放後再修改：一定要掛新 TR

TR 一旦釋放，就是「已經封箱寄出」。之後再改同一支程式，系統會再次跳出 TR 提示，要求你**建新的 TR（或選另一張還沒釋放的 TR）**——不可能再放回已經釋放的那張。

課堂實例（兩組學員都做了這一步）：

| 第一次（已釋放） | 釋放後再修改（新 TR，尚未釋放） |
|---|---|
| `S4HK901986` inventory report：`ZMM2`、`ZB_01`、`ZB_02` | `S4HK901988` inventory mod（物件在 Task `S4HK901989`）：`LIMU REPS ZB_02`（修改既有程式）、`ZB_03`、`ZB_FG01`、`ZTR_B` |
| `S4HK901984` Inventory Report：`ZMM1`、`ZS_0000001`、`ZS_0000003` | `S4HK901990` Inventory modify（物件在 Task `S4HK901991`）：`LIMU REPS ZS_0000003`、`ZS_0000004`、`ZS_0000005`、`ZS_FG01`、`ZTR22_S1` |

看到兩種物件記錄方式：

| 記錄 | 意思 |
|---|---|
| `R3TR PROG ZB_03` | 整個物件（新建的程式：原始碼、屬性、文字元素全部） |
| `LIMU REPS ZB_02` | 物件的一部分：只有**程式原始碼**（修改既有程式時，系統只記錄改到的部分） |

同一支程式因此會出現在**多張 TR** 裡，傳輸時要**依順序**匯入（先舊 TR、再新 TR），否則新版本可能被舊版本蓋掉。

## 7. STMS：匯入佇列與匯入

### 7.1 開啟匯入佇列

1. 執行 **STMS**
2. 按 **Import Overview**（匯入總覽）→ 列出傳輸網域內每一台系統的佇列
3. 游標放在要匯入的系統上（本課程是 `S4H`）→ 按 **Display Import Queue**（或雙擊系統名稱）

> 直接執行 **STMS_IMPORT** 會直接開啟「目前登入系統」的匯入佇列，省掉前兩步。

**⚠️ 剛釋放的 TR 沒出現？按 Refresh**：佇列畫面是開啟當下的快照。如果釋放完馬上進佇列（或佇列畫面一直開著），可能還看不到剛釋放的 TR——按工具列的 **Refresh**（重新整理）就會出現。之後每次匯入完成，也要按 Refresh 才看得到最新狀態。

佇列畫面每一列是一張 TR，欄位包含：匯入順序、TR 號碼、擁有者（Owner）、說明（Short Text）、狀態（St）。

### 7.2 用 Filter 找到自己的 TR

佇列裡是所有人的 TR，要先篩選：

1. 游標放在要篩選的**欄位標題**上（例如 **Owner** 或 **Request**）
2. 按工具列的 **Set Filter**（漏斗圖示）→ 跳出 Set Filter 對話框
3. 輸入條件（例如自己的使用者名稱、或 TR 號碼）→ 按 **Copy**
4. 畫面只剩符合條件的 TR（找不到剛釋放的 TR 時，先按 **Refresh** 再篩選）

> 課堂共用同一個帳號時，Owner 都一樣，改用 **Request**（TR 號碼）或 **Short Text**（說明）欄位篩選。
> 官方說明：篩選「還沒匯入」的 TR 時，在 Return Code 欄位用 `INIT` 當篩選值。

### 7.3 看 TR 有沒有匯入

**方法一：佇列的狀態圖示（St 欄）**。常見的幾種：

| 圖示說明（游標停在圖示上會顯示） | 意思 |
|---|---|
| Request waiting to be imported | 等待匯入 |
| Import running／Import is scheduled | 匯入中／已排程 |
| **Request already imported** | **已經匯入** |
| Request is ready for import again | 曾經單獨匯入過，整批匯入時會再匯一次 |

佇列也有 **RC**（Return Code）欄：`0` 成功、`4` 警告（通常可接受）、`8` 以上是錯誤，要看記錄。

**方法二：Import History**。佇列畫面的選單 **Goto → Import History**，列出這台系統匯入過的 TR 與回傳碼。

**方法三：從 TR 本身看傳輸記錄**。SE10 找到該 TR → 游標放在 Request 上 → 選單 **Goto → Transport Logs**：看得到 Export（釋放時匯出）與每一台目標系統的 Import 步驟和回傳碼。

> 課堂實例：`S4HK901984` 與 `S4HK901986` 今天 10:10 匯入 `S4H`、Client `130`，所有步驟回傳碼都是 `0000`（查匯入記錄表 `TPALOG` 確認）。

### 7.4 按哪個按鈕執行匯入

**實務做法：游標放在要傳的那張 TR，按 Import Request**——一次只處理自己確定要傳的 TR。

1. 游標放在要匯入的 TR 上（有多張時依 TR 號碼順序，一張一張來）
2. 按工具列的 **Import Request**（單張卡車圖示）→ 跳出 **Import Transport Request** 對話框
3. **Target Client** 填要匯入的 Client（本課程 `130`）
4. **Options** 頁籤預設勾選 **Leave transport request in queue for later import**：單張匯入後 TR 仍留在佇列（標示已匯入），下次整批匯入時會依順序再處理一次——**保持預設即可**
5. 按 **Continue** → 確認 **Start Import** 對話框的系統與 Client → 確認

匯入完成後，按 **Refresh** 更新畫面，狀態變成 **Request already imported**，RC 顯示回傳碼。

**⚠️ 不要按 Import All Requests**（整批卡車圖示）：它會把佇列裡**所有人**等待中的 TR 全部依序匯入——別人還沒測好、還不該上線的 TR 也會一起進目標系統，而且匯入後無法撤回。這個按鈕要非常小心，一般開發人員不用它。

> 需要權限：匯入自己的 TR 要 `S_CTS_IMPSGL`；匯入別人的、或整批匯入要 `S_CTS_IMPALL`。多數公司只給 Basis 匯入權限，開發人員只要會看佇列與記錄即可。

## 8. 相關 T-code 總整理

| T-code | 用途 |
|---|---|
| SE80 | 建立 Package、瀏覽套件下所有物件 |
| SE21 | Package 專用維護畫面（與 SE80 功能相同） |
| SE09／SE10 | Transport Organizer：建立、檢視、釋放 TR |
| SE03 | Transport Organizer Tools：搜尋物件在哪些 TR 裡等進階工具 |
| SE38 → Utilities → Versions | 版本管理：比對、回復 |
| STMS | Transport Management System：匯入佇列、匯入、匯入記錄 |
| STMS_IMPORT | 直接開啟目前系統的匯入佇列 |

## 9. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 建物件時沒被問 TR | 建在 `$TMP`，這個物件永遠不會被傳輸 |
| Request 的 Release 按不下去 | 底下還有 Task 沒釋放 |
| 想把修改放回已釋放的 TR | 不可能；釋放後再修改一律掛新 TR |
| 改某支程式時系統硬要你用別人的 TR | 物件已被那張尚未釋放的 TR 鎖住 |
| 正式機跑的是舊版 | 新 TR 還沒匯入，或 TR 匯入順序顛倒（舊蓋新） |
| 佇列找不到自己的 TR | 畫面沒 **Refresh**（太早進佇列）、TR 還沒釋放，或 Filter 條件打錯 |
| 按了 Import All Requests | 把佇列裡所有人的 TR 都匯進去了——練習時只用 Import Request |
| 一張 TR 塞了好幾個不相干的功能 | 其中一個功能出問題時沒辦法單獨傳輸其他功能；一個功能一張 TR |

## 10. 課堂練習

完成 [ex08a](../ex08a_package_transport.md)：建 Package → 建程式掛 TR → 釋放 Task 與 Request → 看版本 → 再修改掛新 TR → 在 STMS 篩選並匯入自己的 TR → 確認匯入記錄。
