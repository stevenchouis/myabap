# OOP 練習 8：多型與轉型

## 學習目標

- 理解向上轉型（子物件裝進父參考）是自動的、永遠安全
- 會寫多型迴圈：一個父類別參考的表格裝各種子類別物件，同一行呼叫跑出不同行為
- 會向下轉型：`CAST`（拿回子類別專屬能力）+ `IS INSTANCE OF`（先確認再轉）
- 會用 `CASE TYPE OF` 依真實類別分流
- 理解「編譯期看參考型別、執行期看真實類別」這條鐵律

## 事前準備

沿用 op06 的四個艙等類別。另外 ADT 建立一個類別 + 一支測試程式，套件 `$TMP`：
`ZCL_OO08_FARE_GROUP`、程式 `ZR_OO08_<你的姓名縮寫>`。

## 題目需求

情境：op06 思考題 3 的正解——三種艙等物件裝進同一個父類別參考的表格，跑多型迴圈；再加一個有「專屬方法」的團體票，體會為什麼需要向下轉型。

1. `ZCL_OO08_FARE_GROUP` 繼承 `ZCL_OO06_FARE`：
   - 私有屬性 `mv_headcount TYPE i`（預設 1）+ 公開方法 `set_headcount`——**這是子類別專屬方法，父類別沒有**
   - `calc_fare` REDEFINITION：全團總價（單價 × 人數），10 人以上打 9 折
   - `get_cabin_name`：回傳含人數的名稱
2. 測試程式：
   - `NEW zcl_oo08_fare_group( )` 後呼叫 `set_headcount( 12 )`（子類別參考時期，專屬方法直接叫）
   - 宣告 `TYPE TABLE OF REF TO zcl_oo06_fare` 的表格，裝入經濟／商務／頭等／團體四個物件
   - **多型迴圈**：LOOP 輸出每個物件的艙等名與票價（基本票價 1000）
   - **向下轉型**：LOOP 中用 `IS INSTANCE OF` 找出團體票，`CAST` 回子類別後改成 20 人再輸出——先試試不 CAST 直接 `lo_fare->set_headcount( )`，看編譯錯誤
   - **`CASE TYPE OF`**：依真實類別輸出不同訊息
3. 實驗（看完註解掉）：對經濟艙物件硬做 `CAST zcl_oo08_fare_group( ... )`——編譯過，執行期 `MOVE_CAST_ERROR` 當掉

## 預期輸出（範例）

```
經濟艙: 1000.00
商務艙: 2500.00
頭等艙: 4000.00
團體票(12人): 10800.00
────────────────────────
團體票(20人) 改 20 人後: 18000.00
────────────────────────
經濟艙 → 一般艙等
商務艙 → 一般艙等
頭等艙（FINAL 類別）
團體票(20人) → 團體票（有專屬方法）
```

## 團隊實務備註

- 鐵律：**編譯期能叫哪些方法看「參考的型別」，執行期跑誰的實作看「物件的真實類別」**——多型迴圈與 REDEFINITION 都是這條的推論
- 向上轉型免寫任何語法（`lt_fares = VALUE #( ( lo_group ) )` 直接塞）；向下轉型一定要 `CAST` 且有執行期風險——先 `IS INSTANCE OF` 或用 `CASE TYPE OF`
- 程式裡出現大量 `IS INSTANCE OF` / `CASE TYPE OF` 是壞味道：通常代表該行為應該做成方法讓多型處理（讓物件自己知道怎麼做，而不是外面問它是誰）
- op07 的介面參考同樣有多型：`TYPE REF TO zif_oo07_discount` 的迴圈就是介面版多型

## 思考題

1. 多型迴圈裡 `lo_fare->calc_fare( )` 這一行，編譯器怎麼知道團體票要跑 ×人數的版本？（提示：它不知道——查表發生在執行期，關鍵字 vtable/動態繫結）
2. `CASE TYPE OF` 的 WHEN 順序重要嗎？如果把 `WHEN TYPE zcl_oo06_fare`（父類別）放第一個會怎樣？
3. 團體票「10 人以上 9 折」寫死在 `calc_fare` 裡；如果想跟 op07 的折扣介面整合（團體折扣也是一種 `ZIF_OO07_DISCOUNT`），類別設計要怎麼調整？

## 答案

見 `zcl_oo08_fare_group.clas.abap` 與 `zr_oo08_poly_demo.prog.abap`（SAP 端程式 `ZR_OO08_POLY_DEMO`）。
