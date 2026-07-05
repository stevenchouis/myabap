# 練習 18：字串與日期處理

> 授課順序：接在練習 17 之後。講義見 [lec18](lectures/lec18_string_date.md)。

## 學習目標

- 會用 `CONCATENATE`（含 `SEPARATED BY`）與 `SPLIT`（含拆進多個變數）
- 會用 `CONDENSE` / `REPLACE` / `TRANSLATE` 整理字串
- 會用位移取子字串 `變數+位移(長度)`（0 起算）讀與寫，會用 `strlen( )`
- 會做日期運算：加減天數、天數差、月初月末套路

## 事前準備

建立程式 `ZR_TR18_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 宣告姓 `'王'`、名 `'小明'`（都是 `c LENGTH 10`），用 `CONCATENATE` 串成全名輸出；再用 `SEPARATED BY '-'` 把 `'A' 'B' 'C'` 串成 `A-B-C`
2. 宣告 `gv_csv TYPE string VALUE 'S0001,王小明,85'`，用 `SPLIT` 拆成學號、姓名、成績三個變數並輸出
3. 學號遮罩：用**位移寫入**把學號後 3 碼改成 `***`，輸出 `S0***`
4. 宣告 `'  ABAP   is   fun  '`，依序輸出：`CONDENSE` 後、`CONDENSE NO-GAPS` 後的結果
5. 把需求 4 的結果用 `REPLACE` 把 `fun` 換成 `great`，再 `TRANSLATE TO UPPER CASE` 輸出
6. 用 `strlen( )` 輸出全名的長度
7. 日期：輸出今天（`sy-datum`）、30 天後、今天距 `20260101` 的天數
8. 用「位移寫入 + 下月初減一天」套路，算出**本月**月初與月末並輸出

## 預期輸出（範例，以 2026/07/05 執行）

```
全名：王小明
串接：A-B-C
學號：S0001  姓名：王小明  成績：85
遮罩後學號：S0***
CONDENSE 後：[ABAP is fun]
NO-GAPS 後：[ABAPisfun]
取代+轉大寫：ABAP IS GREAT
全名長度：          3
今天：2026/07/05
30 天後：2026/08/04
距 2026/01/01：        185 天
本月月初：2026/07/01
本月月末：2026/07/31
```

（日期顯示格式依使用者設定，可能是 05.07.2026 等，不影響對錯。）

## 思考題

1. 需求 1 若把姓名改宣告成 `string`，`CONCATENATE` 的結果會不會不同？為什麼 `c` 的尾端空白不見了？
2. 需求 2 的 SPLIT 如果只給兩個接收變數，`gv_name` 會拿到什麼？
3. 需求 8 的月末套路為什麼要「+ 31」而不是「+ 30」？2 月會不會算錯？

## 答案

見 `zr_tr18_string_date.prog.abap`（SAP 端程式 `ZR_TR18_STRING_DATE`）。
