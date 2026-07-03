# 基礎 ABAP Training 練習題

本目錄存放基礎 ABAP 教育訓練的練習題目與答案程式。

## 目錄結構慣例

- 題目說明：`exNN_主題.md`（題目敘述、需求、預期輸出）
- 答案程式：`zr_trNN_主題.prog.abap`（abapGit 命名，對應 SAP 中的 `ZR_TRNN_*` 程式）
- 答案程式建立於 SAP 後，快照同步到本目錄（與 `src/` 其他檔案相同的單向快照原則）

## 題目清單

| # | 主題 | 題目 | 答案程式 | 狀態 |
|---|---|---|---|---|
| 1 | 語法基礎（statement/句點/註解/鏈式） | [ex01](ex01_syntax_basics.md) | `ZR_TR01_SYNTAX_BASICS` | 完成 |
| 2 | 變數與 TYPE/LIKE/CONSTANTS | [ex02](ex02_type_like.md) | `ZR_TR02_TYPE_LIKE` | 完成 |
| 3 | Local Type 與 Structure | [ex03](ex03_structures.md) | `ZR_TR03_STRUCTURES` | 完成 |
| 4 | Internal Table 基礎（APPEND/LOOP/READ TABLE） | [ex04](ex04_itab_basics.md) | `ZR_TR04_ITAB_BASICS` | 完成 |
| 5 | Internal Table 進階（SORT/MODIFY/DELETE） | [ex05](ex05_itab_advanced.md) | `ZR_TR05_ITAB_ADVANCED` | 完成 |
| 6 | 橋接 SAP Table（SCARR 航班模型、SELECT） | [ex06](ex06_sap_table.md) | `ZR_TR06_SAP_TABLE` | 完成 |
| 7 | 選擇畫面（PARAMETERS/SELECT-OPTIONS/IN） | [ex07](ex07_selscreen.md) | `ZR_TR07_SELSCREEN` | 完成 |
| 8 | 模組化（FORM/USING/CHANGING、Method 初識） | [ex08](ex08_modularize.md) | `ZR_TR08_MODULARIZE` | 完成 |
| 9 | ALV 輸出（cl_salv_table、TRY/CATCH 初識） | [ex09](ex09_alv.md) | `ZR_TR09_ALV` | 完成 |
