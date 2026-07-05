# 練習 20：Control Break 群組小計

> 授課順序：接在練習 11（JOIN）之後、練習 12（列印排版）之前。講義見 [lec20](lectures/lec20_control_break.md)。

## 學習目標

- 會用 `AT FIRST / AT NEW / AT END OF / AT LAST` 做組頭、小計、總計
- 會用 `SUM` 自動加總群組數值欄
- 體會兩條鐵則：先 `SORT`、群組欄位放結構最前面
- 認識 AT 區塊的欄位遮蔽（`*`）規則

## 事前準備

建立程式 `ZR_TR20_<你的姓名縮寫>`，套件 `$TMP`。需要航班測試資料（`SAPBC_DATA_GENERATOR`，練習 6 應已跑過）。

## 題目需求

1. 定義結果結構（**欄位順序就是考點**）：`carrid`、`carrname`、`connid`、`fldate`、`seatsocc`、`price`、`revenue`（`p LENGTH 12 DECIMALS 2`），前兩欄是群組欄位
2. `INNER JOIN` SFLIGHT＋SCARR 撈進內表（沿用練習 11 技能），`LOOP ASSIGNING` 算 `revenue = price * seatsocc`
3. 依 `carrid connid fldate` 排序
4. 用一個 `LOOP ... INTO` 完成整份報表：
   - `AT FIRST`：印報表標題
   - 組頭：印 `carrid` 與 `carrname`（提示：直接 `AT NEW carrid` 的話 carrname 會變 `*`——想想該用哪個欄位當斷點）
   - 明細行：`connid`、`fldate`、`seatsocc`、`revenue`（縮排區隔組頭）
   - `AT END OF`：`SUM` 後印該公司的 `seatsocc` 與 `revenue` 小計＋ULINE（**不要印 price 的小計**，想想為什麼）
   - `AT LAST`：`SUM` 後印總計
5. 實驗一：把 SORT 那行註解掉重跑——觀察小計亂掉的樣子，截圖或記下差異後把 SORT 加回來
6. 實驗二：把組頭改成 `AT NEW carrid.` 並印 `gs-carrname`——觀察 `*` 遮蔽現象，再改回正確寫法

## 預期輸出（範例，數字依測試資料而異）

```
=== 航班營收（依公司小計） ===
AA American Airlines
     0017 2026.01.03        380      159,494.31
     0017 2026.01.31        372      156,136.13
     小計                    752      315,630.44
------------------------------------------------
AZ Alitalia
     ...
     小計                    ...
------------------------------------------------
總計                       5,204    2,381,904.99
```

## 思考題

1. `AT NEW carrid` 的觸發規則是「carrid **及其左邊所有欄位**任一變動」——如果把 `fldate` 移到結構第一欄，小計會變成什麼樣子？
2. `SUM` 把 `price` 也加總了，為什麼「單價的合計」是個沒有意義的數字？
3. 如果只要各公司合計、完全不要明細，除了 Control Break 還有什麼更省的做法？（提示：SELECT SUM ... GROUP BY）

## 答案

見 `zr_tr20_control_break.prog.abap`（SAP 端程式 `ZR_TR20_CONTROL_BREAK`）。
