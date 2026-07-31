# 練習 28：客製 Table Maintenance 的權限防護與並行控制

> 授課順序：接在練習 27（Lock Object）之後。講義見 [lec28](lectures/lec28_auth_wrapper.md)。

## 學習目標

- 理解 SM30 原生權限檢查（`S_TABU_DIS`/`S_TABU_NAM`）只到表格層級，業務維度要自己包 Wrapper
- 會在 SU21 建立自訂**權限物件**（`ACTVT`＋業務欄位），並知道 `AUTHORITY-CHECK` 怎麼呼叫
- 理解 Lock Object 的鎖定範圍**不必等於表格主鍵**，要對應「使用者實際爭搶的資源邊界」
- 會用 `VIEW_MAINTENANCE_CALL` 從程式呼叫標準 Table Maintenance，並用 `dba_sellist` 依欄位篩選只顯示授權範圍內的資料
- 理解「T-code 要指給 Wrapper 程式，不能指給裸的 SM30」這個設計為什麼重要
- 會用 `SELECTION-SCREEN FUNCTION KEY` 在選取畫面加自訂按鈕，並理解「透過 Parameter Transaction 呼叫 SM30」跟「透過 Wrapper 正規呼叫」在保護程度上的差別
- **理解這種 Auth Wrapper／Lock Object 主檔不是憑空存在的抽象練習，而是真的會被別的報表拿去做業務計算**——本題把主檔設計成「航空公司折扣」，另外寫一支計算報表實際套用這個折扣算出最終票價，體會「維護的參數值會影響下游計算結果」這件事

## 事前準備

物件建在套件 `$TMP`。沿用練習 21 學過的 Z 表＋外鍵技巧，這次外鍵指向**標準表** `SCARR`（航空公司主檔），並沿用課程從頭到尾都在用的示範資料模型（`SCARR`/`SPFLI`/`SFLIGHT`）——這是本題跟先前版本最大的差異：先前用「工廠(WERKS)＋通用參數」設計，比較抽象；這一版改成「航空公司(CARRID)＋折扣百分比」，並且真的接了一支計算報表去使用這個折扣，貼近實務常見的「主檔維護 → 下游計算」場景。

> ⚠️ **2026-07-31 重大改版說明**：本題原本是「工廠(WERKS) + 通用參數(PARAM/PARVAL)」設計（`ZTR28_WPARM`／`ZTR28_WERK`／`EZTR28_WERKS`），使用者測試過 Lock 與篩選都正常後，覺得「參數維護完全沒有接到任何計算，教學意義有限」，因此決定整個改版成「航空公司折扣」設計。**這是整份講義的最終版本**，物件名稱、程式邏輯、GUI-only 步驟都已經是新設計；舊物件（`ZTR28_WPARM`／`ZTR28_WERK`／`EZTR28_WERKS`）留在系統裡當作 `$TMP` 殘留物，不影響新設計運作，也不需要特別清除。

## 第一部分：DDIC（已由 Claude 建立並啟用，可直接對照）

1. Domain/DE `ZTR28_DISCPCT`（DEC 6,2，折扣百分比，值域 0~100，語法沿用練習 25「DEC Domain 值域上下限要用整數」的教訓）——`CARRID` 直接重用標準 DE `S_CARR_ID`（CHAR 3，`SCARR`/`SPFLI`/`SFLIGHT` 都用這個），`DISCTXT`（折扣說明）重用標準 DE `TEXT40`，不用另外自建（呼應練習 25「能重用標準就不要自己蓋」的判斷）
2. 表 `ZTR28_CDISC`（Carrier Discount）：

| 欄位 | Key | 型別來源 | 說明 |
|---|---|---|---|
| MANDT | ✔ | Data Element `MANDT` | client |
| CARRID | ✔ | Data Element `S_CARR_ID`，外鍵指向標準表 `SCARR` | 航空公司代碼 |
| DISCOUNT_PCT | | Data Element `ZTR28_DISCPCT` | 折扣百分比 |
| DISCTXT | | 標準 Data Element `TEXT40` | 折扣說明 |
| UPDUSER | | Data Element `SYUNAME` | 異動者 |
| UPDDATE | | Data Element `SYDATUM` | 異動日 |

外鍵 `CARRID` 的 Check Table 是**標準表 `SCARR`**（不是自建表），Cardinality `[0..*,1]`，`screenCheck : true`。

## 第二部分：SU21 建立自訂權限物件（需使用者手動建立，ADT 沒有建立 API）

1. **SU21** → Object Class 選 **`BC_A`**（Basis: Administration；⚠️ `BC` 本身不是合法的 Class 代碼，只是分類字首，實際要選 `BC_A`/`BC_C`/`BC_Z` 這種細分類，存檔時如果選了不存在的 Class 會報紅字錯誤「Object class ... does not exist」）→ Create Authorization Object
2. 物件名稱 `ZTR28_CARR`（10 碼，剛好符合**權限物件名稱上限 10 碼**），Short Text 自訂（如「TR28 Carrier Discount Authorization」）
3. Authorization Fields：`ACTVT`（標準欄位）、`CARRID`（本題業務欄位，型別參考 Data Element `S_CARR_ID`）
4. 存檔、Activate（存檔時如果看到黃色警告「Permissible activities not maintained for field ACTVT」可以忽略，不影響後續使用）
5. **這一步只是定義「有哪些欄位可以管控」，真正要讓某個使用者擁有權限，還要走完下面的 PFCG 流程**——缺這一步的話，任何人 `AUTHORITY-CHECK` 都會失敗（`sy-subrc <> 0`），程式邏輯本身不受影響

> ⚠️ **`ZTR28_CARR`（權限物件，無 `S`）跟 `EZTR28_CARR`（Lock Object，有 `S`、`E` 開頭）拼法相近但不同，操作時注意看清楚。**（舊版的 `ZTR28_WERK` 已被取代，可留著當 `$TMP` 殘留物不用管）

## 第二點五部分：PFCG 角色維護（需使用者手動建立，權限真正生效的關鍵，詳細操作見講義第 3.1 節）

角色名稱**沿用**既有的 `ZTR28_MAINT_ROLE`（不用重新建立角色本身），只是把授權內容改指新的權限物件：

1. **PFCG** → Role 欄位輸入 `ZTR28_MAINT_ROLE` → Change
2. Authorizations 頁籤 → 鉛筆圖示 Change Authorization Data
3. 找到舊的 `ZTR28_WERK` 節點，可以直接刪除（不刪也無妨，只是留著沒作用）
4. **Manually** 按鈕輸入 `ZTR28_CARR` → Enter
5. 展開 `ZTR28_CARR` 節點：`ACTVT` 填 `02`、`CARRID` 填 `LH`（呼應程式的 `p_carrid` 預設值）；確認 `S_TCODE` 底下的 `TCD` 仍有 `ZTR28_MAINT`（T-code 名稱沒變，不用重填）
6. 齒輪圖示 **Generate** 產生 Profile
7. User 頁籤輸入自己的使用者代號 → **User Comparison** → Complete Comparison
8. 存檔
9. 登出重新登入（或開新 Session）驗證：SU53 可查上一次權限失敗的細節

## 第三部分：SE11 建立 Lock Object（需使用者手動建立）

1. SE11 → Lock Object → `EZTR28_CARR`（**系統強制要求 `E` 開頭，不是命名慣例**；⚠️ 注意別跟第二部分的權限物件 `ZTR28_CARR` 搞混，兩者拼法相近但不同）→ Create
2. Primary Table：`ZTR28_CDISC`
3. Lock Parameters：**勾 `MANDT`、`CARRID`**——鎖定範圍是「整家航空公司的折扣設定」
4. Lock Mode：`E`
5. 存檔、Activate——系統會產生 `ENQUEUE_EZTR28_CARR`／`DEQUEUE_EZTR28_CARR`（舊版的 `EZTR28_WERKS` 已被取代，可留著當 `$TMP` 殘留物不用管）

## 第四部分：SM30 Table Maintenance Generator（需使用者手動建立，同練習 21 手法）

1. SE11 → 表 `ZTR28_CDISC` → Utilities → Table Maintenance Generator
2. Authorization Group `&NC&`；Function Group 填 `ZFG_TR28B`（**新的 Function Group，不要跟舊表 `ZTR28_WPARM` 共用的 `ZFG_TR28`**）；Maintenance type 選 **One Step**
3. 產生後可以直接用 SM30 手動測試維護畫面本身（先不管權限/鎖定 Wrapper，純粹確認 View 本身能動）

## 第五部分：SE93 T-code（沿用既有 `ZTR28_MAINT`，不用重建）

`ZTR28_MAINT` 指向 Wrapper 程式 `ZR_TR28_PARAM_MAINT`（程式名稱沒有改），這一步**完全不用動**，之前建好的 T-code 繼續有效。

## 第五點五部分：SE93 修改 Parameter Transaction（給對照按鈕用，只需編輯既有的 `ZTR28_SM30`）

`ZR_TR28_PRICE_CALC` 選取畫面的「維護主檔(SM30)」按鈕呼叫的 `ZTR28_SM30`（SE93 建立的 Parameter Transaction）已經存在，**只需要把 Default Values 的 View 名稱從舊表改成新表**：

1. SE93 → T-code `ZTR28_SM30` → Change
2. 下方 **Default Values**（欄位標題「Name of screen field」／「Value」）表格：把 `VIEWNAME` 那一列的 Value 從 `ZTR28_WPARM` 改成 `ZTR28_CDISC`
3. `UPDATE` = `X` 那一列不用動
4. 存檔

`UPDATE = X` 讓畫面直接進入維護（更新）模式，不是唯讀顯示——呼應這顆按鈕本來就是「完全沒有保護、可以直接改資料」的對照組設計。

## 第六部分：程式（已由 Claude 建立並啟用，見下方原始碼）

> 本題的 GUI-only 手動步驟共**六項**（SU21／PFCG／SE11 Lock Object／SM30 Table Maintenance Generator／SE93 T-code `ZTR28_MAINT`〔沿用不用改〕／SE93 Parameter Transaction `ZTR28_SM30`〔只需修改 Default Values〕），另外還有下一節的 Selection Texts。

> ⚠️ **2026-07-31 再簡化：拿掉 `ZR_TR28_PARAM_LIST`**——這支「清單＋沒有保護的對照按鈕」程式，功能跟 `ZR_TR28_PRICE_CALC` 的按鈕完全重複（兩者都是「直接呼叫 `ZTR28_SM30` 跳進 SM30、不經過 Wrapper」），教學上不需要兩支程式各示範一次同一件事。本題最終只留兩支主程式：**`ZR_TR28_PARAM_MAINT`（維護入口）**與**`ZR_TR28_PRICE_CALC`（主要報表，選取畫面按鈕可直接跳去維護）**。`ZR_TR28_PARAM_LIST` 物件本身因為 ADT 沒有刪除 API 而留在系統裡，原始碼已改成說明性 stub（`WRITE` 一行棄用訊息），不算課程正式教材。

- **`ZR_TR28_PARAM_MAINT`**（Wrapper，走完整保護流程）：選取畫面 `p_carrid`（航空公司，預設 `LH`）＋ `p_disp`（勾選＝只顯示）。依序：`AUTHORITY-CHECK OBJECT 'ZTR28_CARR'` → （維護模式才）`ENQUEUE_EZTR28_CARR` → `VIEW_MAINTENANCE_CALL`（帶 `dba_sellist` 篩選 `CARRID = p_carrid`，只顯示這家航空公司）→ （維護模式才）`DEQUEUE_EZTR28_CARR`
- **`ZR_TR28_PRICE_CALC`**（主要報表：實際套用折扣的計算報表，展示「這個主檔真的會被拿去算錢」，**輸出用 ALV，選取畫面加了「維護主檔(SM30)」按鈕**）：輸入 `p_carrid`（航空公司，預設 `LH`）＋ `p_connid`（航班代碼，預設 `0400`），依序：`SELECT SINGLE` 查 `SPFLI` 確認航線存在（拿到起訖城市）→ `SELECT` 撈 `SFLIGHT` 該航線所有航班（票價、幣別）→ `SELECT SINGLE` 查 `ZTR28_CDISC` 拿這家航空公司的折扣（**查不到就當 0%，不擋報表執行**）→ 逐航班算 `final_price = price * (1 - discount_pct/100)`，用 `REUSE_ALV_GRID_DISPLAY` 顯示（9 欄：航空公司/航班代碼/起訖城市/日期/原價/幣別/折扣/最終票價）。選取畫面用 `SELECTION-SCREEN FUNCTION KEY 1` 加按鈕呼叫 `ZTR28_SM30`（不經過 Wrapper，直接跳進 SM30 維護畫面，沒有權限檢查、沒有 Lock、也沒有航空公司篩選），方便改完折扣馬上回來重跑本報表驗證連動——這顆按鈕本身就是跟 `ZR_TR28_PARAM_MAINT` 正規做法的對照，不需要另外一支清單程式重複示範。這支報表**完全不需要走權限/鎖定 Wrapper**（只是讀取，不是維護）。
- **`ZR_TR28_SEED_DEMO`**（一次性種子程式，方便測試）：`MODIFY` 兩筆示範資料進 `ZTR28_CDISC`（`LH` 15%、`AA` 10%），讓 `ZR_TR28_PRICE_CALC` 一開始執行就有非 0% 的資料可以測試，不用等 GUI-only 物件都建好、手動在 SM30 輸入才看得到效果。可以重複執行（`MODIFY` 不是 `INSERT`，不會因為 Key 重複而報錯）。

## 第六點五部分：Selection Texts（需使用者手動維護，無 ADT API）

`ZR_TR28_PARAM_MAINT`／`ZR_TR28_PRICE_CALC` 選取畫面目前顯示的是技術欄位名稱（`P_CARRID`、`P_CONNID`、`P_DISP`），不是中文說明——這是因為 **Selection Texts 跟本檔前面提過的 Text Symbols 一樣，沒有 ADT REST API**（`sap_get_source`/`sap_set_source` 的 objectType enum 沒有這個選項），只能在 SAP GUI 手動維護：

1. SE38 開啟該程式 → **Goto → Text Elements**（或工具列捷徑）
2. 切到 **Selection Texts** 頁籤
3. 逐一填入對應說明文字：

| 程式 | 欄位 | 建議 Selection Text |
|---|---|---|
| `ZR_TR28_PARAM_MAINT` | `P_CARRID` | 航空公司 |
| `ZR_TR28_PARAM_MAINT` | `P_DISP` | 只顯示(不維護) |
| `ZR_TR28_PRICE_CALC` | `P_CARRID` | 航空公司 |
| `ZR_TR28_PRICE_CALC` | `P_CONNID` | 航班代碼 |

（填完表格後）存檔、Activate（跟一般程式一樣，Local Object 不用建傳輸單）

補上之後，選取畫面欄位標籤會變成中文說明，不影響任何程式邏輯，純粹是操作體驗上的改善。

## 測試流程

**未建齊 GUI-only 物件時**（`programrun` 無頭驗證，已由 Claude 執行過）：

```
ZR_TR28_PARAM_MAINT（p_carrid=LH）→ 權限不足：無法對航空公司 LH 執行 維護（sy-subrc = 12，PFCG 沒做之前一律會是 12）
ZR_TR28_PRICE_CALC（p_carrid=LH, p_connid=0400，種子資料尚未寫入時）→ 折扣以 0% 計算，final_price = price；種子資料寫入後（LH 15%）→ 666.00 → 566.10、680.00 → 578.00，驗證乘法公式正確，ALV 版面正確（REUSE_ALV_GRID_DISPLAY 在無頭環境會退化成文字清單，意外地可以直接驗證）
```

⚠️ **`ZR_TR28_PARAM_MAINT`／`ZR_TR28_PRICE_CALC` 兩支程式後來在排錯過程中都遇過 `programrun` 卡住斷線（`RFC_CLOSED`）的情況**——已確認跟程式碼無關（另建全新測試物件驗證同樣邏輯可正常執行），是 ADT 端「這個特定物件的無頭執行 Session 被卡住」的已知限制（詳見 `.claude/rules/sap-adt-mcp.md` 第 38 節），並非程式有 bug。之後的端對端驗證一律以 SAP GUI 實際操作為準，不要再用 `programrun` 卡住當作程式有問題的證據。

**六項 GUI-only 作業（含 PFCG 指派 `ZTR28_CARR` 角色 `ACTVT=02`、`CARRID=LH`）都做好之後**：

1. 直接執行 `ZR_TR28_PARAM_MAINT`（`p_carrid=LH`，不勾顯示）：應該看到「權限檢查通過」→「鎖定成功」→ 跳出 SM30 風格的維護畫面，**且只看得到 `CARRID=LH` 這一家航空公司的資料列**（`dba_sellist` 篩選生效）→ 離開畫面後印出「已解鎖航空公司」
2. 開兩個 Session，都對 `LH` 執行維護：第二個應該在 `ENQUEUE` 那一步被擋下（`FOREIGN_LOCK`）
3. `p_disp` 打勾（顯示模式）：應該能看、但維護畫面裡的變更功能被關閉，且完全不會呼叫 `ENQUEUE`（顯示不用搶鎖）
4. 執行 T-code `ZTR28_MAINT`：應該直接進到跟上面一樣的選取畫面
5. 執行 `ZR_TR28_PRICE_CALC`，選取畫面上按「維護主檔(SM30)」按鈕（觸發 `CALL TRANSACTION 'ZTR28_SM30'`）：應該直接跳進 `ZTR28_CDISC` 的 SM30 維護畫面，**這次看得到所有航空公司的資料**（沒有篩選），也不會有任何權限檢查訊息——跟第 1 步的行為對比，具體感受「有沒有包 Wrapper」的差別
6. 在 `ZR_TR28_PARAM_MAINT` 把 `LH` 的折扣改成別的數字（例如 20%），存檔離開後執行 `ZR_TR28_PRICE_CALC`（`p_carrid=LH`），確認 `final_price` 真的跟著變動——這一步是本題最重要的體驗：**維護畫面改的值，下一秒就會反映在計算報表的結果上**

## 思考題

1. 如果把 `ACTVT` 拿掉，權限物件只剩 `CARRID` 一個欄位，會失去什麼控管能力？（提示：想想「能看但不能改」這種需求還做不做得到）
2. 為什麼 Wrapper 程式的 `AUTHORITY-CHECK` 跟 `VIEW_MAINTENANCE_CALL` 內部自己的權限檢查不衝突、也不是多餘的？兩者各自把關什麼？
3. 如果 Lock Object 的 Lock Parameters 只勾 `MANDT`（不勾 `CARRID`），會有什麼實際後果？兩個人分別維護不同航空公司的折扣時，行為會有什麼不同？
4. `p_disp`（顯示模式）完全不呼叫 `ENQUEUE`／`DEQUEUE`，這樣設計合理嗎？如果兩個人都用顯示模式同時打開同一家航空公司，會有問題嗎？
5. 如果某個使用者的角色同時擁有 `S_TABU_DIS`（對 `&NC&` Authorization Group 有維護權限）跟這支 T-code，但**沒有**被指派 `ZTR28_CARR` 這個自訂權限物件，這個使用者能不能繞過 Wrapper、直接用 SM30 改到 `ZTR28_CDISC` 的資料？這代表整個防護設計還缺了哪一塊角色/權限管理上的配套？
6. `ZR_TR28_PRICE_CALC` 完全沒有做 `AUTHORITY-CHECK`，任何人都能查詢任何航空公司的折扣與計算結果——這樣的設計合理嗎？如果公司規定「折扣是商業機密，只有維護者本人能查詢」，這支計算報表該怎麼改？

## 答案

見 `zr_tr28_param_maint.prog.abap`、`zr_tr28_price_calc.prog.abap`、`zr_tr28_seed_demo.prog.abap`（SAP 端 `ZR_TR28_PARAM_MAINT`／`ZR_TR28_PRICE_CALC`／`ZR_TR28_SEED_DEMO`）。DDIC 表 `ZTR28_CDISC` 快照見 `ztr28_cdisc.tabl.abap`。權限物件 `ZTR28_CARR`、PFCG 角色 `ZTR28_MAINT_ROLE`、Lock Object `EZTR28_CARR`、T-code `ZTR28_MAINT`／`ZTR28_SM30` 均為 GUI-only（SU21／PFCG／SE11／SE93 皆無 ADT 建立 API），無程式碼快照，需照上方步驟手動建立／修改；兩支主程式的 Selection Texts 也是 GUI-only（見上一節），需使用者在 SE38 手動補齊。`zr_tr28_param_list.prog.abap`（`ZR_TR28_PARAM_LIST`）已棄用，物件因 ADT 無刪除 API 而保留、原始碼已改成說明性 stub，不算課程正式教材。

**已用 `programrun` 驗證的部分**：兩支主程式皆已建立、啟用、無語法錯誤；`ZR_TR28_PARAM_MAINT` 在權限物件尚未建立、以及物件已建立但 PFCG 尚未指派兩種情境下，都正確回報「權限不足（sy-subrc=12）」，證實 Wrapper 的檢查順序與邏輯正確；`ZR_TR28_SEED_DEMO` 執行後 `ZR_TR28_PRICE_CALC`（折扣計算＋ALV）正確反映資料與乘法結果（`666.00 × 0.85 = 566.10`、`680.00 × 0.85 = 578.00`）。**意外發現：`REUSE_ALV_GRID_DISPLAY`（Functional ALV）在 `programrun` 無頭環境下通常會自動退化成文字清單輸出，可以直接驗證欄位/資料正確性，不像 OOP 課程教的 `cl_salv_table` 會整個卡住等畫面**（原本只是為了跟講義 9 的教學進度一致，沒想到還多了「可以無頭驗證」的優點）。**但這個「可無頭驗證」的優點不是絕對可靠**：`ZR_TR28_PARAM_MAINT`／`ZR_TR28_PRICE_CALC` 兩支程式後來都遇過 `programrun` 卡住斷線，排查後確認是「這個特定物件的無頭執行 Session 被卡住」（可能因為程式真的走到 `VIEW_MAINTENANCE_CALL` 這種需要畫面互動的呼叫而卡死），跟程式碼本身無關（詳見 `.claude/rules/sap-adt-mcp.md` 第 38 節）。

**✅ 2026-07-31 使用者完成六項 GUI-only 物件/設定＋兩支程式的 Selection Texts 後，完整跑過「測試流程」六個步驟，全數通過**：`ZR_TR28_PARAM_MAINT` 權限檢查／Lock／`dba_sellist` 篩選正常，雙 Session `FOREIGN_LOCK` 正常擋下，顯示模式不搶鎖，T-code `ZTR28_MAINT` 與 `ZR_TR28_PRICE_CALC` 的按鈕都正確導向維護畫面，且改折扣後 `ZR_TR28_PRICE_CALC` 的 `final_price` 確認連動變化。**ex28 至此全數完工。**

## 版本沿革

**2026-07-31 初版**：工廠(WERKS)＋通用參數(PARAM/PARVAL) 設計，`ZTR28_WPARM`／`ZTR28_WERK`／`EZTR28_WERKS`。新增 `VIEW_MAINTENANCE_CALL` 的 `dba_sellist` 工廠篩選＋改用 `SELECTION-SCREEN FUNCTION KEY`（取代原本需要 SE41 GUI Status 的 `SET PF-STATUS`/`AT USER-COMMAND` 設計）。使用者實測 Lock 與篩選皆正常。

**2026-07-31 第二版**：`ZR_TR28_PARAM_LIST` 按鈕改用 SE93 Parameter Transaction `ZTR28_SM30`，取代硬寫在程式碼裡的 `SET PARAMETER ID 'VIM'` + `CALL TRANSACTION 'SM30' AND SKIP FIRST SCREEN`。這裡有一個教材編寫時猜錯、被使用者截圖實測糾正的細節：Claude 原本指示在 SE93 用「Values for SPA/GPA Parameters」表格填 Parameter ID `VIM`，但正確位置是畫面下方獨立的「Default Values」（screen field）表格，欄位是 `VIEWNAME`／`UPDATE`。

**2026-07-31 第三版**：使用者反饋「參數維護完全沒有接到任何計算，教學意義有限」，整個改版成「航空公司折扣」設計——表格改成 `ZTR28_CDISC`（`CARRID` 為 key，外鍵指向 `SCARR`），權限物件改成 `ZTR28_CARR`，Lock Object 改成 `EZTR28_CARR`，`ZR_TR28_PARAM_LIST` 輸出改用 ALV（`REUSE_ALV_GRID_DISPLAY`），並新增 `ZR_TR28_PRICE_CALC` 計算報表（JOIN `SPFLI`/`SFLIGHT` 套用折扣算最終票價）＋`ZR_TR28_SEED_DEMO` 種子程式。物件命名全部改成折扣語意（PFCG 角色名稱 `ZTR28_MAINT_ROLE` 沿用，只改授權內容指向新物件）；折扣欄位改用正式 `DEC` 型別（`ZTR28_DISCPCT`，值域 0~100）取代原本通用的 `PARVAL(CHAR40)` 文字欄位設計。

**2026-07-31 第四版（本次，最終版）**：使用者發現 `ZR_TR28_PRICE_CALC` 也需要按鈕與 ALV 輸出（跟 `ZR_TR28_PARAM_LIST` 補齊），補上後意識到 `ZR_TR28_PARAM_LIST`（清單＋沒有保護的對照按鈕）跟 `ZR_TR28_PRICE_CALC` 的按鈕功能完全重複，教學上多餘，予以拿掉——本題最終只留**兩支主程式**：`ZR_TR28_PARAM_MAINT`（維護入口）與 `ZR_TR28_PRICE_CALC`（主要報表，選取畫面按鈕可直接跳去維護，同時扮演原本 `ZR_TR28_PARAM_LIST` 的「無保護對照組」角色）。`ZR_TR28_PARAM_LIST` 物件因 ADT 無刪除 API 而保留，原始碼改成說明性 stub。另外新增 Selection Texts 的 GUI-only 操作步驟（第六點五部分），修正選取畫面顯示技術欄位名稱而非中文說明的問題。排錯過程中也發現一個新的 ADT `programrun` 限制：某個特定物件一旦卡住過一次就會持續卡住，跟程式碼無關，詳見 `.claude/rules/sap-adt-mcp.md` 第 38 節。
