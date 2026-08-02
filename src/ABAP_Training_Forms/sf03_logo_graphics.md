# 表單設計練習 3：Logo 置入（SE78 圖形管理）

## Lecture

sf01～sf02 已經會建表單、建 Smart Style、精確定位 Window、放 Text 跟 Template。這題補上正式單據最後一塊常見的視覺元素：**公司 Logo**。跟 sf01/sf02 一路踩雷後才確認交易碼與物件結構不同，這題先把整個流程一次查證清楚（`mcp__sap-docs__search` 查官方文件《Printing Graphics》）：

**流程分兩段，兩個完全不同的交易碼**：

1. **`SE78`（Administration of Form Graphics）**：先把圖檔**匯入系統**——導覽樹選 `Store on Document → GRAPHICS → General graphics`，選對圖檔格式雙擊，選單 `Graphic → Import`，系統會把圖檔存進 **BDS（Business Document Server）**。這一步只是「把圖檔搬進系統」，還沒放到任何表單上。
2. **回到 `SMARTFORMS` 的 Form Builder，建立 Graphic 節點**：在 Page 節點（或 Window 節點）底下 Create → Graphic，`General Attributes` 分頁指定要用彩色還是黑白，`Object`／`ID`／`Name` 三個欄位用來指出「要用哪張圖」——官方文件的建議做法是：**在 Name 欄位按 F4 查找剛剛匯入的圖，選了之後系統會自動把 Object／ID／Name 三個欄位一起帶出來**，不用自己記代碼。

**Graphic 節點的幾個關鍵限制**（都已查證自《Printing Graphics》，不是猜的）：

- **建在 Page 節點底下 vs 建在 Window 底下，行為不一樣**：直接掛在 Page 節點下（或用 Form Painter 直接拖），Form Builder 畫面**當場就看得到**圖；掛在 Window 底下的 Graphic，要等**表單真正執行時**才會被畫進去，Form Builder 設計畫面看不到圖本身，只看到一個帶著節點名稱的空框
- **掛在 Window 底下的 Graphic，多一組「Horizontal Position」設定**（`Reference Point`／`Alignment` 決定水平位置），但**垂直位置是由該 Window 裡「前一個輸出內容」的位置決定的**——這代表 Graphic 節點在 Window 裡的順序（它排在哪個節點後面）會直接影響它印在哪裡，不是自由座標定位
- **⚠️ 圖形目前不能跟文字重疊顯示**，但官方文件給了一個具體的替代方案：**「如果用 Template 節點，可以讓圖形與文字並排顯示」**——這正是這題「Logo + 公司名稱並排」這種常見版面需求的標準做法：Template 一列多欄，一欄放 Graphic 節點、另一欄放 Text 節點
- **解析度設定在 `Technical Attributes` 區塊**：解析度設低，圖在表單上顯示得比較大；解析度設高，圖顯示得比較小——這跟直覺可能相反，容易踩的雷是「圖模糊或位置跑掉」，十之八九是解析度或量測單位換算搞錯，不是圖檔本身壞掉
- 如果印表機支援、且在 `SE78` 有勾選對應設定，SAP Smart Forms 可以讓印表機把圖形**快取在印表機記憶體**、整個列印工作只傳一次圖檔，這是效能考量，這題不深入，只需要知道有這個機制

**背景圖**（跟這題無關但值得知道）：如果要放「掃描過的既有紙本表單當底圖」這種整頁背景圖，不是用 Graphic 節點，是用 **Page 節點自己的 Background Graphic 分頁**，這是另一條路徑，這題不會用到。

## 學習目標

- 能講出匯入圖檔（`SE78`）跟在表單裡放圖形節點（`SMARTFORMS`）是兩個獨立步驟、兩個獨立交易碼
- 能用 F4 查找的方式把已匯入的圖檔掛到 Graphic 節點，不用手動記 Object／ID／Name
- 知道 Graphic 節點放在 Page 底下跟放在 Window 底下的顯示時機差異
- 能用 Template 節點做出「圖形與文字並排」的版面（因為 Graphic 不能直接跟文字疊在一起）
- 知道 Smart Style 是可以跨表單重複指派的共用資源，不用每題都重建一個

## 事前準備

- 沿用 sf02 已建立的 Smart Style `ZSTY_02_LAYOUT`——這題**不新建 Smart Style**，直接在新表單的 `Form Attributes → Output Options` 分頁（sf01 已更正過的位置）指派這個既有物件，順便體會「Smart Style 本來就是設計成可以跨表單共用」這件事
- 需要一張小圖檔（任意 BMP／GIF／JPEG 皆可，公司 Logo 或隨便一張小圖都行，這題重點是流程不是美術）

## 題目需求

1. **用 `SE78` 匯入一張圖檔**：`Store on Document → GRAPHICS → General graphics`，選對應格式，`Graphic → Import`，取一個好記的技術名稱（例如 `ZLOGO_SF03`）。

2. **建立新表單 `ZSF_03_LOGO`**，Global Settings 的 Style 指派為既有的 `ZSTY_02_LAYOUT`（不新建），Page Format 沿用 `DINA4`。

3. **新增一個 Secondary Window `HEADER`**（位置/大小可比照 sf02：Position X-Origin `2`cm／Y-Origin `2`cm，Size Width `17`cm／Height `2`cm）。

4. **在 `HEADER` 裡放一個 Template 節點，1 列 2 欄**（欄寬總和要等於 17cm，例如左欄 `3`cm、右欄 `14`cm）：
   - 左欄放 **Graphic 節點**，用 F4 查找剛剛匯入的 `ZLOGO_SF03`
   - 右欄放 **Text 節點**，套用段落格式 `P1`（沿用 sf02 建立的段落格式），內容 `ZSF_03_LOGO 練習 - 公司抬頭`

5. **MAIN Window** 放一個簡單的 Text 節點（段落格式 `P2`），內容 `這是 sf03 的 Logo 置入練習表單`，不用像 sf02 那麼複雜。

6. **啟用**整組物件（`ZSF_03_LOGO`；`ZSTY_02_LAYOUT` 已經是啟用狀態，不用重新啟用）。

7. **呼叫端程式**：Claude 建立 `ZR_SF03_DEMO`，沿用前兩題的骨架，`formname = 'ZSF_03_LOGO'`。

8. **驗證**：用 Print Preview 或執行 `ZR_SF03_DEMO`，確認 Logo 跟公司名稱文字**並排顯示、沒有重疊**，且 Logo 大小合理（不會整頁滿版也不會小到看不見——如果太大/太小，回頭檢查 `Technical Attributes` 的解析度設定）。

## 思考題

1. 如果把 Graphic 節點直接放在 Page 節點底下（不透過 Template 跟文字並排），會發生什麼事？這樣做能不能達到「Logo 在左、文字在右」的效果？（提示：想想 Page 節點底下的 Graphic 是怎麼定位的，跟 Window 裡的定位方式一樣嗎）
2. 這題把 Graphic 節點放進 Window 裡（而不是 Page 底下），所以 Form Builder 設計畫面看不到圖，只能看到一個空框。這對你調整版面（例如確認 Logo 有沒有跟文字對齊）造成什麼實際困擾？你會怎麼因應（提示：想想除了 Form Builder 設計畫面，還有哪個功能可以看到實際輸出）？
3. `ZSTY_02_LAYOUT` 這次被 `ZSF_03_LOGO` 拿來重複使用。如果之後你把 `ZSTY_02_LAYOUT` 的 `P1` 段落格式改了（例如字體從黑體改成別的），會同時影響 `ZSF_02_LAYOUT` 跟 `ZSF_03_LOGO` 兩張表單的顯示嗎？這對「多張表單共用一個 Smart Style」是好處還是風險？

## 答案

`ZR_SF03_DEMO` 快照見 `zr_sf03_demo.prog.abap`（已建立、語法檢查通過）。`ZSF_03_LOGO`（表單本體，含匯入的圖檔 `ZLOGO_SF03`）需要你在 `SE78`／`SMARTFORMS` 手動建立（原因見 sf01／`.claude/rules/sap-adt-mcp.md` 第 19 節）；`ZSTY_02_LAYOUT` 直接沿用 sf02 已建立的物件，不用重建。完成後請回報結果，或執行 `ZR_SF03_DEMO` 搭配 Print Preview 確認 Logo 與文字並排效果。
