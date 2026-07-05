# 練習 17：運算與流程控制

> 授課順序：接在練習 2 之後。講義見 [lec17](lectures/lec17_control_flow.md)。

## 學習目標

- 會用算術運算子，理解 `DIV`（整數商）／`MOD`（餘數）與「目的地型別決定精度」
- 會寫 `IF / ELSEIF / ELSE` 與 `CASE / WHEN / WHEN OTHERS`，知道兩者的適用場景
- 會用 `DO n TIMES`、無上限 `DO` + `EXIT`、`WHILE`，認識 `sy-index`
- 會用 `CHECK` / `CONTINUE` 控制迴圈流程

## 事前準備

建立程式 `ZR_TR17_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 宣告 `gv_a TYPE i VALUE 17`、`gv_b TYPE i VALUE 5`，依序輸出 `+`、`-`、`*`、`DIV`、`MOD` 五種運算結果
2. 把 `gv_a / gv_b` 分別存進 `TYPE i` 與 `TYPE p LENGTH 8 DECIMALS 2` 的變數並輸出——觀察兩者差異
3. 宣告 `gv_score TYPE i VALUE 75`，用 `IF / ELSEIF / ELSE` 判斷等第（>= 80 是 A、>= 60 是 B、其餘 C）並輸出
4. 對算出的等第用 `CASE` 輸出評語：A →「優等」、B 或 C →「普通」、其他 →「資料異常」（`WHEN OTHERS` 必須要有）
5. 用 `DO 5 TIMES` 輸出 `第 n 圈`（n 用 `sy-index`）
6. 用**無上限** `DO` 從 1 開始累加 `sy-index`，總和超過 100 就 `EXIT`，輸出總和與最後圈數
7. 用 `WHILE` 找出「平方不超過 200 的最大整數」並輸出
8. 用 `DO 10 TIMES` + `CHECK` 只輸出偶數圈（不能用 IF 包整段）

## 預期輸出（範例）

```
17 + 5 =         22
17 - 5 =         12
17 * 5 =         85
17 DIV 5 =          3
17 MOD 5 =          2
存進 i：          3
存進 p：       3.40
75 分 → 等第 B
普通
第          1 圈
（…第 2～5 圈…）
累加超過 100：總和        105 ，最後圈數         14
平方不超過 200 的最大整數：         14
偶數：          2
（…4、6、8、10…）
```

## 思考題

1. 把需求 3 的 `>= 80` 與 `>= 60` 兩個分支順序對調，75 分會得到什麼等第？為什麼？
2. 需求 6 的 `EXIT` 如果忘了寫，程式最後會怎麼結束？（提示：ST22、TIME_OUT）
3. `CHECK sy-index MOD 2 = 0.` 改寫成等價的 `IF ... CONTINUE.` 要怎麼寫？

## 答案

見 `zr_tr17_control_flow.prog.abap`（SAP 端程式 `ZR_TR17_CONTROL_FLOW`）。
