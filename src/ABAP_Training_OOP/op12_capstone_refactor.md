# OOP 練習 12：期末綜合——報表 OO 化重構

## 學習目標

- 能把傳統報表（ex13）重構成「商業邏輯在 Class、程式只剩 UI 薄層」——團隊風格規範要求的新程式寫法
- 綜合運用整個課程：類別設計（op01–05）、例外（op09）、單元測試（op10）、`cl_salv_table`（op11）
- 理解「取數」與「計算」拆開的理由：純計算方法不碰 DB，測試餵假資料就能全分支驗證
- 體會「重構不改行為」：同樣查詢條件，重構前後資料列必須一致

## 事前準備

已完成 ex13（有跑過答案 `ZR_TR13_CAPSTONE` 更好）。ADT 建立兩個類別 + 一支程式，套件 `$TMP`：
`ZCX_OO12_NO_DATA`、`ZCL_OO12_FLIGHT_REVENUE`、程式 `ZR_OO12_<你的姓名縮寫>`。

## 題目需求

把 ex13 航班營收報表重構成三層：例外類別 + 商業邏輯類別（附測試）+ UI 薄層。

1. `ZCX_OO12_NO_DATA`：繼承 `CX_STATIC_CHECK`，`get_text` 回傳查無資料訊息（做法同 op09，這次不用帶屬性）
2. `ZCL_OO12_FLIGHT_REVENUE`：
   - 公開 TYPES：`ty_revenue`（沿用 ex13 的欄位：carrid/carrname/connid/fldate/seatsocc/price/currency/revenue）、`tt_revenue`、`tr_carrid`/`tr_fldate`（`TYPE RANGE OF`，接選擇畫面的 SELECT-OPTIONS）
   - `build`：**純計算**——`iv_skip_unsold = abap_true` 時刪除 `seatsocc = 0`，逐筆算 `revenue = price × seatsocc`（用 `ASSIGNING` 直接改，不用 MODIFY）；**不碰資料庫**
   - `get_revenues`：SFLIGHT INNER JOIN SCARR（= ex13 的 get_data），呼叫 `build`，結果為空 `RAISE EXCEPTION TYPE zcx_oo12_no_data`
3. Test Classes：`ltc_flight_revenue`（HARMLESS/SHORT），至少三個方法——營收有算對、skip 時未售出被排除、不 skip 時保留且營收為 0。**全部只測 `build`，不碰 DB**
4. `ZR_OO12_<縮寫>`：選擇畫面照抄 ex13（航空公司/日期範圍 + checkbox），`START-OF-SELECTION` 只做——TRY 呼叫 `get_revenues`（`s_carrid[]` 直接傳給 RANGE 參數、checkbox 用 `xsdbool( )` 轉 `abap_bool`）→ `cl_salv_table` 輸出 → CATCH 兩種例外。**UI 層 30 行內**（不含註解）
5. 驗收：與 `ZR_TR13_CAPSTONE` 用相同條件執行，**資料列內容一致**（輸出載體從分頁 List 換成 ALV 是本次重構「唯二」的行為差異：分頁頁首頁尾與總頁數回填由 ALV 內建功能取代）

## 預期結果

- 選擇畫面同 ex13；執行出 ALV（筆數在標題），checkbox 行為同 ex13
- 條件縮小到查無資料：狀態列訊息（來自 `ZCX_OO12_NO_DATA=>get_text`），不噴錯
- `Ctrl+Shift+F10`：三個測試綠燈

## 課程總結：ex13 → op12 對照

| ex13（傳統） | op12(OO) | 學到的課 |
|---|---|---|
| FORM get_data 全域變數 | 類別方法、參數進出 | op01–04 封裝 |
| 邏輯散在程式裡 | `ZCL_` 全域類別，跨程式可重用 | op05 |
| 查無資料 WRITE 訊息 | `ZCX_` 例外，呼叫端必須面對 | op09 |
| 沒有測試（沒法測） | build 純方法 + 三綠 | op10 |
| WRITE 分頁 + 頁數回填 | `cl_salv_table` 內建 | op11 |

## 團隊實務備註

- **「取數薄、計算純」**是可測試設計的核心招式：`get_revenues` 薄到幾乎不會錯（SELECT + 轉呼叫），`build` 純到隨便測——DB 依賴被隔離在最小範圍
- UI 層只剩「收參數、呼叫、展示、接例外」，之後要加背景執行版或 OData 版，商業邏輯一行不用改——這就是分層的回報
- 正式專案的差異：套件不是 `$TMP`（要能進 Transport）、例外要掛訊息類別（T100）而不是寫死字串、RANGE 參數視需求改成更明確的查詢條件物件
- 結業標準回顧：這支程式就是 `.claude/rules/abap-style.md`「商業邏輯盡量寫在 Class 方法中」+「新 Class 必附測試」的完整示範

## 思考題

1. `build` 為什麼設計成「進一張表、回一張表」而不是 CHANGING 同一張表？對測試友善在哪？
2. 想加「依幣別小計」（ex13 延伸挑戰 3）：邏輯該加在 `ZCL_OO12_FLIGHT_REVENUE` 還是報表層？加了之後測試怎麼補？
3. 如果哪天要求「營收算法改成扣掉 5% 手續費」：ex13 版要改哪裡、op12 版要改哪裡？各要重測什麼？——這題答得出來，你就知道這門課為什麼存在

## 答案

見 `zcx_oo12_no_data.clas.abap`、`zcl_oo12_flight_revenue.clas.abap`（+ `.testclasses.abap`）與 `zr_oo12_revenue_oo.prog.abap`（SAP 端程式 `ZR_OO12_REVENUE_OO`）。
