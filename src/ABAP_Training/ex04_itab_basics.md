# 練習 4：Internal Table 基礎

## 學習目標

- 理解 internal table（多筆）與 work area（一筆）的分工
- 會用 `TYPES ... TYPE STANDARD TABLE OF ...` 定義表格型別
- 會用 `APPEND` 加資料、`LOOP AT ... INTO` 逐筆處理
- 會用 `READ TABLE ... WITH KEY / INDEX` 讀單筆，並**養成檢查 `sy-subrc` 的習慣**
- 認識 `sy-tabix`（迴圈中目前筆數）

## 事前準備

建立程式 `ZR_TR04_<你的姓名縮寫>`，套件 `$TMP`。

## 題目需求

1. 沿用練習 3 的學生結構（學號/姓名/成績即可），再用 `TYPES ... TYPE STANDARD TABLE OF` 定義表格型別
2. 宣告 internal table `gt_students` 與 work area `gs_student`
3. 用 `APPEND` 加入 3 筆學生資料
4. 用 `LOOP AT ... INTO` 輸出全部資料，每行開頭印出 `sy-tabix`
5. 用 `READ TABLE ... WITH KEY` 找出學號 `S0002`，找到才輸出（檢查 `sy-subrc`）
6. 用 `READ TABLE ... INDEX 3` 讀第三筆並輸出
7. 故意讀一個不存在的學號，輸出 `sy-subrc` 的值——觀察不是 0

## 預期輸出（範例）

```
=== 全部學生 ===
         1 S0001 王小明         85
         2 S0002 李小美         92
         3 S0003 陳大文         67
WITH KEY 找到 S0002： 李小美
INDEX 3 讀到的是： 陳大文
查無 S9999，sy-subrc =          4
```

## 思考題

1. `READ TABLE` 找不到時，work area 裡是什麼？（提示：印出來看看——這是實務上「用到上一筆殘留值」bug 的由來）
2. `APPEND` 之後忘記換 work area 內容，連按兩次 APPEND 會怎樣？

## 答案

見 `zr_tr04_itab_basics.prog.abap`（SAP 端程式 `ZR_TR04_ITAB_BASICS`）。
