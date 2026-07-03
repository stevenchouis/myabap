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
| 8 | 模組化（FORM/USING/CHANGING） | [ex08](ex08_modularize.md) | `ZR_TR08_MODULARIZE` | 完成 |
| 9 | Functional ALV 與 MACRO（REUSE_ALV_GRID_DISPLAY/fieldcat/DEFINE） | [ex09](ex09_alv.md) | `ZR_TR09_ALV` | 完成 |
| 10 | Report Event（INITIALIZATION～AT LINE-SELECTION/HIDE） | [ex10](ex10_events.md) | `ZR_TR10_EVENTS` | 完成 |
| 11 | 多表 JOIN（INNER/LEFT OUTER、CORRESPONDING FIELDS） | [ex11](ex11_join.md) | `ZR_TR11_JOIN` | 完成 |
| 12 | 列印排版與頁面規劃（LINE-SIZE/LINE-COUNT/END-OF-PAGE、點矩陣選型） | [ex12](ex12_print_layout.md) | `ZR_TR12_PRINT_LAYOUT` | 完成 |
| 13 | 期末綜合實作：航班營收報表（含總頁數回填），結業對照 Z_INVENTORY_COST_REPORT | [ex13](ex13_capstone.md) | `ZR_TR13_CAPSTONE` | 完成 |
| 14 | INCLUDE 拆檔（TOP/F01 慣例、context 啟用） | [ex14](ex14_include_split.md) | `ZR_TR14_CAPSTONE` + `_TOP`/`_F01` | 完成 |
| 15 | Function Module（SE37 建立/單測、CALL FUNCTION 與例外） | [ex15](ex15_function_module.md) | `ZFG_TR15` / `Z_TR15_CALC_REVENUE` / `ZR_TR15_CALL_FM` | 完成 |

> - 本階段不含 OOP（Local Class / Method / cl_salv_table 等），留待 SAP OOP 課程。
> - 課程目標：完課後能獨立寫出並看懂 `Z_INVENTORY_COST_REPORT` 等級的傳統報表。

## 建議授課順序（題號 ≠ 順序）

**ex01 → … → ex12 → ex14（INCLUDE 拆檔）→ ex15（Function Module）→ ex13（期末綜合實作，最後做）**

ex14/ex15 是後來補的主題，題號在 13 之後，但期末實作 ex13 會用到兩者的技能（拆檔結構、呼叫 FM），請放在最後。SAP 端答案程式已依原題號命名（`ZR_TR13_CAPSTONE` 等），故不重編題號。
