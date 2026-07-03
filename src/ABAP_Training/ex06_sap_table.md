# 練習 6：橋接 SAP Table——SCARR 航班訓練模型

## 學習目標

- 認識第一張 SAP 資料庫表：`SCARR`（航空公司主檔，SAP 官方訓練資料模型）
- 會用 SE11 看表定義、SE16 瀏覽表資料
- 會參照 DDIC 宣告變數：`TYPE scarr`（一列）、`TYPE scarr-carrid`（單一欄位）
- 寫出第一個 `SELECT ... INTO TABLE` 與 `SELECT SINGLE`
- 知道舊程式的 `LIKE scarr-carrid` 與 `TYPE scarr-carrid` 等價（新程式用 TYPE）

## 事前準備

1. 建立程式 `ZR_TR06_<你的姓名縮寫>`，套件 `$TMP`
2. **講師課前確認**：SE16 看 `SCARR` 是否有資料；沒有的話先執行報表 `SAPBC_DATA_GENERATOR`（SE38）產生航班訓練資料
3. 學員先用 SE11 看 `SCARR` 的欄位定義、SE16 看實際資料，認識 `CARRID`（代碼）、`CARRNAME`（名稱）、`CURRCODE`（幣別）三個欄位

## 題目需求

1. 宣告：`gt_carriers`（`SCARR` 的 internal table）、`gs_carrier`（`TYPE scarr`）、`gv_carrid`（`TYPE scarr-carrid`）
2. `SELECT * FROM scarr INTO TABLE @gt_carriers UP TO 10 ROWS.` 讀資料，讀完檢查 `sy-subrc`，沒資料就輸出提示訊息並 `RETURN`
3. 輸出筆數與清單（代碼/名稱/幣別）
4. 用 `SELECT SINGLE` 讀代碼 `'AA'` 的航空公司，檢查 `sy-subrc` 後輸出

## 預期輸出（範例，依系統資料而定）

```
讀到筆數：         10
=== 航空公司清單（代碼 / 名稱 / 幣別）===
AA American Airlines    USD
AB Air Berlin           EUR
AC Air Canada           CAD
...
SELECT SINGLE 找到航空公司： AA
```

## 為什麼用 SCARR 而不是 MARA/MARD？

`SCARR`/`SFLIGHT` 是 SAP 為教學設計的航班模型：欄位少、語意直觀（航空公司、航班、票價），不需要任何業務模組知識。等 internal table 與 SELECT 都熟了，再進到需要業務背景的實務表（物料、庫存）也就只是換表名而已。

## 思考題

1. `SELECT *` 和只選需要的欄位（如 `SELECT carrid carrname`），實務上哪個好？為什麼？
2. `UP TO 10 ROWS` 拿掉會怎樣？對 SCARR 這種小表沒差，那對千萬筆的交易表呢？

## 答案

見 `zr_tr06_sap_table.prog.abap`（SAP 端程式 `ZR_TR06_SAP_TABLE`）。
