# 練習 8：模組化——FORM 副程式

## 學習目標

- 理解模組化的目的：主流程只描述「做什麼」，細節放副程式
- 會定義與呼叫 `FORM`（`PERFORM`）
- 理解參數傳遞：`USING`（輸入）與 `CHANGING`（輸出/雙向）
- 知道參數可以加型別（`TYPE`），讓語法檢查幫你抓錯

## 事前準備

建立程式 `ZR_TR08_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 學生結構含期中/期末/平均（沿用練習 3），建 3 筆測試資料——**放在一個無參數的 FORM `fill_data` 裡**
2. 寫 FORM `calc_avg`：`USING` 兩個成績、`CHANGING` 平均值；主流程 LOOP 中呼叫它算每個學生的平均（記得 `MODIFY` 寫回）
3. 寫 FORM `write_all` 輸出全部資料
4. 主流程（`START-OF-SELECTION`）只剩三件事：`PERFORM fill_data.` → LOOP 計算 → `PERFORM write_all.`

## 預期輸出（範例）

```
=== 成績與平均 ===
S0001 王小明         78         91       84.5
S0002 李小美         88         95       91.5
S0003 陳大文         60         72       66.0
```

## 團隊實務備註

- 舊程式（如本專案 ZDQM 系列）大量使用 FORM，**看懂 FORM 是維護的基本功**，本課先把它學紮實
- 團隊風格規範要求新的商業邏輯盡量寫在 Class 的 Method 中——Method 是 SAP OOP 課程的主角，等 OOP 課上完會再回頭比較兩者
- FORM 參數務必加 `TYPE`：沒加型別的參數什麼都能傳，錯誤要到執行期才爆

## 思考題

1. `calc_avg` 的 `USING` 參數如果在 FORM 裡被修改，呼叫端的變數會變嗎？（動手試——USING 預設傳參考，這是 FORM 的著名陷阱）
2. `fill_data` 直接改全域的 `gt_students`，這樣好嗎？如果要讓它「把結果交出來」而不是「偷偷改全域」，參數該怎麼設計？（提示：`CHANGING` 也能傳 internal table）

## 答案

見 `zr_tr08_modularize.prog.abap`（SAP 端程式 `ZR_TR08_MODULARIZE`）。
