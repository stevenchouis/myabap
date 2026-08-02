# 表單設計練習 4：畫框線（Box and Shading／Line Type）

## Lecture

⚠️ 先更正一個規劃階段的用詞：`ABAP_Training_Forms/README.md` 課綱草案原本寫「Window 的 Frame（外框）屬性」，這次出題前用 `mcp__sap-docs__search` 查證官方文件才發現**沒有叫「Frame」的屬性**——正確名稱是 **Box and Shading（框線與網底）**，是幾乎所有輸出節點（Window、Text、Graphic、Table Line……）共用的一組屬性，在 `Output Options` 分頁裡（sf02 提過的「General Attributes／Output Options／Conditions 三個共用分頁」）。這題把「框線」拆成兩個層次來教：**單一節點的 Box and Shading**（給一整個 Window 或 Text 畫外框、上底色），跟 **Template／Table 的 Line Type 框線**（表格內部逐格畫線，細緻很多）。

**Box and Shading（單一節點畫框）**：

- **Box**：勾選要畫上/下/左/右哪幾條邊線，可以個別設定線的**間距（Spacing）、顏色、粗細**
- **Shading**：框內底色，顏色跟飽和度可調——⚠️黑白印表機會把「飽和度 100% 的任何顏色」都印成黑色，要印出灰階效果要自己調低飽和度，不是選淺灰色就會印出淺灰
- **不設 Spacing 時的預設規則**（官方文件《Box and Shading》原文查證）：**Window 本身、Address／Graphic 這種輸出區塊，框線會畫在 Window 邊界上，底色會鋪滿到邊界**；但如果是 **Window 底下的子節點**（例如 Window 裡的某個 Text），左右邊線跟底色會延伸到 Window 的左右邊界，但**上下間距則依節點類型而定**——Graphic 節點框線高度貼合圖形大小，Text／Address 節點的框線下緣貼著文字下方，上緣留稍微多一點空間
- **可以針對「不同頁」設定不同的框線細節**（Details 設定），例如某條邊線只在第一頁畫粗一點——這題不會用到，只需要知道有這個彈性

**Template／Table 的 Line Type（表格內部框線，細緻度更高）**：

- 官方文件《Describing the Table Layout》：Template 的版面配置決定「列數/欄數、每列高度、每欄寬度、表格在 Window 內的對齊方式、要不要畫分隔線或外框」——這些設定都在 **Table Painter**（Template 節點的圖形化編輯畫面）裡完成
- 每一列的框線設定叫一個 **Line Type**：可以用 **Pattern** 這個工具快速套「所有儲存格都有分隔線＋整個表格加外框」這種常見樣式，也可以逐格點選要不要畫線（官方文件《Setting Boxes》：**要針對個別儲存格設框線，得先關掉 Draw Mode**）
- **同一個 Line Type 可以被多列共用**（`Reference` 欄位指到另一列的 Line Type 名稱，系統會複製那一列的高度/欄寬設定），不用每一列都重新設定一次

**跨頁時框線會不會斷掉？——`No Break` 這個關鍵屬性**（官方文件《Processing Loops and Tables》查證，這題先建立觀念，實際跑迴圈輸出明細列留到 sf05）：

- Smart Forms 印 Table／Loop 明細列時，是**一列一列動態判斷**還放不放得下當頁，放不下就觸發自動換頁——這代表**同一個 Line Type 的表格列，內容有可能被硬生生從中間切斷，上半段印在這頁、下半段印到下一頁**
- 想要「這一列的內容無論如何都要印在同一頁，不要被切斷」，要在該 **Line Type 勾選 `No Break`**——官方文件原文：「You must specify No Break with the line type to prevent the system from breaking up the table at the end of the main window for space reasons」
- 這題示範的表格內容是靜態的（不會跑到需要換頁的程度），所以**看不到 `No Break` 實際發揮作用**，但這個屬性要先設定成習慣動作——sf05／sf06 會用到真正動態、可能跨頁的明細列，那時候「忘記勾 `No Break`」造成的框線斷裂會是常見的踩雷點

## 學習目標

- 能講出 Box and Shading 是共用於多種節點類型的屬性，不是 Window 專屬的「Frame」（更正課綱草案的用詞錯誤）
- 能幫一個 Window 畫外框、加底色，並知道「不設 Spacing」時系統套用的預設規則
- 能用 Table Painter 的 Pattern 功能幫 Template 的儲存格畫分隔線與外框
- 知道 `No Break` 這個 Line Type 屬性的用途，即使這題的靜態內容示範不出實際效果

## 事前準備

沿用 sf02 已建立的 Smart Style `ZSTY_02_LAYOUT`（跟 sf03 一樣直接指派既有物件，不新建）。

## 題目需求

1. **建立新表單 `ZSF_04_BORDERS`**，Style 指派既有的 `ZSTY_02_LAYOUT`，Page Format 沿用 `DINA4`。

2. **新增 Secondary Window `HEADER`**（Position/Size 比照 sf02：X `2`cm／Y `2`cm，Width `17`cm／Height `2`cm），在它的 `Output Options` 分頁設定 **Box and Shading**：
   - Box：四邊都勾選，顏色黑色、粗細自訂（例如 `0.5`pt）
   - Shading：淺灰色，飽和度調低（例如 `10%`，避免黑白印表機印成全黑）
   - 裡面放一個 Text 節點（段落格式 `P1`），內容 `ZSF_04_BORDERS 練習 - 框線與網底`

3. **在 MAIN Window 裡加一個 Template 節點，3 列 2 欄**，靜態內容自訂（例如一張簡單的檢查清單：`項目`／`狀態` 兩欄，三列填 `Logo 已置入`／`已完成`、`版面已對齊`／`已完成`、`框線已設定`／`待確認` 之類），用 **Table Painter 的 Pattern** 功能設定：
   - 所有儲存格之間畫分隔線
   - 整個 Template 外圍加外框
   - 這個 Line Type 勾選 **`No Break`**（即使這題內容不會觸發換頁，先養成設定的習慣）

4. **啟用**整組物件。

5. **呼叫端程式**：Claude 建立 `ZR_SF04_DEMO`，沿用前幾題骨架，`formname = 'ZSF_04_BORDERS'`。

6. **驗證**：Print Preview 或執行 `ZR_SF04_DEMO`，確認：
   - `HEADER` Window 有清楚的外框跟淺灰底色，文字沒有被底色蓋到看不清楚
   - Template 的 3×2 格線整齊、外框完整

## 思考題

1. 如果把 `HEADER` Window 的 Box Spacing 都設成 `0`（沿用官方文件說的預設規則），框線會畫在哪裡？如果你想讓框線比 Window 邊界**往內縮 0.3cm**（框線跟視窗邊緣之間留一點呼吸空間），要怎麼調整？
2. 官方文件提到 Box and Shading 的間距設定「依節點類型而定」——Graphic 節點的框線高度貼合圖形大小，Text 節點的下緣貼著文字、上緣留較多空間。如果你在同一個 Template 儲存格裡同時有 Text 跟 Graphic 兩個節點（sf03 教過的並排寫法），猜猜看框線通常會怎麼計算？（提示：這題不要求查到標準答案，重點是意識到「框線範圍不是憑空決定的，是跟著節點類型的內容範圍算出來的」）
3. `No Break` 解決的是「同一列的內容被切斷」，但 README 的課綱草案還提過另一個問題：**「MAIN window 分頁時框線斷裂的處理」**——想想看，如果一個 Template／Table 本身很長、確實需要跨好幾頁才印得完（不是靠 `No Break` 能解決的情況，因為那是整張表都放不下，不是單一列被切斷），這時候你會怎麼處理「每一頁都要看到欄位標題」這個常見需求？（提示：sf05 會教的 Table 節點有自動產生的 Header／Main Area／Footer 三個子節點，這個機制正是為了解決這個問題設計的，這題先預告，不用寫出完整答案）

## 答案

`ZR_SF04_DEMO` 快照見 `zr_sf04_demo.prog.abap`（已建立、語法檢查通過）。`ZSF_04_BORDERS` 表單本體需要你在 `SMARTFORMS` 手動建立（原因見 sf01／`.claude/rules/sap-adt-mcp.md` 第 19 節），`ZSTY_02_LAYOUT` 沿用既有物件不用重建。完成後請回報結果，或執行 `ZR_SF04_DEMO` 搭配 Print Preview 確認框線與網底效果。
