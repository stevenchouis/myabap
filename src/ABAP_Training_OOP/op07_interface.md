# OOP 練習 7：介面

## 學習目標

- 會定義 `ZIF_` 全域介面：只有方法「宣告」、沒有實作
- 會在類別用 `INTERFACES` 實作介面，方法名寫成 `zif_xxx~方法名`
- 會宣告「介面參考」（`TYPE REF TO zif_xxx`）裝任何實作類別的物件
- 理解「寫給介面不寫給實作」：呼叫端只認識規格，新增實作不用改呼叫端
- 能分辨繼承（is-a，共用實作）與介面（can-do，只共用規格）的使用時機

## 事前準備

ADT 建立一個介面 + 兩個類別 + 一支測試程式，套件 `$TMP`：
`ZIF_OO07_DISCOUNT`、`ZCL_OO07_DISC_CHILD`、`ZCL_OO07_DISC_SENIOR`、程式 `ZR_OO07_<你的姓名縮寫>`。

## 題目需求

情境：op06 思考題 2 的正解——兒童票、敬老票這種「折扣規則」如果每個艙等都開子類別，類別數量會爆炸（3 艙等 × N 種折扣）。折扣自成一族，用介面定規格。

1. 介面 `ZIF_OO07_DISCOUNT`，兩個方法：
   - `get_name`：`RETURNING VALUE(rv_name) TYPE string`——折扣名稱
   - `apply`：`IMPORTING iv_fare TYPE s_price`、`RETURNING VALUE(rv_fare) TYPE s_price`——套用折扣
2. `ZCL_OO07_DISC_CHILD` 實作介面：兒童票 65 折
3. `ZCL_OO07_DISC_SENIOR` 實作介面：敬老票 8 折
4. 測試程式：
   - 用 op06 的 `ZCL_OO06_FARE_BUSINESS` 算出商務艙票價（基本票價 1000）
   - 宣告 `TYPE TABLE OF REF TO zif_oo07_discount` 的表格，裝入兩種折扣物件
   - 迴圈輸出每種折扣的名稱與折扣後票價——**迴圈內只透過介面參考呼叫**
5. 觀察：實作類別裡方法名是 `zif_oo07_discount~apply`；透過介面參考呼叫時只寫 `lo_disc->apply( ... )`

## 預期輸出（範例）

```
商務艙原價: 2500.00
────────────────────────
兒童票(65折): 1625.00
敬老票(8折): 2000.00
```

## 團隊實務備註

- 介面 = 合約：實作類別少寫一個方法就編譯不過——規格由編譯器強制執行
- 「寫給介面」的威力：之後加「早鳥票」只要新增一個實作類別、表格多一行，**迴圈與其他呼叫端一行都不用改**——這就是開放封閉原則的雛形
- 繼承 vs 介面的選擇：有共通「實作」要繼承（op06 的 super->）；只有共通「規格」用介面。一個類別只能繼承一個父類別，但可以實作多個介面
- 團隊命名慣例表的 `ZIF_` 就是這裡落地：跨模組的服務約定都先定介面

## 思考題

1. 折扣如果做成 `ZCL_OO06_FARE` 的子類別（如 `ZCL_FARE_BUSINESS_CHILD`），3 種艙等 × 4 種折扣要幾個類別？用介面呢？
2. `zcl_oo07_disc_child` 的物件能不能裝進 `TYPE REF TO zcl_oo06_fare`？為什麼不行？（提示：它們沒有繼承關係——介面參考與類別參考是兩套相容規則）
3. 想同時套用「兒童票+早鳥」兩種折扣，呼叫端怎麼寫最省事？（提示：折扣表格 LOOP 起來連乘——介面參考的表格就是為這種事存在的）

## 答案

見 `zif_oo07_discount.intf.abap`、`zcl_oo07_disc_child.clas.abap`、`zcl_oo07_disc_senior.clas.abap` 與 `zr_oo07_discount_demo.prog.abap`（SAP 端程式 `ZR_OO07_DISCOUNT_DEMO`）。
