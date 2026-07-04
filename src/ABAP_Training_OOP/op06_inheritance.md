# OOP 練習 6：繼承

## 學習目標

- 會用 `INHERITING FROM` 建立子類別，理解「子類別自動擁有父類別的一切」
- 會用 `REDEFINITION` 覆寫父類別方法，並用 `super->` 沿用父類別的實作再加料
- 理解 `ABSTRACT`：抽象類別不能 NEW、抽象方法強迫子類別實作
- 理解 `FINAL`：封死繼承（類別層級）
- 能用「is-a（是一種）」檢驗繼承關係是否合理

## 事前準備

ADT 建立四個類別 + 一支測試程式，套件 `$TMP`：
`ZCL_OO06_FARE`（抽象基底）、`ZCL_OO06_FARE_ECONOMY`、`ZCL_OO06_FARE_BUSINESS`、`ZCL_OO06_FARE_FIRST`、程式 `ZR_OO06_<你的姓名縮寫>`。

## 題目需求

情境：艙等計價——同一個基本票價，不同艙等有不同的加價規則。

1. 抽象基底 `ZCL_OO06_FARE`（`ABSTRACT`）：
   - `calc_fare`：`IMPORTING iv_base_price TYPE s_price`、`RETURNING`；基底實作＝原價回傳
   - `get_cabin_name`：`ABSTRACT` 方法（只宣告不實作），`RETURNING VALUE(rv_name) TYPE string`——強迫每個子類別自報艙等名
2. `ZCL_OO06_FARE_ECONOMY`：繼承基底；只實作 `get_cabin_name`（計價直接沿用父類別＝原價）
3. `ZCL_OO06_FARE_BUSINESS`：`REDEFINITION` 覆寫 `calc_fare`——**用 `super->calc_fare( ... )` 先拿父類別結果**再乘 2.5
4. `ZCL_OO06_FARE_FIRST`：**繼承 BUSINESS**（不是直接繼承基底），`calc_fare` = `super->` 的商務艙價再乘 1.6；類別加上 `FINAL`
5. 測試程式：基本票價 1000，分別 NEW 三種艙等物件並輸出艙等名與票價
6. 實驗（看完註解掉）：
   - `NEW zcl_oo06_fare( )` → 抽象類別不能實例化（編譯錯誤）
   - 試寫一個類別 `INHERITING FROM zcl_oo06_fare_first` → FINAL 擋下（編譯錯誤）

## 預期輸出（範例）

```
基本票價: 1000.00
經濟艙: 1000.00
商務艙: 2500.00
頭等艙: 4000.00
```

## 團隊實務備註

- `REDEFINITION` 不能改方法簽章——參數就是父類別定的那套（這是 op08 多型能成立的前提）
- `super->` 的價值：子類別只寫「差異」，共通邏輯留在父類別一份——改共通規則只改一處
- 抽象方法 vs 基底給預設實作：**每個子類別都必須不同**的行為用 ABSTRACT；**大多數共用、少數特化**的行為給預設實作
- 繼承是強耦合：父類別一改，全部子類別跟著動。用之前先用 is-a 檢驗，猶豫時優先考慮 op07 的介面

## 思考題

1. `FIRST INHERITING FROM BUSINESS` 通過 is-a 檢驗嗎？「頭等艙是一種商務艙」聽起來怪，但程式碼共用很方便——這個 trade-off 你怎麼選？（提示：如果商務艙改成乘 3，頭等艙價格會跟著動，這是 feature 還是 bug？）
2. 想加「兒童票 65 折」：開子類別 `ZCL_OO06_FARE_CHILD`？還是 `calc_fare` 加參數？每個艙等都有兒童票時，子類別方案會爆炸成幾個類別？
3. 三種艙等物件，能不能都裝進同一個 `TYPE REF TO zcl_oo06_fare` 的變數？裝進去之後呼叫 `calc_fare` 會跑誰的版本？（動手試——這就是 op08 多型）

## 答案

見 `zcl_oo06_fare*.clas.abap` 四個類別快照與 `zr_oo06_fare_demo.prog.abap`（SAP 端程式 `ZR_OO06_FARE_DEMO`）。
