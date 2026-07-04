# OOP 練習 10：ABAP Unit 單元測試

## 學習目標

- 會寫 local test class：`FOR TESTING RISK LEVEL HARMLESS DURATION SHORT`
- 會用 given-when-then 組織測試方法，`cl_abap_unit_assert=>assert_equals` 驗證
- 會在 ADT 跑測試（`Ctrl+Shift+F10`）、看紅綠結果
- 理解「為可測試而設計」：依賴用建構子**注入**，不在方法裡自己 `NEW`
- 會寫測試替身（test double）：實作介面的假物件，讓測試不依賴真實類別

## 事前準備

ADT 建立類別 `ZCL_OO10_QUOTE`，套件 `$TMP`。測試類別寫在 ADT 的 **Test Classes 頁籤**（不是主源碼）。

## 題目需求

情境：把 op06 的艙等與 op07 的折扣組合成「報價引擎」，並為它補上單元測試——團隊規範「新 Class 必附測試」從這題開始是硬要求。

1. `ZCL_OO10_QUOTE`：
   - 建構子 `IMPORTING io_fare TYPE REF TO zcl_oo06_fare`、`it_discounts`（`ZIF_OO07_DISCOUNT` 參考的表格，OPTIONAL）——**依賴全部從外面注入**
   - `calc_quote`：先 `mo_fare->calc_fare( )`，再 LOOP 依序套用所有折扣，回傳最終票價
2. Test Classes 頁籤：
   - 測試替身 `ltd_half_off`：`DEFINITION FINAL FOR TESTING`、實作 `ZIF_OO07_DISCOUNT`、行為固定（永遠半價）
   - 測試類別 `ltc_quote`（`RISK LEVEL HARMLESS DURATION SHORT`），三個測試方法：
     - `economy_no_discount`：經濟艙、無折扣 → 原價 1000
     - `business_child_discount`：商務艙 + 兒童票 → 1000 × 2.5 × 0.65 = 1625
     - `stub_discount_applies`：注入 `ltd_half_off` 替身 → 500
   - 每個方法內用註解標出 given / when / then 三段
3. `Ctrl+Shift+F10` 執行，三綠
4. 實驗（看完還原）：把 `calc_quote` 的 LOOP 註解掉再跑——看紅色測試怎麼報（期望值 vs 實際值、你寫的 msg）

## 預期輸出（範例）

```
ZCL_OO10_QUOTE > LTC_QUOTE
  BUSINESS_CHILD_DISCOUNT   passed
  ECONOMY_NO_DISCOUNT       passed
  STUB_DISCOUNT_APPLIES     passed
```

## 團隊實務備註

- `RISK LEVEL HARMLESS`＝測試不改系統狀態、`DURATION SHORT`＝跑得快——這兩個宣告讓測試可以隨時隨地放心執行，team 規範固定用這組
- **依賴注入是可測試的前提**：如果 `calc_quote` 裡自己 `NEW zcl_oo07_disc_child( )`，測試就永遠綁死真實折扣類別；從建構子注入，測試就能塞替身。op07「寫給介面」在這裡拿到第二個回報
- 測試替身解決「我只想測 A，但 A 依賴 B」的問題：給 B 一個行為固定的假貨，A 的邏輯錯誤才不會被 B 的行為干擾
- 好的測試方法名是句子（`unsold_removed_when_skip`）：測試報告紅掉時，光看名字就知道壞了什麼
- 測試也是文件：新人看 `ltc_quote` 三個方法，就知道 `calc_quote` 的完整行為

## 思考題

1. 為什麼 `it_discounts` 用介面表格而不是 `zcl_oo07_disc_child` 的表格？如果當初 op07 沒定介面，`ltd_half_off` 這個替身要怎麼寫？
2. 測試 `assert_equals` 的 `exp` 寫 `'1625.00'`——如果商務艙倍率哪天改成 3.0，這個測試會紅。這是測試「太脆」還是「盡責」？（提示：測試紅掉逼你確認：是需求真的改了，還是有人改壞了？）
3. `get_flights` 那種會 SELECT 資料庫的方法要怎麼測？（提示：op12 的答案把「取數」與「計算」拆成兩個方法——為什麼？）

## 答案

見 `zcl_oo10_quote.clas.abap` 與 `zcl_oo10_quote.clas.testclasses.abap`（測試類別 include 快照）。
