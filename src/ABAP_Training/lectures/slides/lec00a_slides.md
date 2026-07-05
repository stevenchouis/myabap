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

# 講義 0a
# 環境準備

SAP GUI 安裝登入與 ABAP Workbench 導覽

上完本講，之後所有練習你都知道「在哪裡做、按什麼鍵」

---

## 本講重點

- SAP GUI 安裝與 SAP Logon 連線設定
- 登入畫面：Client / 帳號 / 密碼 / 語言
- GUI 基本操作：命令欄（`/n`、`/o`）、F1/F4、多重 Session
- ABAP Workbench 工具導覽：SE80、SE38、SE11、SE16N、SE37、ST22
- SE38 核心操作：語法檢查、啟用、執行、Pretty Printer

---

## 1. SAP GUI 安裝

SAP GUI（俗稱前端、Logon）：連 SAP 的用戶端，常見 7.70 / 8.00

- **安裝來源**：一律跟公司 IT 或 Basis 要安裝包
  （版本要跟公司統一；不要亂裝來路不明的版本）
- 裝完桌面有 **SAP Logon** 圖示
  ——它是「連線管理器」，真正的 GUI 視窗由它啟動
- 常見加裝：GUI scripting、中文語言包

---

## 2. SAP Logon 連線設定

SAP Logon → Connections → New → Custom Application Server

| 欄位 | 內容 | 範例 |
|---|---|---|
| Description | 自己看的名稱 | DEV 開發機 |
| Application Server | AP 伺服器 IP | 192.168.x.x |
| Instance Number | 實例編號 2 碼 | 00 |
| System ID (SID) | 系統識別碼 3 碼 | DEV |

負載平衡（Group Selection）、SAProuter → 照抄 Basis 給的值

> DEV / QAS / PRD 是三個不同連線項目
> **看清楚再登入，開發只在 DEV 做**

---

## 3. 登入與登出

| 欄位 | 說明 |
|---|---|
| Client | 3 碼（如 130）——不同 Client 資料互相隔離 |
| User | 你的帳號 |
| Password | 首次登入強制改密碼 |
| Language | `EN` 英文／`ZF` 繁中；**建議開發者用 EN**，查錯誤訊息方便 |

- 密碼連錯會鎖帳號 → 找 Basis 解（SU01）
- 重複登入跳警告 → 依公司授權政策選
- 登出：System → Log Off；`/nex` 是**不儲存直接全關**，小心用

---

## 4. GUI 畫面與基本操作

主畫面（SAP Easy Access）：左側功能樹、上方**命令欄**、下方**狀態列**

| 操作 | 說明 |
|---|---|
| `/n<Tcode>` | 結束目前畫面、跳新 T-code（`/nSE38`） |
| `/o<Tcode>` | **開新視窗**（最多 6 個 session） |
| `F1` | 欄位**說明**（含技術資訊：能查到資料表與欄位名） |
| `F4` | 欄位**可能值清單**（Search Help） |
| `F3` | 上一頁 |
| `F8` | 執行 |

> 日常至少開兩個 session：一個寫程式、一個查資料（用 `/o`）

---

## 5. ABAP Workbench 工具導覽

| T-code | 名稱 | 本課程用法 |
|---|---|---|
| SE38 | ABAP Editor | 寫程式——**每一講都用** |
| SE80 | Object Navigator | 看程式＋INCLUDE 結構（講義 14） |
| SE11 | ABAP Dictionary | 資料表定義、DE、Domain（講義 6 起） |
| SE16N | Data Browser | 直接看表內容、驗證程式撈的數 |
| SE37 | Function Builder | Function Module（講義 15） |
| SE91 | Message Maintenance | 訊息類別（講義 22） |
| ST22 | Dump Analysis | 程式當掉——**除錯第一站** |
| SM37 | Job Monitor | 背景執行結果 |

---

## 兩個殺手級操作（務必體驗）

**前進導覽（Forward Navigation）**
對任何名字**雙擊**就跳到它的定義
- 雙擊 FORM 名 → 跳到 FORM
- 雙擊資料表名 → 跳進 SE11
- 回程按 F3

**Where-Used（使用處清單）**
物件上按 `Ctrl+Shift+F3`，列出誰在用它
→ **改共用物件前的保命動作**（講義 14 再強調）

---

## 6. SE38 核心操作（每天的手感）

| 操作 | 快捷鍵 | 說明 |
|---|---|---|
| 語法檢查 | `Ctrl+F2` | 寫完先檢查，訊息標行號 |
| 啟用 Activate | `Ctrl+F3` | **存檔 ≠ 啟用**，執行的是 active 版本 |
| 執行 | `F8` | 有選擇畫面會先停在畫面 |
| Pretty Printer | `Shift+F1` | 自動排版，寫完習慣按一下 |
| 顯示/修改切換 | `Ctrl+F1` | 唯讀模式防手滑 |
| 版本管理 | Utilities → Versions | 比對/還原歷史版本 |
| 除錯 | `/h` 再執行 | 單步 F5、跳過 F6、跑到底 F8 |

編輯器設定：行號顯示、程式碼補全（`Ctrl+Space`）

---

<!-- _class: lead -->

# 課後任務

完成 GUI 安裝與 DEV 登入，改好密碼

用 `/o` 同開 SE38 + SE16N；SE16N 查 T000 表對照 Client 觀念

SE38 開系統程式練習：前進導覽、F3 返回、Where-Used

ST22 看一筆 dump，找到「錯誤發生的程式行」

**環境就緒，下一講 lec01 寫第一支程式**
