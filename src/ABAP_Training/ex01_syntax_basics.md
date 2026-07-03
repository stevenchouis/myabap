# 練習 1：ABAP 語法基礎

## 學習目標

- 知道 ABAP statement 以句點「`.`」結束，可跨多行書寫
- 會用兩種註解：`*`（整行，必須在行首）與 `"`（行內，到行尾）
- 會用冒號「`:`」鏈式寫法合併多個相同關鍵字的 statement
- 知道 ABAP 關鍵字不分大小寫
- 會用 `WRITE` 與 `/`（換行）輸出文字

## 事前準備

在 SE38 建立自己的程式，命名 `ZR_TR01_<你的姓名縮寫>`（例：`ZR_TR01_ABC`），類型 Executable Program，套件 `$TMP`（Local Object）。

## 題目需求

寫一支程式，依序完成：

1. 用 `WRITE` 輸出 `Hello ABAP!`（第一行，不加 `/`）
2. 換行輸出一行自我介紹文字，並在該行程式碼**加上行內註解**
3. 用**一個**冒號鏈式 `WRITE` 輸出三行文字（不能寫三個 WRITE）
4. 用三種不同大小寫（全小寫 / 混合 / 全大寫）各寫一行 `WRITE`，證明關鍵字不分大小寫
5. 寫一個**跨三行以上**的 WRITE statement
6. 程式中至少要有一個 `*` 開頭的整行註解

## 預期輸出（範例）

```
Hello ABAP!
我是第二行
鏈式寫法第一行
鏈式寫法第二行
鏈式寫法第三行
lowercase 寫法
Mixed Case 寫法
UPPERCASE 寫法
跨多行的 statement，效果跟寫在一行一樣
```

## 提示

- `WRITE '文字'.` 輸出在目前行；`WRITE / '文字'.` 先換行再輸出
- 鏈式寫法：`WRITE: / 'A', / 'B', / 'C'.`
- 忘記句點是初學最常見的語法錯誤，看錯誤訊息時先檢查上一行

## 答案

見 `zr_tr01_syntax_basics.prog.abap`（SAP 端程式 `ZR_TR01_SYNTAX_BASICS`）。
