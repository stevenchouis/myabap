# 練習 14：INCLUDE 拆檔——TOP 與 SUBROUTINE

## 學習目標

- 理解 `INCLUDE` 的本質：**原地展開的程式碼片段**，跟寫在主程式裡完全等價，拆檔是為了「人」好維護
- 掌握實務拆檔慣例：
  - `<程式名>_TOP`：全域宣告（TYPES / DATA / 選擇畫面）
  - `<程式名>_F01`：FORM 副程式（量大再拆 F02、F03…）
  - 主程式：只剩 INCLUDE 兩行 + 事件流程，一眼看懂骨架
- 知道 FORM 的 INCLUDE 要放**最後**（FORM 插在事件中間會造成後續事件碼進不到）
- 會在 SE38/SE80 建 INCLUDE（程式類型選 Include program）並雙擊導覽

## 事前準備

建立三個物件（套件 `$TMP`）：
1. `ZR_TR14_<縮寫>`：Executable Program（主程式）
2. `ZR_TR14_<縮寫>_TOP`：Include Program
3. `ZR_TR14_<縮寫>_F01`：Include Program

SE38 建 INCLUDE：程式類型（Attributes → Type）選 **I - Include program**。

## 題目需求

把「簡化版航班營收報表」拆成三個檔：

1. **TOP**：`TABLES sflight`、營收結構 TYPES、`gt_rev/gs_rev/gv_count`、選擇畫面 BLOCK（公司與日期範圍）
2. **F01**：`FORM get_data`（SELECT SFLIGHT + 計算 revenue）、`FORM display_data`（輸出 + 合計筆數）
3. **主程式**：`INCLUDE ..._top.` → `INITIALIZATION`（BLOCK 標題）→ `START-OF-SELECTION`（兩個 PERFORM）→ `INCLUDE ..._f01.`（放最後！）
4. 啟用時三個物件一起啟用（Eclipse 勾選全部；SE38 啟用主程式時會帶出清單）
5. 執行結果應與拆檔前完全相同

## 觀察與實驗

1. 在主程式雙擊 `INCLUDE zr_tr14_top.` 可以直接跳進去——導覽是拆檔後讀程式的基本功
2. 把 `INCLUDE ..._f01.` 移到 `START-OF-SELECTION` 之前，啟用會看到什麼錯誤？為什麼？
3. 對照本專案實例：`ZDQM0001` 的 `INCLUDE ZDQM0001F01`——注意 **ZDQM0002 也 INCLUDE 同一支**，共用 INCLUDE 的修改會同時影響多支主程式（練習 8 改那支巨集時就是如此），這是拆檔的威力也是風險

## 思考題

1. 什麼該進 TOP、什麼該留在主程式？（慣例：宣告進 TOP、事件流程留主程式——事件是程式的「目錄」）
2. INCLUDE 沒有自己的「執行語意」——直接 F8 執行一個 INCLUDE 會怎樣？
3. 一個 INCLUDE 被多支程式共用時，語法檢查要以哪支主程式為準？（提示：這正是 ADT 啟用 INCLUDE 時要指定 context 的原因）

## 答案

見 `zr_tr14_capstone.prog.abap`、`zr_tr14_top.prog.abap`、`zr_tr14_f01.prog.abap`（SAP 端 `ZR_TR14_CAPSTONE` + 兩個 INCLUDE）。
