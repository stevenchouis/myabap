# OOP 練習 3：建構子與封裝

## 學習目標

- 會寫 `constructor`，理解「物件一出生就是有效狀態」——必要資料在 `NEW` 時非給不可
- 會用 `PRIVATE SECTION` 把屬性藏起來，只開放「守得住規則」的公開方法
- 會用 `READ-ONLY` 讓屬性外部可讀、不可改
- 知道 `class_constructor` 的執行時機：整個程式第一次用到該類別前，只跑一次

## 事前準備

建立程式 `ZR_OO03_<你的姓名縮寫>`，套件 `$TMP`。
本題是把 op01 的計數器類別「加上保護」——op01 思考題 2 的正式解答。

## 題目需求

1. 定義 local class `lcl_carrier_stats`：
   - `PUBLIC SECTION`：屬性 `mv_carrid TYPE s_carr_id READ-ONLY`
   - `PRIVATE SECTION`：屬性 `mv_flights TYPE i`
2. `constructor`：`IMPORTING iv_carrid`，`NEW` 時就綁定航空公司
3. `add_flights`：`IMPORTING iv_count TYPE i`，**只接受正數**，負數直接忽略（正式做法是丟例外——op09 再教）
4. `get_flights`：`RETURNING` 回傳目前計數
5. `class_constructor`：輸出一行訊息；主程式 `NEW` 兩個物件（AA、LH），觀察這行訊息只出現一次
6. AA 加 5 個航班、再故意加 -99（應被擋下）、LH 加 2 個，輸出驗證
7. 試著在主程式直接寫 `go_aa->mv_flights = 999.` 和 `go_aa->mv_carrid = 'XX'.`，觀察兩種**編譯期**錯誤訊息（抄下來），再註解掉

## 預期輸出（範例）

```
>>> class_constructor：整個程式只執行這一次
>>> constructor：建立 AA 的統計物件
>>> constructor：建立 LH 的統計物件
=== 封裝後的物件 ===
AA 航班數:          5
LH 航班數:          2
```

## 團隊實務備註

- 封裝原則：屬性**預設放 private**；需要讓外部唯讀才用 `READ-ONLY` 或 getter；需要讓外部改就提供方法——方法裡才守得住業務規則（如「航班數不能是負的」）
- `constructor` 不能有 `EXPORTING` / `RETURNING`，且每個類別只有一個（ABAP 方法沒有多載）
- `class_constructor` 是靜態方法（`CLASS-METHODS`）——靜態成員的完整介紹在 op04

## 思考題

1. `READ-ONLY` 屬性和「private 屬性 + getter 方法」效果很像，差在哪？什麼情況一定要用 getter？（提示：getter 可以算出來再給，READ-ONLY 只能原樣給）
2. `add_flights` 收到負數現在是默默忽略——呼叫端根本不知道被擋了。想讓呼叫端知道，有哪些選項？各有什麼缺點？（op09 例外類別會給正式答案）
3. `constructor` 裡適合做 `SELECT` 之類的重活嗎？如果建構子失敗，呼叫端拿到的是什麼？

## 答案

見 `zr_oo03_encapsulation.prog.abap`（SAP 端程式 `ZR_OO03_ENCAPSULATION`）。
