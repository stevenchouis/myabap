# 練習 28：客製 Table Maintenance 的權限防護與並行控制

> 授課順序：接在練習 27（Lock Object）之後。講義見 [lec28](lectures/lec28_auth_wrapper.md)。

## 學習目標

- 理解 SM30 原生權限檢查（`S_TABU_DIS`/`S_TABU_NAM`）只到表格層級，業務維度要自己包 Wrapper
- 會在 SU21 建立自訂**權限物件**（`ACTVT`＋業務欄位），並知道 `AUTHORITY-CHECK` 怎麼呼叫
- 理解 Lock Object 的鎖定範圍**不必等於表格主鍵**，要對應「使用者實際爭搶的資源邊界」
- 會用 `VIEW_MAINTENANCE_CALL` 從程式呼叫標準 Table Maintenance
- 理解「T-code 要指給 Wrapper 程式，不能指給裸的 SM30」這個設計為什麼重要
- 會用 `SET PF-STATUS` + `AT USER-COMMAND` + `CALL TRANSACTION` 在 Report 的 App bar 加自訂按鈕呼叫另一支 Transaction

## 事前準備

物件建在套件 `$TMP`。沿用練習 21 學過的 Z 表＋外鍵技巧，這次外鍵指向**標準表** `T001W`（工廠主檔，呼應練習 25「Check Table 指向標準表」的手法）。

## 第一部分：DDIC（已由 Claude 建立並啟用，可直接對照）

1. Domain/DE `ZTR28_PCODE`（CHAR 10，參數代碼）、`ZTR28_PARVAL`（CHAR 40，參數值）——`PARTXT`（說明文字）重用標準 DE `TEXT40`，不用另外自建（呼應練習 25「能重用標準就不要自己蓋」的判斷）
2. 表 `ZTR28_WPARM`：

| 欄位 | Key | 型別來源 | 說明 |
|---|---|---|---|
| MANDT | ✔ | Data Element `MANDT` | client |
| WERKS | ✔ | Data Element `WERKS_D`，外鍵指向標準表 `T001W` | 工廠 |
| PARAM | ✔ | Data Element `ZTR28_PCODE` | 參數代碼 |
| PARVAL | | Data Element `ZTR28_PARVAL` | 參數值 |
| PARTXT | | 標準 Data Element `TEXT40` | 參數說明 |
| UPDUSER | | Data Element `SYUNAME` | 異動者 |
| UPDDATE | | Data Element `SYDATUM` | 異動日 |

外鍵 `WERKS` 的 Check Table 是**標準表 `T001W`**（不是自建表），Cardinality `[0..*,1]`，`screenCheck : true`。

## 第二部分：SU21 建立自訂權限物件（需使用者手動建立，ADT 沒有建立 API）

1. **SU21** → Object Class 選 `BC` → Create Authorization Object
2. 物件名稱 `ZTR28_WERKS`，Short Text 自訂
3. Authorization Fields：`ACTVT`（標準欄位）、`WERKS`（本題業務欄位，型別參考 Data Element `WERKS_D`）
4. 存檔、Activate
5. **這一步只是定義「有哪些欄位可以管控」，真正要讓某個使用者擁有權限，還要在 PFCG 把這個物件加進角色、給值（如 `ACTVT=02`、`WERKS=1011`），指派給使用者**——這部分是權限管理員的工作，不是本題重點，但缺這一步的話，任何人 `AUTHORITY-CHECK` 都會失敗（`sy-subrc <> 0`），程式邏輯本身不受影響

## 第三部分：SE11 建立 Lock Object（需使用者手動建立）

1. SE11 → Lock Object → `EZTR28_WERKS` → Create
2. Primary Table：`ZTR28_WPARM`
3. Lock Parameters：**只勾 `MANDT`、`WERKS`（不勾 `PARAM`）**——鎖定範圍是「整個工廠」，不是「單一參數列」，見講義第 3 節的設計理由
4. Lock Mode：`E`
5. 存檔、Activate——系統會產生 `ENQUEUE_EZTR28_WERKS`／`DEQUEUE_EZTR28_WERKS`

## 第四部分：SM30 Table Maintenance Generator（需使用者手動建立，同練習 21 手法）

1. SE11 該表 → Utilities → Table Maintenance Generator
2. Authorization Group `&NC&`；Function Group `ZFG_TR28`；One step
3. 產生後可以直接用 SM30 手動測試維護畫面本身（先不管權限/鎖定 Wrapper，純粹確認 View 本身能動）

## 第五部分：SE93 建立 T-code（需使用者手動建立）

1. SE93 → T-code `ZTR28_MAINT` → Create
2. 型態選 **Program and selection screen (Report transaction)**
3. Program 填 `ZR_TR28_PARAM_MAINT`（**Wrapper 程式，不是 SM30、不是 View 名稱**），Screen `1000`
4. 存檔

## 第六部分：SE41 建立 GUI Status（需使用者手動建立）

1. SE41 → Program `ZR_TR28_PARAM_LIST`、Status `ZTR28LIST` → Create
2. Application Toolbar 加一個按鈕：Function Code `MAINT`，文字/圖示自訂（如「維護」）
3. 存檔、Activate

## 第七部分：程式（已由 Claude 建立並啟用，見下方原始碼）

- **`ZR_TR28_PARAM_MAINT`**（Wrapper）：選取畫面 `p_werks`（工廠，預設 `1011`）＋ `p_disp`（勾選＝只顯示）。依序：`AUTHORITY-CHECK` → （維護模式才）`ENQUEUE_EZTR28_WERKS` → `VIEW_MAINTENANCE_CALL` → （維護模式才）`DEQUEUE_EZTR28_WERKS`
- **`ZR_TR28_PARAM_LIST`**（清單＋入口按鈕）：`SELECT-OPTIONS s_werks` 篩選顯示 `ZTR28_WPARM` 內容，`TOP-OF-PAGE` 掛 `SET PF-STATUS 'ZTR28LIST'`，`AT USER-COMMAND` 處理 `sy-ucomm = 'MAINT'` 時 `CALL TRANSACTION 'ZTR28_MAINT'`

## 測試流程

**未建齊 GUI-only 物件時**（`programrun` 無頭驗證，已由 Claude 執行過）：

```
ZR_TR28_PARAM_LIST（空表）→ 印出「（沒有資料，或選取條件沒有命中）」，SET PF-STATUS 未定義的狀態名稱不會造成 dump
ZR_TR28_PARAM_MAINT（p_werks=1011）→ 權限不足：無法對工廠 1011 執行 維護（sy-subrc = 12，代表系統裡還沒有這個權限物件）
```

**五個 GUI-only 物件都建好、且透過 PFCG 給自己指派了 `ZTR28_WERKS`（`ACTVT=02`、`WERKS=1011`）角色之後**：

1. 直接執行 `ZR_TR28_PARAM_MAINT`（`p_werks=1011`，不勾顯示）：應該看到「權限檢查通過」→「鎖定成功」→ 跳出 SM30 風格的維護畫面 → 離開畫面後印出「已解鎖工廠」
2. 開兩個 Session，都對 `1011` 執行維護：第二個應該在 `ENQUEUE` 那一步被擋下（`FOREIGN_LOCK`）
3. `p_disp` 打勾（顯示模式）：應該能看、但維護畫面裡的變更功能被關閉，且完全不會呼叫 `ENQUEUE`（顯示不用搶鎖）
4. 執行 T-code `ZTR28_MAINT`（不透過 `ZR_TR28_PARAM_LIST`）：應該直接進到跟上面一樣的選取畫面
5. 執行 `ZR_TR28_PARAM_LIST`，選取工廠後按上方工具列的「維護」按鈕：應該觸發 `CALL TRANSACTION 'ZTR28_MAINT'`，行為跟直接打 T-code 一致

## 思考題

1. 如果把 `ACTVT` 拿掉，權限物件只剩 `WERKS` 一個欄位，會失去什麼控管能力？（提示：想想「能看但不能改」這種需求還做不做得到）
2. 為什麼 Wrapper 程式的 `AUTHORITY-CHECK` 跟 `VIEW_MAINTENANCE_CALL` 內部自己的權限檢查不衝突、也不是多餘的？兩者各自把關什麼？
3. 如果 Lock Object 的 Lock Parameters 改成勾整個主鍵（`MANDT`+`WERKS`+`PARAM`），會有什麼實際後果？兩個人分別維護同工廠、不同參數代碼的資料時，行為會有什麼不同？
4. `p_disp`（顯示模式）完全不呼叫 `ENQUEUE`／`DEQUEUE`，這樣設計合理嗎？如果兩個人都用顯示模式同時打開同一個工廠，會有問題嗎？
5. 如果某個使用者的角色同時擁有 `S_TABU_DIS`（對 `&NC&` Authorization Group 有維護權限）跟這支 T-code，但**沒有**被指派 `ZTR28_WERKS` 這個自訂權限物件，這個使用者能不能繞過 Wrapper、直接用 SM30 改到 `ZTR28_WPARM` 的資料？這代表整個防護設計還缺了哪一塊角色/權限管理上的配套？

## 答案

見 `zr_tr28_param_maint.prog.abap`、`zr_tr28_param_list.prog.abap`（SAP 端 `ZR_TR28_PARAM_MAINT`／`ZR_TR28_PARAM_LIST`）。DDIC 表 `ZTR28_WPARM` 快照見 `ztr28_wparm.tabl.abap`。權限物件 `ZTR28_WERKS`、Lock Object `EZTR28_WERKS`、T-code `ZTR28_MAINT`、GUI Status `ZTR28LIST` 均為 GUI-only（SU21／SE11／SE93／SE41 皆無 ADT 建立 API），無程式碼快照，需照上方步驟手動建立。

**已用 `programrun` 驗證的部分**：兩支程式皆已建立、啟用、無語法錯誤；`ZR_TR28_PARAM_MAINT` 在權限物件尚未建立時正確回報「權限不足（sy-subrc=12）」，證實 Wrapper 的檢查順序與邏輯正確。**五個 GUI-only 物件建好後的端對端驗證（含 `VIEW_MAINTENANCE_CALL` 畫面互動、雙 Session `FOREIGN_LOCK`、App bar 按鈕）需要使用者在 SAP GUI 手動確認**，這部分不受 ADT `programrun` 支援（跟講義提過的「會開全螢幕畫面的呼叫沒辦法無頭驗證」限制相同）。
