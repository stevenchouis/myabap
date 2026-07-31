# 練習 27：並行控制與 Lock Object

> 授課順序：接在練習 21（Z 資料表）之後。講義見 [lec27](lectures/lec27_lock_object.md)。

## 學習目標

- 理解為什麼多人同時改同一筆資料會有「遺失更新」問題
- 會在 SE11 建立自訂 **Lock Object**（Primary Table、Lock Parameters、Lock Mode）
- 知道怎麼查詢系統自動產生的 `ENQUEUE_*`／`DEQUEUE_*` Function Module
- 會在程式裡呼叫這兩個 FM，正確處理 `FOREIGN_LOCK` 例外
- 理解 E 模式下「同一使用者可疊加鎖定次數」的行為
- 會用 SM12 查看目前系統的鎖定紀錄

## 事前準備

沿用練習 21 的 `ZTR21_STUD`（學生表，Key 是 `MANDT`+`ID`）。物件建在套件 `$TMP`。

## 第一部分：SE11 建立 Lock Object

1. SE11 → 左邊選 **Lock Object** → 輸入 `EZTR21_STUD`（**慣例 `E` 開頭**）→ Create
2. **Tables** 頁籤：Primary Table 填 `ZTR21_STUD`
3. **Lock Parameters** 頁籤：勾選 `MANDT`、`ID`（鎖住「這一個學號」，不是整張表）
4. **Lock Mode** 選 `E`（Exclusive/Write Lock）
5. 存檔、Activate
6. **查詢系統自動產生的 FM**：該 Lock Object 畫面 → Utilities → Generated Objects，應該看到 `ENQUEUE_EZTR21_STUD`／`DEQUEUE_EZTR21_STUD` 兩個 FM；也可以直接 SE37 Display 這兩個 FM 名稱，確認 Import 參數是 `MANDT`／`ID`

## 第二部分：程式撰寫 ZR_TR27_&lt;縮寫&gt;

選擇畫面：`PARAMETERS p_id TYPE ztr21_stud-id.`（要編輯的學號）

依序完成（**每一步都印出結果，方便對照**）：

1. 呼叫 `ENQUEUE_EZTR21_STUD`（`mandt = sy-mandt`、`id = p_id`），接 `EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3`；印出 `sy-subrc` 與對應訊息（0=鎖定成功／1=已被鎖定／其他=系統異常）
2. 鎖定成功的話，`SELECT SINGLE` 讀出這筆學生資料印出來（模擬「進入編輯畫面」）
3. **驗證 E 模式可疊加**：對同一個 `p_id` **再呼叫一次** `ENQUEUE_EZTR21_STUD`——預期 `sy-subrc = 0`（同一使用者可以重複鎖定，不會擋自己），印出「第二次 ENQUEUE 也成功，鎖定次數疊加」
4. 呼叫一次 `DEQUEUE_EZTR21_STUD`，接著**馬上再檢查一次**：試著用另一個角度證明鎖還在（提示：因為呼叫了兩次 ENQUEUE，只 DEQUEUE 一次不會真正解鎖——可以在思考題說明，或呼叫 SM12 對照，程式本身不需要真的驗證這點）
5. 呼叫第二次 `DEQUEUE_EZTR21_STUD`，完全解鎖
6. 最後印出「本次編輯流程結束，鎖定已釋放」

## 預期輸出（範例，`p_id = 'S0001'`）

```
呼叫 ENQUEUE_EZTR21_STUD（學號 S0001）：sy-subrc = 0（鎖定成功）
讀取到學生資料：S0001 王小明 90
再次呼叫 ENQUEUE_EZTR21_STUD（同一使用者）：sy-subrc = 0（鎖定次數疊加，未被自己擋下）
呼叫 DEQUEUE_EZTR21_STUD 第 1 次
呼叫 DEQUEUE_EZTR21_STUD 第 2 次
本次編輯流程結束，鎖定已釋放
```

## 課堂實測：FOREIGN_LOCK 怎麼真的看到

單一次執行看不到「被別人擋下來」的效果（見講義第 7 節）。上課時請兩人一組（或一人開兩個 SAP GUI 視窗）：

1. 視窗 A 執行本程式，**在第 1 步 ENQUEUE 成功後、還沒 DEQUEUE 之前**加一個中斷點或 `WAIT UP TO 30 SECONDS`，讓程式停住
2. 視窗 B 對**同一個學號**執行同一支程式——`ENQUEUE` 那一步應該收到 `sy-subrc = 1`（`FOREIGN_LOCK`）
3. 用 **SM12** 查看目前鎖定紀錄，應該能看到視窗 A 持有的那一筆
4. 視窗 A 走完 DEQUEUE 後，SM12 那筆記錄消失，視窗 B 才能鎖定成功

## 思考題

1. 如果程式在 `ENQUEUE` 成功之後、`DEQUEUE` 之前直接當機（Dump），這筆鎖定會怎麼樣？誰、什麼時候會把它清掉？（提示：想想 Session 結束跟 SM12 的角色）
2. 練習第 4 步：呼叫兩次 `ENQUEUE`、卻只呼叫一次 `DEQUEUE`，這筆資料現在還被鎖著嗎？如果這時候另一個使用者想鎖同一筆資料，會發生什麼事？
3. Lock Object 的 Lock Parameters 如果只勾 `MANDT`（不勾 `ID`），會發生什麼事？這樣設計合理嗎？（提示：想想「鎖一筆」跟「鎖全表」的差別）
4. 如果把 Lock Mode 從 `E` 改成 `S`，練習第 3 步「同一使用者重複 ENQUEUE」的行為會不一樣嗎？如果換成兩個不同使用者都用 `S` 模式鎖同一筆，會發生什麼事？
5. Lock Object 擋得住兩個使用者同時在畫面上編輯同一筆資料，但擋不住什麼？（提示：想想練習 21 學過的「外鍵只擋畫面輸入，不擋 Open SQL」——Lock Object 是不是也有類似的「只在程式主動配合時才生效」限制？如果有人寫了一支背景程式直接 `UPDATE ztr21_stud`，完全不呼叫 `ENQUEUE`，會被擋下來嗎？）

## 答案

見 `zr_tr27_lock_object.prog.abap`（SAP 端程式 `ZR_TR27_LOCK_OBJECT`）。Lock Object `EZTR21_STUD` 無程式碼快照（結構化 DDIC 物件，非 source-based，且**建立本身是 GUI-only，ADT 沒有建立 API**，需在 SE11 手動建立——這點在 Enhancement 課程 en08 案例一也遇到過同樣的限制）。
