# 練習 8a：Package 與傳輸請求——從建立到匯入

> 授課順序：接在練習 8（FORM）之後、練習 15（Function Module）之前。講義見 [lec08a](lectures/lec08a_package_transport.md)。

## 學習目標

- 會在 SE80 建立自己的 Package，並知道 Transport Layer 決定物件往哪裡送
- 會建立 Workbench Request，看懂 Request／Task 兩層結構
- 會依正確順序釋放：**先 Task、再 Request**
- 會在版本管理（Version Management）看到「每次釋放對應一個版本」
- 體驗「釋放後再修改，一定要掛新 TR」
- 會在 STMS 匯入佇列用 Filter 找到自己的 TR、執行單張匯入、確認匯入結果

## 事前準備

- 本系統只有一台（`S4H`），Transport Layer 是 `ZS4H`，匯入練習是匯入回 `S4H` 自己、Client `130`。
- 以下 `<縮寫>` 請換成自己的姓名縮寫；Package 名稱照講師指定（課堂實例：`ZMM1`、`ZMM2`）。

## 題目需求

**Part 1：建立 Package 與第一張 TR**

1. SE80 建立 Package `Z<指定名稱>`：Software Component `HOME`、Transport Layer `ZS4H`
2. 存檔時系統要求 TR → **Create Request**，Short Description 寫清楚（例如「ex08a 練習：<縮寫> 第一版」）
3. SE38 在這個 Package 建一支簡單程式 `ZR_TR08A_<縮寫>`（內容可以直接抄 ex08 的報表，或只寫幾行 `WRITE`），存檔時選**剛才那張 TR**，啟用並執行

**Part 2：看懂 TR 並釋放**

4. SE10 勾 **Modifiable** → **Display**，展開自己的 Request：
   - 記下 Request 號碼與 Task 號碼
   - 展開 Task，確認裡面有 Package（`R3TR DEVC`）與程式（`R3TR PROG`）
5. 先釋放 **Task**，再釋放 **Request**
6. 重新顯示時勾 **Released**，確認自己的 Request 出現在已釋放清單

**Part 3：版本**

7. SE38 開啟 `ZR_TR08A_<縮寫>` → **Utilities → Versions → Version Management**，找到剛才釋放產生的版本，確認它對應的 TR 號碼就是 Part 1 那張

**Part 4：釋放後再修改**

8. 在程式加一行 `WRITE` → 存檔：系統**再次**要求 TR（因為原本的已釋放）→ 建第二張 TR（說明寫「ex08a 練習：<縮寫> 第二版」）
9. SE10 展開第二張 TR 的 Task：這次程式記錄成 `LIMU REPS ZR_TR08A_<縮寫>`（只記錄原始碼），不是 `R3TR PROG`
10. 釋放第二張 TR（先 Task 再 Request），回到版本管理：現在有兩個版本，勾兩個版本按 **Compare**，看到新增的那一行

**Part 5：STMS 匯入**

11. STMS → **Import Overview** → 游標放在 `S4H` → **Display Import Queue**（或直接執行 `STMS_IMPORT`）。看不到剛釋放的 TR 時，按 **Refresh**
12. 游標放在 **Request** 欄標題 → **Set Filter** → 輸入自己的兩張 TR 號碼 → **Copy**，畫面只剩自己的 TR
13. 看 **St**（狀態）欄：兩張都應該是 **Request waiting to be imported**
14. 游標放在**第一張** TR → **Import Request**（**不要**按 Import All Requests） → Target Client `130` → Options 保持預設 → Continue → 確認
15. 按 **Refresh**：第一張變成 **Request already imported**、RC 是 `0`；再依同樣步驟匯入第二張（**依順序：先舊後新**）
16. 驗證：SE10 開啟第一張 TR → **Goto → Transport Logs**，看到 Export 與 Import 兩段記錄、回傳碼都是 0

## 預期結果

- SE10 已釋放清單有自己的兩張 TR，第一張內含 `R3TR DEVC`＋`R3TR PROG`，第二張內含 `LIMU REPS`
- 版本管理有兩個版本，分別對應兩張 TR，Compare 看得到新增的那一行
- STMS 佇列兩張 TR 都是 **Request already imported**、RC `0`
- SE10 Transport Logs 有 Export 與 Import 記錄

## 思考題

1. 如果 Part 1 把程式建在 `$TMP`，存檔時會被問 TR 嗎？這支程式有辦法傳到正式機嗎？要怎麼補救？（提示：Goto → Object Directory Entry）
2. Part 2 如果先按 Request 的 Release、Task 還沒釋放，會發生什麼事？為什麼 SAP 要這樣設計？
3. Part 4 為什麼第二張 TR 裡記錄的是 `LIMU REPS` 而不是 `R3TR PROG`？兩者差在哪？
4. 如果 Part 5 先匯入第二張、再匯入第一張，目標系統最後會是哪一版的程式？
5. 為什麼平常只用 **Import Request**、不按 **Import All Requests**？
6. 同學正在修改一支程式、TR 還沒釋放，這時你也去改同一支程式，系統會怎麼處理？
7. 剛釋放完馬上進 STMS，佇列裡找不到自己的 TR，第一步該做什麼？

## 答案

本題沒有答案程式，以「預期結果」四項自我檢查。課堂實例可對照：`ZMM1`（`S4HK901984`→`S4HK901990`）、`ZMM2`（`S4HK901986`→`S4HK901988`），前兩張已於 2026-09-24 匯入 `S4H` Client `130`，回傳碼 `0000`。
