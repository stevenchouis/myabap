# 表單設計練習 2：版面元件、量測與 Smart Style

## Lecture

sf01 已經建出一張最簡單的表單（一個 MAIN Window 裡放一句 `Hello Smartform!`），也第一次踩過「Smart Style 是強制項目」這個規定。這題要把版面的積木元件、精確定位的量測方法、以及 Smart Style 的段落/字元格式，一次串起來——目標是讓你能看懂 Form Painter 的整棵導覽樹在講什麼，而不是只會照抄步驟。

**Smart Forms 的真實階層只有兩層，不是三層**（sf02 課綱草稿一開始寫錯過，已在 README 修正並記錄教訓）：已用 `mcp__sap-docs__search` 查證官方文件《Node Types: Overview》——建立一張 Smart Form 之後，Form Painter 的導覽樹一開始就有兩個根節點：

- **Global Settings**：底下是 Form Attributes、Form Interface、Global Definitions，管的是整張表單的全域設定（sf01 已經碰過 Form Attributes）
- **Pages and Windows**：底下才是 **Page（頁）→ Window（視窗）** 兩層——Page 底下可以直接放 Window／Graphic／Address；Window 底下才放 Text／Table／Template 這些真正輸出內容的節點。沒有獨立的「Page Window」物件（那是 SAPscript 專屬的，見 `.claude/rules/sap-adt-mcp.md` 第 19 節）

官方文件也提到一個對 sf01 有幫助的事實：**「建立表單之後，第一頁上已經自動存在一個 Main Window」**——這就是為什麼 sf01 不用自己建 MAIN，只要在既有的 MAIN 底下加 Text 節點即可。

**Orientation（方向）是 Page 的屬性，不是 Form Attributes 的屬性**：sf01 一開始誤以為 `Form Attributes` 應該要有個 Orientation 欄位可以選 Portrait/Landscape，經使用者實測+確認才知道畫錯了地方——**Orientation 是掛在每一個 `Page` 節點自己身上**（例如系統預設的 `%PAGE1 New Page`），不是表單全域的設定。這點呼應 Page→Window 這個階層的設計邏輯：Page 是版面配置的最外層容器，紙張規格、方向這些「這一頁長怎樣」的屬性自然掛在 Page 節點上；也因為方向是掛在個別 Page 上，**同一張表單裡不同的 Page 理論上可以設定不同方向**（例如正文頁直印、附表頁橫印）。這題只用系統預設的第一頁，維持預設方向即可，不用另外調整。

**Window 的四種類型**（已查證官方文件《Main Window and Secondary Windows》《Creating Windows》）：

| 類型 | 數量限制 | 換頁行為 | 用途 |
|---|---|---|---|
| **Main Window** | 一張表單**只能有一個** | 內容溢出時**自動換頁**，接續到下一頁的 Main Window 繼續輸出（流動文字） | 明細列表、正文這類「不知道會印幾頁」的內容 |
| **Secondary Window** | 可以多個 | 內容溢出時**被截斷**，不會觸發換頁；固定輸出區域 | 頁首公司抬頭、頁尾簽核欄這類「位置固定、內容量可預期」的區塊 |
| **Copies Window** | Secondary Window 的子類型，多一組控制「只在正本/副本列印」的屬性 | 同 Secondary | 正本／副本要顯示不同內容時用 |
| **Final Window** | Secondary Window 的子類型 | 等所有其他節點都處理完才輸出 | 表單最後才要印的內容（如總計、最終簽核） |

⚠️ 官方文件特別提醒：**Main Window 在每一頁的寬度必須一致（高度可以不同）**，且**一張表單只能指定一個 Main Window**——這跟 Secondary Window 可以在不同頁面有不同大小、可以有多個是明顯的差異。

**輸出內容的節點類型**（同樣查證自《Node Types: Overview》，這題只會用到前三種，其餘列出讓你知道 Form Painter 裡還有什麼）：

| 節點 | 用途 |
|---|---|
| **Text** | 輸出任何文字（含表格內容），本題 sf01 已經用過 |
| **Template** | 輸出**固定列數/欄數**的表格——版面配置在設計期就決定好，本題主要練這個 |
| **Table** | 輸出**動態列數**的表格，自動產生 Header／Main Area／Footer 三個子節點——資料量不確定、要跑迴圈輸出明細時用（sf05「資料傳遞」才會深入教，這題只需要知道 Template 跟 Table 的差異） |
| Graphics／Address | 圖形（sf03 教）、地址（系統自動從地址主檔讀取格式化） |
| Loop／Alternative | 流程控制（重複處理／條件分支，sf05 深入教） |
| Folder／Complex section／Program lines／Commands | 分組、複合屬性、內嵌 ABAP 程式碼、特殊指令（換頁等），本課程不深入 |

官方 FAQ 對 Table／Template 的差異講得很直白：**「Template 是固定列數欄數，輸出是固定的；Table 的大小取決於執行期程式傳了多少資料進來」**——這題選 Template 是因為內容是設計期就知道的靜態資料，不需要動態列數。

**量測與定位**：每個 Window 節點自己的屬性頁裡有 **Position**（起始座標）與 **Size**（寬高）兩組數值，對應 Form Painter 畫面上這個視窗的位置與大小（官方文件《Creating Windows》：「The Position and Size values in the Output Options box correspond to the position in the Form Painter」）。⚠️這兩組數值的畫面呈現方式可能因系統版本/個人化設定而略有不同（cm 或 inch），本課程統一用 **cm** 表示，座標原點在頁面**左上角**（X 往右增加、Y 往下增加，跟 SAPscript 的 `XORIGIN`/`YORIGIN` 觀念一致）。除了直接打數字，也可以直接在 Form Painter 畫面用滑鼠拖曳調整，但**要做到「精確對齊」（例如頁首框要剛好在正文上方留 0.5cm 間距），用數字輸入比用滑鼠拖曳準確得多**，這是本題「如何量測表單尺寸」的核心練習。

**Smart Style 複習與加深**：sf01 已經知道每張表單「必須」指派一個 Smart Style，但當時只建了一個完全不客製化的佔位版本。Smart Style 裡真正的內容是：

- **Paragraph Format（段落格式）**：控制一整段文字的字型、大小、粗細、行距、縮排——每個段落格式有一個代碼（例如 `P1`），Text 節點裡的文字要指定套用哪個段落格式
- **Character Format（字元格式）**：套用在一段文字**局部**（例如整段文字裡某幾個字要粗體強調），是段落格式之上的疊加效果
- **指派範圍**：sf01 提過 Smart Style 是在 Form Attributes **全域**指派，但官方文件《Smart Styles》也提到：**可以在個別節點（例如某個 Text 節點）局部指派 Smart Style，這個局部指派會蓋過全域設定，作用範圍是該節點的整棵子樹**——這代表一張表單原則上共用一個全域 Style，但某個特殊區塊想要完全不同的字型風格時，可以局部覆蓋，不用整張表單重做

這題會建一個有**兩個自訂段落格式**的 Smart Style（一個當標題用、一個當內文用），取代 sf01「完全不客製化」的最小佔位版本。

## 學習目標

- 能講出 Smart Forms 正確的兩層階層（Page→Window），以及 Global Settings／Pages and Windows 這兩個根節點各自管什麼
- 能分辨 Main Window 跟 Secondary Window 的核心差異（換頁行為、數量限制），並說出 Copies／Final Window 是 Secondary Window 的子類型
- 能分辨 Template（固定列數欄數）跟 Table（動態列數）的使用時機
- 能用數字輸入的方式精確設定 Window 的 Position／Size，而不是只靠滑鼠拖曳
- 能建立一個含多個自訂 Paragraph Format 的 Smart Style，並讓不同 Text 節點套用不同格式

## 事前準備

- 延續 sf01 的 `ZSF_01_HELLO`／`ZSTY_01_HELLO`，但這題**建立新物件**（不修改 sf01 的成果，維持每題獨立可驗收）：Smartform 本體 `ZSF_02_LAYOUT`，Smart Style `ZSTY_02_LAYOUT`
- 一樣需要在 SAP GUI 手動操作（原因見 sf01 Lecture／`.claude/rules/sap-adt-mcp.md` 第 19 節），Claude 只建立呼叫端程式並語法檢查

## 題目需求

這題要做一張簡單的「內部備忘錄」靜態版面（不接任何動態資料，資料綁定留給 sf05），版面規格如下（A4 直印，21cm × 29.7cm）：

1. **建立 Smart Style `ZSTY_02_LAYOUT`**，包含兩個自訂 Paragraph Format：

   | 段落格式代碼 | 用途 | 建議設定 |
   |---|---|---|
   | `P1` | 標題 | 字型加大（例如 14pt）、**粗體** |
   | `P2` | 內文 | 一般大小（例如 10pt）、正常字重 |

   到 **Header Data → Standard Settings** 分頁，**Standard Paragraph** 欄位選 `P1` 或 `P2` 其中之一（⚠️這是強制必填欄位，sf01 已踩過這個坑：沒填會在存檔時報錯「Standard Paragraph is not filled」，見 sf01 Lecture 的更正說明——sf01 的 `ZSTY_01_HELLO` 只建了一個 `P1` 所以沒得選，這題有兩個可以選，建議選內文用的 `P2` 當預設，畢竟大部分文字都是內文）。

   啟用這個 Smart Style。

2. **建立 Smartform `ZSF_02_LAYOUT`**，`Form Attributes` 節點的 `Output Options` 分頁（sf01 已更正過：Page Format／Style 都在這個分頁，不是分開的分頁）指派 Style 為 `ZSTY_02_LAYOUT`（沿用需求 1 已建好的物件），Page Format 沿用 sf01 的 `DINA4`。Orientation（方向）**不在這裡設定**——經使用者確認，Orientation 是每一個 `Page` 節點自己的屬性（不是 Form Attributes 這個全域層級），這題用系統預設的第一頁、維持預設方向即可，不用特別調整；如果之後真的需要橫印，就是去該 `Page` 節點自己的屬性頁裡設定。

3. **新增一個 Secondary Window** 當作備忘錄的頁首框：

   | 屬性 | 值 |
   |---|---|
   | 名稱 | `HEADER`（自訂即可） |
   | 類型 | Secondary Window |
   | Position | X-Origin `2` cm，Y-Origin `2` cm |
   | Size | Width `17` cm，Height `2` cm |

   裡面放一個 Text 節點，套用段落格式 `P1`，內容輸出 `ZSF_02_LAYOUT 練習 - 內部備忘錄`。

4. **調整既有的 MAIN Window 位置**，讓正文從頁首框下方 0.5cm 開始（`2 + 2 + 0.5 = 4.5`）：

   | 屬性 | 值 |
   |---|---|
   | Position | X-Origin `2` cm，Y-Origin `4.5` cm |
   | Size | Width `17` cm，Height 維持系統預設或自行拉長 |

5. **在 MAIN Window 裡加一個 Template 節點**，固定 2 欄 × 3 列，靜態填入下面內容（不用接資料，直接打死值），每一格文字套用段落格式 `P2`：

   | 欄1（Label） | 欄2（Value，先寫死佔位文字即可） |
   |---|---|
   | 日期 | 2026/07/21 |
   | 文號 | SF02-001 |
   | 頁次 | 第 1 頁 |

6. **啟用整組物件**（Smart Style → Smartform，順序跟 sf01 一樣：Style 要先能啟用，表單才啟得動）。

7. **呼叫端程式**：Claude 會建立 `ZR_SF02_DEMO`（`PROG/P`，套件 `$TMP`），沿用 sf01 的骨架（`SSF_FUNCTION_MODULE_NAME` + 動態 `CALL FUNCTION`），`formname = 'ZSF_02_LAYOUT'`。

8. **驗證**：用 `SMARTFORMS` 的 Test/Print Preview 或執行 `ZR_SF02_DEMO`，確認：
   - 頁首框（Secondary Window）文字是粗體大字（`P1`）
   - 正文區（Template，`P2`）跟頁首框中間有清楚的間距，2 欄 3 列對齊整齊
   - 兩個 Window 沒有互相重疊

## 操作重點提示

這題你會自己在 GUI 操作，這裡列建立順序上的重點提醒（不逐步展開每個按鈕，細節可以對照 sf01 的 Step by Step 風格）：

1. **先用 `SMARTSTYLES` 獨立建好 Smart Style 再建表單**——⚠️sf01 出題時曾誤以為「在表單的 Style 欄位輸入新名稱會跳出建立提示」，使用者實測後發現不是這樣：輸入不存在的名稱只會顯示紅字錯誤「does not exist」，**沒有任何建立提示**，正確順序是先用 `SMARTSTYLES` 交易碼把 Style 建好、啟用，回到表單時只是引用這個已存在的名稱（見 sf01 Lecture 的更正說明）
2. Style Builder 裡新增 Paragraph Format：導覽樹的 Paragraph Formats 資料夾按右鍵 → Create，輸入代碼 `P1`（固定兩個字元），在右側屬性頁設定字型/大小/粗體；`P2` 同樣方式新增；**兩個都建好後別忘了回 Header Data → Standard Settings 分頁把 Standard Paragraph 填成 `P1` 或 `P2`**（強制必填，見題目需求 1 的提醒），填完才能 Activate
3. 表單裡新增 Window：對 Page 節點按右鍵 → Create → Window，選 **Secondary Window** 類型；Position／Size 這兩組數值在該 Window 的屬性頁裡（確切分頁名稱可能因版本略有出入，找「Position」「Size」關鍵字即可，跟 Form Painter 畫面顯示會同步）
4. 調整既有 MAIN Window 位置：直接點選 MAIN 節點，改它的 Position／Size 屬性，不用重新建立
5. Template 節點：對 MAIN Window 按右鍵 → Create → Template，先在 Table Painter 設定好 2 欄 3 列的框架，再逐格輸入文字並指定段落格式
6. Text 節點（頁首框裡的標題）：跟 sf01 一樣 Create → Text，但這次要在文字編輯畫面裡指定段落格式 `P1`（不是用系統預設格式）

## 思考題

1. 如果把頁首框（`HEADER`）也改成 Main Window 會發生什麼事？（提示：一張表單只能有一個 Main Window，系統會怎麼反應？）
2. Template 節點的內容是設計期就固定的靜態文字。如果日後要把「文號」欄位改成從 ABAP 程式傳進來的動態值，該用 Template 還是要改用其他機制？（提示：Template 本身可以放變數欄位，但列數/欄數的「表格骨架」是固定的——跟 sf05 會教的 Table＋Loop 動態產生列數是不同層次的「動態」，這題只需要先意識到兩者的差異，不用寫出完整答案）
3. Secondary Window `HEADER` 如果內容太長超過設定的 2cm 高度，官方文件說會發生什麼事？這跟 Main Window 溢出時的行為差在哪？

## 答案

`ZR_SF02_DEMO` 快照見 `zr_sf02_demo.prog.abap`（已建立、語法檢查通過）。`ZSF_02_LAYOUT`（表單本體）與 `ZSTY_02_LAYOUT`（Smart Style，含 `P1`／`P2` 兩個自訂段落格式）都需要你在 `SMARTFORMS`／`SMARTSTYLES` 手動建立（原因見 sf01／`.claude/rules/sap-adt-mcp.md` 第 19 節）——完成後請回報結果，或直接執行 `ZR_SF02_DEMO` 搭配 Print Preview 確認版面是否符合題目需求的座標與段落格式。
