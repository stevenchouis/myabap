# 講義 0a：環境準備——SAP GUI 安裝登入與 ABAP Workbench 導覽

> 本講是動手課但沒有程式作業：目標是把開發環境裝好、登得進去，並把 ABAP Workbench 的各個工具實際走一遍。上完本講，lec01 起的所有練習你都知道「在哪裡做、按什麼鍵」。

## 本講重點

- SAP GUI 安裝與 SAP Logon 連線設定
- 登入畫面：Client / 帳號 / 密碼 / 語言，與登入後的畫面元素
- GUI 基本操作：命令欄（`/n`、`/o`）、F1/F4、多重 Session
- ABAP Workbench 工具導覽：SE80、SE38、SE11、SE16N、SE37、ST22
- SE38 編輯器核心操作：語法檢查、啟用、執行、Pretty Printer、除錯起手式

## 1. SAP GUI 安裝

SAP GUI（俗稱前端、Logon）是連 SAP 的用戶端程式，Windows 版本目前常見 7.70 / 8.00。

- **安裝來源**：企業環境一律跟公司 IT 或 Basis 要安裝包（版本、修正檔等級要跟公司統一）；原廠下載在 SAP Support Portal（要 S-user 帳號），自己不要亂裝來路不明的版本。
- 安裝時勾選預設元件即可；裝完桌面會有 **SAP Logon** 圖示——它是「連線管理器」，真正的 GUI 視窗由它啟動。
- 常見加裝：GUI scripting（自動化用，公司政策可能關閉）、SAP GUI 中文語言包（顯示語言見登入節）。

## 2. SAP Logon 連線設定

第一次使用要新增系統連線（公司通常會發設定檔或由 IT 預埋，這裡了解手動設定以備不時之需）：

1. 開 SAP Logon → Connections 按 New（新增項目）→ 選 Custom Application Server。
2. 填入四個關鍵欄位（跟 Basis 要）：

| 欄位 | 內容 | 範例 |
|---|---|---|
| Description | 自己看的名稱 | DEV 開發機 |
| Application Server | AP 伺服器 IP 或主機名 | 192.168.x.x |
| Instance Number | 實例編號，2 碼 | 00 |
| System ID (SID) | 系統識別碼，3 碼 | DEV |

3. 若公司有負載平衡，改選 Group/Server Selection（填 Message Server 與 Logon Group）；跨網段可能還要 SAProuter 字串——這些都屬 Basis 管轄，照抄他們給的值即可。

> 對應第 0 講的 Landscape 觀念：DEV / QAS / PRD 會是 SAP Logon 裡三個不同的連線項目。**看清楚再登入**，開發只在 DEV 做。

## 3. 登入與登出

雙擊連線項目出現登入畫面，四個欄位：

| 欄位 | 說明 |
|---|---|
| Client | 3 碼（跟 Basis 確認，如 130）——不同 Client 資料互相隔離（見講義 0 第 4 節） |
| User | 你的帳號 |
| Password | 首次登入會強制改密碼 |
| Language | `EN` 英文／`ZF` 繁中（系統要有裝該語言包）；建議開發者用 EN，錯誤訊息查資料方便 |

登入注意事項：

- 密碼連錯數次帳號會被鎖，鎖了找 Basis 解（SU01）。
- 同帳號重複登入會跳警告視窗：選「繼續本次登入並中斷其他連線」或「維持多重登入」——公司授權政策可能禁止多重登入，依規定選。
- 登出：System → Log Off，或命令欄輸入 `/nex`（**不儲存直接全部關閉**，小心用）。

## 4. GUI 畫面與基本操作

登入後的主畫面（SAP Easy Access）元素：左側功能樹、上方**命令欄**（輸入 T-code 的白色框）、最下方**狀態列**（訊息、系統/Client/回應時間都顯示在這）。

| 操作 | 說明 |
|---|---|
| `/n<Tcode>` | 結束目前畫面、跳到新 T-code（如 `/nSE38`） |
| `/o<Tcode>` | **開新視窗**執行 T-code（同時最多 6 個 session） |
| `/n` | 回主畫面 |
| `F1` | 游標所在欄位的**說明**（含技術資訊：按進去能看到欄位的資料表與欄位名——查表利器） |
| `F4` | 欄位的**可能值清單**（搜尋幫手 Search Help） |
| `F3` / 綠色返回 | 上一頁 |
| `F8` | 執行 |

> 開發者日常至少開兩個 session：一個寫程式（SE38）、一個查資料（SE16N）或測試執行，用 `/o` 開。

## 5. ABAP Workbench 工具導覽

ABAP Workbench 是開發工具的總稱（T-code 家族 SE 開頭為主）。兩種使用習慣：從 **SE80**（Object Navigator，單一入口左樹右編輯）做所有事，或依任務直接進個別工具——課程以個別工具為主，對照如下：

| T-code | 名稱 | 用途與本課程用法 |
|---|---|---|
| SE38 | ABAP Editor | 建立/修改/執行程式——**每一講都用** |
| SE80 | Object Navigator | 總覽套件下所有物件；看程式＋INCLUDE 結構（講義 14）最方便 |
| SE11 | ABAP Dictionary | 看資料表定義、Data Element、Domain（講義 6 起） |
| SE16N | Data Browser | 直接看表內容、下條件查資料（驗證程式撈的數對不對） |
| SE37 | Function Builder | 建立/單測 Function Module（講義 15） |
| SE91 | Message Maintenance | 訊息類別維護（MESSAGE 進階用法） |
| ST22 | Dump Analysis | 程式當掉（runtime error）的完整紀錄——除錯第一站 |
| SM37 | Job Monitor | 背景執行的程式在這看結果 |

導覽時務必體驗 Workbench 的兩個殺手級操作：

- **前進導覽（Forward Navigation）**：對任何名字**雙擊**就跳到它的定義——程式裡雙擊 FORM 名跳到 FORM、雙擊資料表名跳進 SE11。回程按 F3。
- **Where-Used（使用處清單）**：物件上按 Ctrl+Shift+F3（或工具列望遠鏡＋箭頭圖示），列出誰在用它——改共用物件前的保命動作（講義 14 會再強調）。

## 6. SE38 核心操作（每天的手感）

| 操作 | 快捷鍵 | 說明 |
|---|---|---|
| 語法檢查 | `Ctrl+F2` | 寫完先檢查，訊息會標行號 |
| 啟用 Activate | `Ctrl+F3` | **存檔 ≠ 啟用**，執行的是 active 版本（見講義 1） |
| 執行 | `F8` | 直接跑；有選擇畫面會先停在畫面 |
| Pretty Printer | `Shift+F1` | 自動排版（縮排、大小寫），寫完習慣按一下 |
| 顯示/修改切換 | `Ctrl+F1` | 眼鏡/鉛筆圖示；唯讀模式防手滑 |
| 版本管理 | Utilities → Versions | 比對/還原歷史版本（正式物件搭配 TR 產生版本） |
| 除錯 | 命令欄輸入 `/h` 再執行，或程式裡設中斷點 | 單步 F5、跳過 F6、跑到底 F8——課堂先會「開得起來、看得到變數值」即可，深入用法隨練習累積 |

另外認識兩個編輯器設定（New Front-End Editor）：行號顯示、程式碼補全（Ctrl+Space），在編輯器右下角工具鈕裡。

## 7. 課後任務（無程式作業）

1. 完成 GUI 安裝與 DEV 登入，改好密碼，把狀態列的系統/Client 資訊截圖存查。
2. 用 `/o` 同時開 SE38 與 SE16N 兩個 session；在 SE16N 查 T000 表（Client 清單），對照講義 0 的 Client 觀念。
3. 在 SE38 打開任一系統程式（如 `SAPBC_DATA_GENERATOR`）練習：唯讀瀏覽、雙擊前進導覽、F3 返回、Where-Used。
4. 進 ST22 看一筆 dump，找到「錯誤發生的程式行」那個段落。

> 環境就緒，下一講（[lec01](lec01_syntax_basics.md)）寫第一支程式。
