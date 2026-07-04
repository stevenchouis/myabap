# OOP 練習 5：全域類別

## 學習目標

- 會在 ADT（Eclipse）建立全域類別 `ZCL_`，理解它跟 local class 的差別：**不綁在任何程式裡，全系統都能用**
- 看懂全域類別的定義骨架：`PUBLIC` / `FINAL` / `CREATE PUBLIC`
- 體會「跨程式重用」：一個類別，多支程式共用——對照練習 15 用 FM 達成同一件事
- 建立分層觀念：全域類別只管邏輯**不做 WRITE**，輸出是呼叫端（報表）的責任

## 事前準備

- 從本題起改用 **ADT（Eclipse）** 開發：File → New → ABAP Class
- 類別 `ZCL_OO05_<你的姓名縮寫>`、測試程式 `ZR_OO05_<你的姓名縮寫>`，套件 `$TMP`

## 題目需求

1. 把 op03 的 `lcl_carrier_stats` **搬家**成全域類別 `ZCL_OO05_CARRIER_STATS`：
   - 介面不變：`constructor( iv_carrid )`、`add_flights( iv_count )`（只收正數）、`get_flights( )`、`mv_carrid` READ-ONLY、`mv_flights` private
   - **拿掉 op03 版本裡所有 WRITE**（constructor 與 class_constructor 的訊息）——全域類別不該假設自己活在報表裡
2. 寫測試程式 `ZR_OO05_USE_GLOBAL`：用法跟 op03 完全一樣，但類別定義**不在程式裡**——程式瞬間變短
3. 觀察 ADT 中類別的樣子：Outline、F3 跳進標準類別看看（例如 `CL_ABAP_TYPEDESCR`），感受「系統裡到處都是類別」
4. 想像另一位同事的程式也要統計航班——他直接 `NEW zcl_oo05_carrier_stats( ... )` 就好，不用複製任何程式碼

## 預期輸出（範例）

```
=== 全域類別：類別在系統裡，程式只剩使用 ===
AA 航班數:          5
LH 航班數:          2
```

## 團隊實務備註

- 團隊規範「商業邏輯寫在 Class 方法、程式只剩 UI 薄層」指的就是**全域類別**——local class 是學習與程式內小工具用，正式邏輯一律 `ZCL_`
- `FINAL`：ADT 範本預設加上，意思是「不開放繼承」；什麼時候該拿掉，op06 繼承會講
- 全域類別裡做 WRITE、MESSAGE 等 UI 動作是壞味道：邏輯與呈現綁死，之後想在 ALV、API、背景作業重用都不行
- 命名：類別檔案快照是 `zcl_oo05_carrier_stats.clas.abap`（abapGit 慣例，`.clas` 表示 class）

## 思考題

1. 同樣是「跨程式重用」，FM（練習 15）和全域類別差在哪？如果邏輯需要「記住狀態」（像本題的計數器），FM 做得到嗎？
2. op03 的 class_constructor 訊息拿掉了，如果全域類別真的需要「回報發生了什麼」，除了 WRITE 還有什麼選項？（回傳值？例外？——op09）
3. 把類別從 local 搬到 global，呼叫端程式碼改了幾行？這說明了什麼？

## 答案

見 `zcl_oo05_carrier_stats.clas.abap`（SAP 端類別 `ZCL_OO05_CARRIER_STATS`）與 `zr_oo05_use_global.prog.abap`（程式 `ZR_OO05_USE_GLOBAL`）。
