---
marp: true
theme: default
paginate: true
headingDivider: false
style: |
  section {
    font-family: 'Microsoft JhengHei', 'Noto Sans TC', sans-serif;
    font-size: 26px;
    padding: 60px;
  }
  section.lead {
    text-align: center;
    justify-content: center;
  }
  section.lead h1 { font-size: 56px; }
  code, pre {
    font-family: Consolas, 'Courier New', monospace;
  }
  pre {
    font-size: 21px;
    line-height: 1.45;
  }
  table { font-size: 23px; }
  section.compact pre { font-size: 19px; }
  section.compact table { font-size: 20px; }
  blockquote {
    border-left: 6px solid #0a6ed1;
    padding-left: 16px;
    color: #333;
    background: #eef6fc;
  }
  footer { color: #999; }
---

<!-- _class: lead -->
<!-- _paginate: false -->

# 講義 8a
# Package 與傳輸請求——SE80／SE10／STMS

ABAP 基礎教育訓練（授課順序：接在講義 8 之後、講義 15 之前）

對應練習 ex08a｜驗收：SE10 傳輸記錄＋STMS 匯入狀態

---

## 本講重點

- **Package**：物件歸屬與傳輸路線；`$TMP` vs 正式 Package（SE80）
- **TR**：Request 與 Task 兩層結構（SE10）
- **釋放順序**：先 Task，再 Request
- **TR 與版本**：釋放時存版本，可比對、可回復
- **釋放後再修改**：一定掛**新 TR**
- **STMS**：Filter 找 TR、看是否已匯入、執行匯入

---

## 1. 為什麼要有 Package 與 TR

| 系統 | 用途 |
|---|---|
| DEV | 開發人員寫程式 |
| QAS | 使用者驗收 |
| PRD | 每天營運，**不能直接改程式** |

- **Package**：物件屬於哪個專案、走哪條傳輸路線
- **TR**：這一次改了哪些物件，是傳輸的單位
- `$TMP`：只存在這台系統，**永遠不會被傳輸**

> 傳輸路徑由 **Basis 設定**：釋放後系統自動決定 Target System、排進佇列
> 本課程是單一系統 `S4H` → STMS 練習匯入 `S4H` 自己

---

<!-- _class: compact -->

## 2. 建立 Package（SE80）

SE80 → 下拉選 **Package** → 輸入名稱 → Enter → Yes

| 欄位 | 本系統的值 |
|---|---|
| Package | 課堂實例：`ZMM1`、`ZMM2`（`Z`／`Y` 開頭） |
| Software Component | `HOME`（客戶自開發） |
| Transport Layer | `ZS4H`（決定往哪裡送） |
| Package Type | Not a Main Package |

Save → 系統要求 TR（**Package 本身也會被傳輸**）

`$TMP` 的程式要上線：SE38 → **Goto → Object Directory Entry** → 改 Package → 掛 TR

---

## 3. Request 與 Task（SE10）

```
S4HK901984  Inventory Report          ← Request：傳輸的單位
  └ S4HK901985  Inventory Report      ← Task：每個開發人員一個
        R3TR DEVC ZMM1
        R3TR PROG ZS_0000001
        R3TR PROG ZS_0000003
```

- 建立：存檔時跳出提示 → **Create Request**，或 SE10 → Create → **Workbench Request**
- 一個功能一張 TR，說明寫清楚
- 物件在**未釋放**的 TR 裡會被鎖住：別人改只能加入同一張

（今天課堂的真實資料）

---

## 4. 釋放順序：先 Task，再 Request

1. SE10 → 勾 **Modifiable** → Display
2. 游標放在 **Task** → **Release**
3. Task 全部釋放後，游標放在 **Request** → **Release**

- Task 沒放 → Request 放不了（所有參與者都要確認改完）
- 釋放 Task：物件併進 Request（記錄 `CORR RELE ...`）
- 釋放 Request：匯出成傳輸檔，排進下一台的匯入佇列

> ⚠️ 釋放後收不回來；什麼時候釋放要跟團隊確認

---

## 5. TR 與版本

TR 釋放時，系統替程式**存一個版本**

SE38 → **Utilities → Versions → Version Management**

- 每個版本標示對應的 TR 號碼
- 勾兩個版本 → **Compare**：看改了哪幾行
- 選舊版本 → **Retrieve**：回復（仍要存檔、啟用、掛 TR）

課堂實例：`ZB_01` 在 `S4HK901986` 釋放後多一個版本

**TR 不只是傳輸的箱子，也是修改履歷**

---

<!-- _class: compact -->

## 6. 釋放後再修改：一定掛新 TR

| 第一次（已釋放） | 再修改（新 TR） |
|---|---|
| `S4HK901986`：`ZMM2`、`ZB_01`、`ZB_02` | `S4HK901988`：`LIMU REPS ZB_02`、`ZB_03`、`ZB_FG01`… |
| `S4HK901984`：`ZMM1`、`ZS_0000001`、`ZS_0000003` | `S4HK901990`：`LIMU REPS ZS_0000003`、`ZS_0000004`… |

| 記錄 | 意思 |
|---|---|
| `R3TR PROG` | 整個物件（新建） |
| `LIMU REPS` | 只有程式原始碼（修改既有程式） |

同一支程式出現在多張 TR → **依順序匯入：先舊後新**，否則舊蓋新

---

## 7. STMS：開啟匯入佇列、用 Filter 找 TR

1. STMS → **Import Overview** → 游標放 `S4H` → **Display Import Queue**
   （或直接 `STMS_IMPORT`）
2. 游標放在欄位標題（**Owner**／**Request**）→ **Set Filter**（漏斗）
3. 輸入條件 → **Copy** → 只剩符合的 TR

> **找不到剛釋放的 TR → 按 Refresh**（太早進佇列，畫面是舊的快照）
> 共用帳號時 Owner 都一樣 → 改篩 **Request** 或 **Short Text**
> 篩「還沒匯入」的：Return Code 欄填 `INIT`

---

<!-- _class: compact -->

## 7.3 看 TR 有沒有匯入

**St 欄圖示**（游標停在圖示上看說明）

| 說明 | 意思 |
|---|---|
| Request waiting to be imported | 等待匯入 |
| Import running／scheduled | 匯入中／已排程 |
| **Request already imported** | **已匯入** |
| Request is ready for import again | 單獨匯入過，整批時會再處理 |

**RC**：`0` 成功、`4` 警告、`8` 以上錯誤

其他方法：佇列 **Goto → Import History**；SE10 → TR → **Goto → Transport Logs**

課堂實例：`S4HK901984`／`S4HK901986` 匯入 `S4H` Client 130，RC `0000`

---

## 7.4 按哪個按鈕匯入

1. 游標放在要傳的那張 TR → **Import Request**（單張卡車）
2. **Target Client** 填 `130`
3. Options 預設勾 **Leave transport request in queue for later import** → 保持
4. **Continue** → 確認 Start Import
5. **Refresh** → 狀態變 **Request already imported**

> ⚠️ **不要按 Import All Requests**（整批卡車）：會把**所有人**的 TR
> 一起匯入，包含還不該上線的，而且收不回來

權限：自己的 TR 要 `S_CTS_IMPSGL`；別人的／整批要 `S_CTS_IMPALL`

---

<!-- _class: compact -->

## 8. T-code 總整理與常見錯誤

| T-code | 用途 |
|---|---|
| SE80／SE21 | 建立 Package |
| SE09／SE10 | 建立、檢視、釋放 TR |
| SE03 | 進階工具（找物件在哪些 TR） |
| SE38 → Versions | 版本比對、回復 |
| STMS／STMS_IMPORT | 匯入佇列、匯入、記錄 |

| 症狀 | 原因 |
|---|---|
| 建物件沒被問 TR | 建在 `$TMP` |
| Request 放不了 | Task 還沒釋放 |
| 正式機跑舊版 | 新 TR 沒匯入，或順序顛倒 |
| 佇列找不到 TR | 沒 Refresh、還沒釋放、或 Filter 打錯 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex08a**：

建 Package → 建程式掛 TR → 先放 Task 再放 Request →
看版本 → 再修改掛新 TR → STMS 篩選並匯入 → 看傳輸記錄
