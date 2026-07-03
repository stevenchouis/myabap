# 練習 8：模組化——FORM 與 Method

## 學習目標

- 理解模組化的目的：主流程只描述「做什麼」，細節放副程式
- 會定義與呼叫 `FORM`（`PERFORM`），理解 `USING`（輸入）與 `CHANGING`（輸出/雙向）
- 初識 local class 與 `CLASS-METHODS`：同一個邏輯的 OO 寫法（團隊規範方向）
- 知道 Method 的 `RETURNING` 讓呼叫端可以直接接回傳值

## 事前準備

建立程式 `ZR_TR08_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 學生結構含期中/期末/平均（沿用練習 3），建 3 筆測試資料——**放在一個無參數的 FORM `fill_data` 裡**
2. 寫 FORM `calc_avg`：`USING` 兩個成績、`CHANGING` 平均值；主流程 LOOP 中呼叫它算每個學生的平均（記得 `MODIFY` 寫回）
3. 寫 FORM `write_all` 輸出全部資料
4. 主流程（`START-OF-SELECTION`）只剩：`PERFORM fill_data.` → LOOP 計算 → `PERFORM write_all.`
5. **加碼**：照抄答案裡的 `lcl_calc` local class，用 `lcl_calc=>average( iv_s1 = 70 iv_s2 = 95 )` 算一次平均並輸出——體會 Method 呼叫的寫法

## 預期輸出（範例）

```
=== 成績與平均 ===
S0001 王小明         78         91       84.5
S0002 李小美         88         95       91.5
S0003 陳大文         60         72       66.0
Method 版計算 70 與 95 的平均：       82.5
```

## 為什麼要認識兩種寫法？

- 舊程式（如本專案 ZDQM 系列）大量使用 FORM，**看懂它是維護的基本功**
- 團隊風格規範要求**新的商業邏輯盡量寫在 Class 方法中**——FORM 沒有真正的回傳值、參數檢查弱；Method 有 `RETURNING`、型別檢查嚴格、可以做單元測試
- 結論：讀舊碼要懂 FORM，寫新碼用 Method

## 思考題

1. `calc_avg` 的 `USING` 參數如果在 FORM 裡被修改，呼叫端的變數會變嗎？（動手試——這是 FORM 的陷阱之一：USING 預設傳參考）
2. 把 `lcl_calc=>average` 的呼叫改成錯的參數名（如 `iv_x = 70`），語法檢查會怎樣？同樣的錯在 PERFORM 會被抓到嗎？

## 答案

見 `zr_tr08_modularize.prog.abap`（SAP 端程式 `ZR_TR08_MODULARIZE`）。
