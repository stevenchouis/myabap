# 表單設計練習 1：為什麼要用 Smartform

## Lecture

基礎課 ex12「列印排版」教的是 **Classical List**：用 `WRITE`/`AT`/`ULINE`/`TOP-OF-PAGE` 這些指令，靠精確計算欄位位置（第幾欄、寬度幾格）拼出一份純文字報表，本質上是把畫面當成一張等寬字元格的表格在排版。這種做法能做出堪用的報表，但有兩個天生的限制：**排版是用座標數字硬算出來的**（改一個欄寬，後面所有欄位位置都要重算），以及**只能輸出等寬字元、沒有真正的圖形元素**（畫不出公司 Logo、無法用不同字型大小強調標題、線條粗細固定）。當需求從「跑一份給自己看的內部報表」升級成「印一張要給客戶看的正式單據」（出貨單、發票、對帳單），Classical List 的排版方式就會變得非常吃力。

**SAP 列印輸出技術的演進**，三代工具解決的正是「座標硬算」跟「無法圖形化」這兩個問題：

1. **SAPscript**（最舊，1990 年代技術）：第一代表單工具，交易碼 `SE71`（表單／Layout Set）＋`SE72`（樣式／Style）。已經有基本的圖文混排能力，但版面定位方式仍然接近純文字時代的思維（一行一行寫，靠 Tab 停駐點抓位置），維護體驗差，SAP 從 4.6 版之後就不建議新開發案用它。本課程**不排入 SAPscript 的實作練習**，只需要知道它是 Smartform 的前身、舊系統維護時可能還會遇到即可。
2. **Smartform**（本課程主軸，SAP 從 4.6C 開始主推，交易碼是**獨立的 `SMARTFORMS`**——⚠️容易誤會的地方：`SE71` 是 SAPscript 專用的交易碼，SAPscript 表單在 SAP 的物件分類裡叫「Layout Set」，跟 Smartform 是完全不同的兩種物件、兩支不同的交易碼，兩者**不共用**入口；`SE72`（SAPscript Style）對應的 Smartform 版本是另一支交易碼 `SMARTSTYLES`，同樣是各自獨立。已用 ADT quickSearch 查證：`SE71`/`SE72`/`SE78` 三者的套件（Package）都是 `STXD`（SAPscript 系列），`SMARTFORMS`/`SMARTSTYLES` 的套件是 `SMART`——套件不同就是兩套獨立工具的直接證據）：改用**圖形化的 Form Painter**畫版面——用滑鼠在畫布上拖曳 Window（視窗）、用所見即所得的方式調整框線與位置，脫離「純手動算座標」的痛苦；還內建**流程控制元素**（`LOOP`、`Alternative` 條件顯示），可以直接對應一個 Internal Table 逐筆輸出明細，不用像 Classical List 自己寫 `LOOP AT ... WRITE`。
3. **Adobe Forms（Interactive/Print Forms by Adobe，交易碼 `SFP`）**：更新一代，輸出成 PDF、支援互動式表單欄位（可以讓終端使用者在 PDF 上打字），但需要額外架設 **ADS（Adobe Document Services）伺服器**，不是每套系統都有裝。本課程列為候選的下一階段，這裡先不展開。

**這門課的教學方式跟前面所有課程不一樣，要先說清楚**：`.claude/rules/sap-adt-mcp.md` 第 19 節已經實測查證——`SMARTFORMS`（表單）、`SMARTSTYLES`（樣式）、`SE78`（圖形管理，這支是 SAPscript 與 Smartform**共用**的工具，不受上面「各自獨立」規則影響）這幾個工具**完全沒有 ADT REST API**，抓 `discovery` 全文與物件型別清單都找不到對應的 collection，`sap_create_object`/`sap_get_source`/`sap_set_source` 也沒有這個 objectType 選項。這代表 Smartform 本體（版面配置、Window、Text、Table 元件）**沒辦法由 Claude 直接建立或修改**，只能由你在 SAP GUI 裡用 `SMARTFORMS` 手動操作，Claude 從旁指導步驟、事後靠你回報或間接驗證。但 Smartform 有一個關鍵設計：**它是「表單設計」跟「程式呼叫」分離的兩層架構**——表單本體（Form Painter 畫的版面）是一層，呼叫表單的 ABAP 程式又是另一層，兩者中間靠一個「動態產生的 Function Module 名稱」串接。這個「呼叫端」是純 ABAP 程式碼，跟其他課程一樣可以由 Claude 用 `sap_create_object`/`sap_set_source` 建立、語法檢查、甚至用 `programrun` 端對端驗證。

**呼叫端骨架：`SSF_FUNCTION_MODULE_NAME` + `CALL FUNCTION`**：Smartform 一旦啟用，系統會在背景**自動產生一支 Function Module**，名稱是系統動態配置的（不是你自己取的名字，也不保證每次都一樣），所以呼叫端程式不能寫死 `CALL FUNCTION 'Z...'`，要先用標準 FM `SSF_FUNCTION_MODULE_NAME` 查出這次的實際名稱，再用**動態呼叫**（`CALL FUNCTION lv_fm_name`）：

```abap
DATA: lv_fm_name    TYPE rs38l_fnam,
      ls_ctrl_param TYPE ssfctrlop,
      ls_output_opt TYPE ssfcompop.

" 第一步：把 Smartform 的名字換成這次系統實際產生的 Function Module 名稱
CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
  EXPORTING
    formname           = 'ZSF_01_HELLO'
  IMPORTING
    fm_name             = lv_fm_name
  EXCEPTIONS
    no_form             = 1
    no_function_module  = 2
    OTHERS               = 3.
IF sy-subrc <> 0.
  " 表單不存在或未啟用——處理錯誤
  RETURN.
ENDIF.

" 第二步：控制參數——關掉對話框與預覽畫面，才能無人值守執行（背景/自動化情境常用）
ls_ctrl_param-no_dialog = abap_true.
ls_ctrl_param-preview   = abap_false.

" 第三步：動態呼叫剛剛查到的 Function Module
CALL FUNCTION lv_fm_name
  EXPORTING
    control_parameters = ls_ctrl_param
    output_options      = ls_output_opt
  EXCEPTIONS
    formatting_error    = 1
    internal_error       = 2
    send_error           = 3
    user_canceled        = 4
    OTHERS                = 5.
IF sy-subrc <> 0.
  " 呼叫失敗——處理錯誤
ENDIF.
```

這段骨架有兩個地方值得注意：`formname` 是**固定字串**（表單名稱，設計期就決定），但真正被 `CALL FUNCTION` 呼叫的 `lv_fm_name` 是**執行期才查出來的變數**——這正是為什麼呼叫 Smartform 一定要「查名稱→動態呼叫」兩步，不能像呼叫一般 FM 一樣寫死名字。另外 `control_parameters-no_dialog = abap_true` 這個設定很重要：預設狀態下呼叫 Smartform 會跳出列印對話框或預覽畫面（GUI-only，跟第 16 節記載的 `cl_salv_table` 一樣沒辦法用 `programrun` 無頭驗證），但關掉對話框與預覽後，只要輸出目的地設定得當（例如導到 Spool 而非直接印表機），理論上可以無人值守執行——這點等 sf01 的 Smartform 本體實際建好之後，可以嘗試看看 `programrun` 能不能端對端跑過。

**Global Settings（`SMARTFORMS` 建立表單後的第一個節點：Form Attributes）**：⚠️這裡先更正一個**根據使用者實測畫面才發現的錯誤**——原本以為 Form Attributes／Page Format／Output Options 是三個平行的分頁，但實際畫面（使用者截圖確認）是：導覽樹底下只有 **`Form Attributes` 一個節點**，點開它右側是**兩個分頁**：

- **`General Attributes`**：表單的基本屬性，說明文字、語言等
- **`Output Options`**：這個分頁其實同時裝了好幾組設定——**紙張規格（Page Format，例如 `DINA4`）／字元密度（Characters per Inch）／行距（Lines per Inch）／`Style` 欄位／列印輸出相關設定（Output Format／Mode／Device）全部擠在同一個分頁**，不是分開的獨立分頁

這代表 Lecture／題目需求原本描述的「Page Format 分頁」實際上就是 `Output Options` 分頁裡的一組欄位，不是另一個獨立分頁——這題後面的操作步驟已經照這個更正過的結構重寫。

**⚠️ Orientation（直印／橫印方向）不是在這裡設定**：前一版教材曾經以為 `Form Attributes` 的 `Output Options` 分頁應該要有一個 Orientation 欄位可以選 Portrait/Landscape，結果畫面上根本沒有這個欄位（見更早的截圖修正）。經使用者確認：**Orientation 是每一個 `Page` 節點（`Pages and Windows` 底下，例如系統預設的 `%PAGE1 New Page`）各自的屬性，不是 Form Attributes 這個全域層級的設定**——這代表**同一張表單裡，不同 Page 可以設定成不同方向**（例如第一頁直印、附表那一頁橫印），這點留到 sf02 深入 Page／Window 階層時再說明；sf01 只用系統預設的第一頁、維持預設方向（直印），不需要另外調整。

**⚠️ Smart Style 是強制項目，sf01 也躲不掉**：已用 `mcp__sap-docs__search` 查證 SAP 官方文件《Smart Styles》原文——「**You must assign a Smart Style to each Smart Form. You do this globally for the entire Smart Form in the form attributes.**」（你必須為每一張 Smart Form 指派一個 Smart Style，在 Form Attributes 裡全域指派）。Smart Style（交易碼 `SMARTSTYLES`）定義的是段落格式（Paragraph Format）與字元格式（Character Format），套用到表單裡的 Text／欄位上——概念上對應 SAPscript 的 Style（`SE72`），但一樣是**獨立物件、獨立交易碼**，不是同一個東西（呼應前面 SE71/SMARTFORMS 的教訓，SAPscript 跟 Smartform 的每一組對應物件幾乎都是「概念類似、物件與交易碼各自獨立」）。Smart Style 的深入教學（段落/字元格式怎麼設計、怎麼共用）排在 sf02。

**⚠️ 另一個經使用者實測發現的錯誤**：原本以為在 `Output Options` 分頁的 `Style` 欄位直接輸入一個還不存在的名稱、按 Enter，系統會跳出「要不要建立」的提示、直接分支進 Style Builder——**實測結果不是這樣**：輸入不存在的名稱只會在狀態列顯示紅字錯誤「Style ZSTY_01_HELLO does not exist」，**沒有任何建立提示**。正確順序是：**先**用獨立的 `SMARTSTYLES` 交易碼把 Style 建好、啟用，**再**回到表單的 `Output Options` 分頁輸入這個已經存在的名稱——這題後面的操作步驟已經照這個更正過的順序重寫。

**⚠️ 第三個經使用者實測發現的錯誤，也是最容易卡住的一個**：原本以為 sf01 這種「最簡單、不特別客製化任何格式」的 Smart Style 可以什麼都不填、直接 Activate 過關——**實測結果不是這樣**：`SMARTSTYLES` 的 **Header Data → Standard Settings** 分頁有一個**強制必填欄位「Standard Paragraph」**，沒填就無法存檔，錯誤清單會顯示「Header Data / Standard Paragraph is not filled」。已用 `mcp__sap-docs__search` 查證官方文件《Header Data of a Smart Style》確認這是官方規定：「**You must define the following values in the header data: Standard Paragraph...**」「**You must flag one of the existing paragraphs as default paragraph.**」——也就是說，Header Data 的 Standard Paragraph 欄位裡要填的是一個**已經存在的 Paragraph Format**，代表「這張 Style 沒有另外指定格式時，預設要套用哪一個段落格式」（官方文件補充：把某個 Text 節點的段落格式設成 `*`，就是明確指定「套用這個 Standard Paragraph」）。這代表 sf01 的「最簡單版」Smart Style **至少要建一個 Paragraph Format**，不可能完全零客製化——這題後面的操作步驟已經補上這個必要的最小步驟。

**Paragraph Format 是什麼、怎麼設定**（已查證官方文件《Paragraph Formats》）：段落格式管的是「一整段文字要長什麼樣子」——縮排（Indents）、行距（Spacing）、字型設定（Font：字型／大小／粗體斜體／顏色）、定位點（Tabs）、編號與大綱層級（Numbering and Outline）。建立方式：在 Style Builder 裡選 **Paragraph Formats** 節點 → **Create**，**格式代碼固定是兩個字元**（例如 `P1`），在跳出的屬性頁依序設定各分頁的內容，最後 **Activate**。sf01 只需要建一個最陽春的版本（例如代碼 `P1`，字型維持系統預設、不特別調整），重點是讓它存在、可以被 Header Data 的 Standard Paragraph 選到；真正認真設計段落格式（字型大小、粗體標題等）留到 sf02。

## 學習目標

- 能講出 SAPscript → Smartform → Adobe Forms 三代列印輸出工具的差異與各自定位，並知道本課程只實作 Smartform
- 能分清楚 `SE71`（SAPscript Layout Set）跟 `SMARTFORMS`（Smart Forms）是兩支完全不同的交易碼，不要混用
- 能用 `SMARTFORMS` 建立一個空白 Smartform，正確設定 `Form Attributes` 節點的 `General Attributes`／`Output Options` 兩個分頁（後者含 Page Format／Style 等欄位）
- 知道 **Smart Style 是每張 Smart Form 的強制指派項目**（SAP 官方文件明文規定），能建立一個最簡單的 Smart Style 並在 Form Attributes 指派
- 知道 Smart Style 的 **Header Data 也有強制必填欄位 Standard Paragraph**，必須先建至少一個 Paragraph Format 才能填、才能存檔；能講出 Paragraph Format 的用途（縮排/行距/字型/定位點/編號）與建立方式
- 能講出「為什麼呼叫 Smartform 不能直接 `CALL FUNCTION '固定名稱'`」，並寫出正確的 `SSF_FUNCTION_MODULE_NAME` + 動態 `CALL FUNCTION` 呼叫骨架
- 知道本課程的教學限制：Smartform 本體要在 SAP GUI 手動建立，Claude 只能建立與驗證呼叫端 ABAP 程式

## 事前準備

- 這題**不需要**先建立任何前置物件，但需要你在 SAP GUI 完成一段手動操作（Claude 這邊無法透過 `sap-adt` MCP 建立 Smartform 本體，原因見上方 Lecture 與 `.claude/rules/sap-adt-mcp.md` 第 19 節）。
- 建議先確認你有 `SMARTFORMS` 的開發權限，並且系統有裝字元集支援（中文顯示用，Global Settings 語言留 EN 或按你系統慣例即可，這題內容本身不涉及中文文字元素）。

## 題目需求

1. **先用 `SMARTSTYLES` 建立一個最簡單的 Smart Style `ZSTY_01_HELLO`**（見 Lecture 的說明：這是 SAP 官方規定的強制項目，不能跳過；⚠️要先建好、啟用，不能等到表單那邊才臨時建，見 Lecture 的更正說明）：
   - 建一個最陽春的 Paragraph Format，代碼 `P1`（兩個字元），字型維持系統預設不用調整
   - 到 **Header Data → Standard Settings** 分頁，**Standard Paragraph** 欄位選剛剛建的 `P1`（⚠️這是強制必填欄位，沒填無法存檔，見 Lecture 的第三個更正說明）
   - **Activate** 整個 Style
   - 不需要再客製化其他格式，重點是讓表單有一個合法、通過檢查的 Style 可以指派；認真設計段落格式留到 sf02

2. **在 SAP GUI 用 `SMARTFORMS` 建立一個新 Smartform**（⚠️不是 `SE71`——`SE71` 是 SAPscript Layout Set 專用的交易碼，見 Lecture 的說明），名稱 `ZSF_01_HELLO`，`Form Attributes` 節點的兩個分頁依下表設定：

   | 分頁 | 欄位 | 值 |
   |---|---|---|
   | General Attributes | Description | `SF01 - Hello World 練習表單` |
   | Output Options | Page Format | `DINA4` |
   | Output Options | Style | `ZSTY_01_HELLO`（沿用需求 1 已經建好、啟用的 Style，這裡只是引用既有名稱，不會自動建立） |
   | Output Options | Application | 預設值（通常是 `SAPscript`，維持系統帶出的預設即可） |

3. **在 MAIN Window 裡加一個 Text 元素**，內容輸出純文字 `Hello Smartform!`（不需要任何框線、Logo，這題只求「表單能被呼叫並印出一行字」跑通）。

4. **啟用（Activate）這個 Smartform**（連同 Smart Style 一起，需要都先啟用）。

5. **呼叫端程式**：Claude 會建立 `ZR_SF01_DEMO`（`PROG/P`，套件 `$TMP`），內容依 Lecture 骨架，`formname = 'ZSF_01_HELLO'`，`control_parameters-no_dialog = abap_true`，並在呼叫前後用 `WRITE` 印出 `lv_fm_name` 與 `sy-subrc`，方便你在 SAP GUI 直接執行程式（SE38/SA38 或 F8）觀察結果。

6. **驗證**：你在 SAP GUI 執行 `ZR_SF01_DEMO`，確認：
   - 螢幕先印出查到的動態 Function Module 名稱（格式類似 `/1BCDWB/SF00000xxx`）
   - `SSF_FUNCTION_MODULE_NAME` 的 `sy-subrc = 0`（代表表單存在且已啟用）
   - Smartform 本身有沒有正確印出「Hello Smartform!」，請在跳出的預覽畫面（或 Spool，視你的 `output_options` 設定）確認

## SMARTFORMS 逐步操作教學

題目需求 1～4 要在 SAP GUI 手動完成，以下是完整的 Step by Step 操作說明。**交易碼是 `SMARTFORMS`，不是 `SE71`**（`SE71` 開啟的是 SAPscript Layout Set 維護畫面，輸入 `ZSF_01_HELLO` 這種名稱會被當成 SAPscript 表單處理，不會產生 Smartform；兩者是完全獨立的物件與工具，詳見 Lecture）。⚠️這裡的步驟順序已經根據使用者實測畫面更正過兩次：(1) **Smart Style 要先獨立建好、啟用，不能等到表單那邊才臨時建**——原本以為在表單的 Style 欄位輸入新名稱會跳出建立提示，實測發現只會顯示「Style ... does not exist」的錯誤，不會有任何提示；(2) **Smart Style 本身也不能空白，Header Data 有強制必填的 Standard Paragraph 欄位，要先建一個 Paragraph Format 才能填**，實測發現不填直接存檔會報錯「Header Data / Standard Paragraph is not filled」。

### 步驟一：先用 SMARTSTYLES 建立 Smart Style（含至少一個 Paragraph Format）

依官方文件《Maintenance of Styles with the Style Builder》《Paragraph Formats》《Header Data of a Smart Style》的標準流程：

1. 執行交易碼 `SMARTSTYLES`
2. 在「Style」欄位輸入 `ZSTY_01_HELLO`
3. 點擊工具列的 **Create**（建立）
4. 彈出的建立對話框：
   - **Description**：填 `SF01 - Hello World 練習用 Style`
   - 按 **Enter** 確認
5. 若跳出「Create Object Directory Entry」對話框，選擇套件 `$TMP`
6. **先建一個最陽春的 Paragraph Format**（⚠️這一步不能省略，見下方說明）：
   - 左側導覽樹選 **Paragraph Formats** 節點，按右鍵或工具列 **Create**
   - 在「Paragraph Format」欄位輸入**兩個字元**的代碼，例如 `P1`（官方文件規定段落格式代碼固定兩個字元，不能取更長的名字）
   - 各分頁（Indents and Spacing／Font 等）維持系統預設即可，不用調整
   - 按 **Enter** 確認（這一步不用急著 Activate，等步驟 8 一起啟用整個 Style）
7. **回到 Header Data，填強制必填欄位**：
   - 左側導覽樹選 **Header Data** 節點，切到 **Standard Settings** 分頁
   - **Standard Paragraph** 欄位輸入或用 F4 選剛剛建立的 `P1`（⚠️這是 SAP 官方規定的強制欄位——已查證官方文件《Header Data of a Smart Style》："You must define the following values in the header data: Standard Paragraph..."——沒填會在存檔時報錯「Header Data / Standard Paragraph is not filled」）
   - 其他欄位（Characters per Inch／Lines per Inch／Font）維持系統預設即可
8. 按工具列的 **Activate**（啟用）
9. 狀態列應顯示「Style ZSTY_01_HELLO was activated」之類的成功訊息

### 步驟二：開啟 SMARTFORMS 並建立新表單

1. 執行交易碼 `SMARTFORMS`
2. 在「Form」欄位輸入 `ZSF_01_HELLO`
3. 點擊工具列的 **Create**（建立，🔨圖示或按 `F5`）
4. 彈出的「Create Form」對話框：
   - **Description**：填 `SF01 - Hello World 練習表單`
   - 按 **Enter** 確認
5. 若跳出「Create Object Directory Entry」對話框，選擇套件 `$TMP`（本地物件，不需要傳輸請求）——如果團隊慣例是用 Z 套件而非 `$TMP`，改成對應的 Z 套件並選傳輸請求

### 步驟三：設定 Form Attributes（General Attributes／Output Options 兩個分頁）

建立後系統會直接進入表單維護畫面，左側樹狀結構最上層是 **Global Settings**，底下第一個節點是 **Form Attributes**：

#### General Attributes 分頁

1. 點選左側樹的 **Form Attributes** 節點（右側會自動開啟這個節點的分頁畫面）
2. 確認在 **General Attributes** 分頁，**Description** 是 `SF01 - Hello World 練習表單`（跟建立時填的一致）

#### Output Options 分頁

⚠️ 這個分頁同時裝了 Page Format／字元密度／行距／Style／列印輸出設定，全部擠在一起，不是分開的獨立分頁：

1. 切到 **Output Options** 分頁
2. **Page Format**：下拉選 `DINA4`
3. **Style**：輸入 `ZSTY_01_HELLO`（步驟一已經建好、啟用的既有 Style，這裡是**引用**，不會自動建立——如果看到紅字錯誤「does not exist」，代表步驟一的 Style 還沒建好或還沒啟用，回頭確認）
4. **Application**：維持系統帶出的預設值即可（通常是 `SAPscript`），不用改
5. 其他欄位保持預設

設定完按 `Ctrl+S`（Save）存檔一次。

### 步驟四：在 MAIN Window 加入 Text 元素

1. 左側樹狀結構往下展開：**Pages and Windows** → **FIRST**（第一頁）→ **MAIN**（系統預設就有這個主視窗，是專門給流動內容用的）
2. **在 MAIN 上按右鍵** → **Create** → **Text**
3. 彈出對話框：
   - **Text name**：可以隨意取一個識別名稱，例如 `HELLO_TEXT`
   - 按 **Enter**
4. `General Attributes` 分頁下方會有一大塊**空白**的文字編輯區——這是官方文件《Entering Texts in the PC Editor》說的 **PC Editor inline（嵌入式）版本**，本來就不會有任何提示文字或輸入框線，直接點進去就能打字
5. 把游標點進那塊空白區域，直接打字輸入：`Hello Smartform!`
6. 按 `Ctrl+S` 存檔，回到表單維護主畫面（或按綠色返回箭頭 `F3`）

### 步驟五：檢查與啟用

1. 按工具列的 **Check**（檢查，✓圖示，或 `Ctrl+F3`）——如果有錯誤訊息，畫面下方會顯示，處理後再檢查一次
2. 檢查通過後，按 **Activate**（啟用，🔶圖示；也可以走選單 **Smart Forms → Activate**）
3. 狀態列應顯示「Form ZSF_01_HELLO was activated」之類的成功訊息（如果步驟一的 Smart Style 還沒啟用，這一步可能會報錯，回頭確認 Style 已經 Activate 過）

### 步驟六：驗證

#### 方式 A（在 SMARTFORMS 直接測試）

- 工具列有 **Test**（測試，🖨️圖示，或選單 **Smart Forms → Test → Print Preview**）
- 會跳出「Enter Selection Criteria for Output」畫面，直接按 Enter/Execute
- 應該會看到預覽畫面印出 `Hello Smartform!`

#### 方式 B（透過呼叫端程式 `ZR_SF01_DEMO`）

- 用 SE38 或 SA38 執行 `ZR_SF01_DEMO`
- 螢幕會依序印出：查到的動態 Function Module 名稱（類似 `/1BCDWB/SF00000xxx`）、`SSF_FUNCTION_MODULE_NAME sy-subrc: 0`、呼叫後的 `sy-subrc`
- 因為程式裡設了 `no_dialog = abap_true`／`preview = abap_false`，這次執行**不會跳出預覽畫面**，只會印出文字結果告訴你呼叫成功或失敗——這正好呼應思考題 1 提到的「背景/無人值守執行」情境，也是驗證 Lecture 提到的「`programrun` 能不能無頭跑過 Smartform」這個假設的第一步（先在 SAP GUI 手動執行確認邏輯正確，之後才有意義再測 `programrun`）

## 思考題

1. Lecture 提到 `control_parameters-no_dialog = abap_true` 理論上可以讓呼叫變成無人值守。如果要在背景工作（Background Job，`SM36`）排程每天自動印一批單據，除了 `no_dialog` 之外，`output_options` 還需要設定什麼（提示：想想背景執行時沒有螢幕，列印結果要導去哪裡）？
2. `SSF_FUNCTION_MODULE_NAME` 用 `EXCEPTIONS no_form = 1` 這種傳統 `EXCEPTIONS`，不是 BAPI 那種 `RETURN TYPE bapiret2` 結構化錯誤（if01 學過的兩種錯誤回報方式）。這個設計選擇合理嗎？為什麼 Smartform 框架的這支查詢 FM 不需要 BAPI 等級的相容承諾？
3. 如果同一個 Smartform 被啟用兩次（例如你先啟用一版簡單版，之後又改版重新啟用），兩次查到的 `lv_fm_name` 會是同一個名稱嗎？這對「把 Function Module 名稱寫死在程式裡」這種做法（繞過 `SSF_FUNCTION_MODULE_NAME`）意味著什麼風險？

## 答案

`ZR_SF01_DEMO` 快照見 `zr_sf01_demo.prog.abap`（已建立、語法檢查通過）。`ZSF_01_HELLO`（表單本體）與 `ZSTY_01_HELLO`（Smart Style，SAP 規定每張表單必須指派、缺這個會過不了啟用）都因為沒有 ADT API（見 `.claude/rules/sap-adt-mcp.md` 第 19 節），需要你分別在 `SMARTFORMS`／`SMARTSTYLES`（**不是** `SE71`／`SE72`——見 Lecture 的更正說明）手動建立——完成後請回報結果，或直接執行 `ZR_SF01_DEMO` 觀察 `lv_fm_name`／`sy-subrc`／預覽畫面，Claude 這邊沒辦法讀到 `SMARTFORMS`／`SMARTSTYLES` 畫面內容，只能靠程式執行結果或你的口頭回報間接確認表單與 Style 是否都建對。
