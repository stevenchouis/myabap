# 基礎 ABAP Training 練習題

本目錄存放基礎 ABAP 教育訓練的練習題目與答案程式。

## 上課講義（lectures/）

每題另有對應的**上課講義**（重要觀念＋詳細語法＋範例）放在 [lectures/](lectures/README.md)，編號與題號一致（lec01 ↔ ex01）。授課流程：先講課（lecNN）→ 實作練習（exNN）→ 對照答案程式。講義 PDF 重產指令：`node tools/md2pdf.js src/ABAP_Training/lectures`。

## 講義 PDF

每份 `*.md` 都有對應的 `*.pdf` 講義。md 修改後在 repo 根目錄執行 `node tools/md2pdf.js` 重產（只重產有變更的；`--all` 全部重產），再 commit。

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
| 16 | Field-Symbol（ASSIGN/LOOP ASSIGNING/ASSIGN COMPONENT） | [ex16](ex16_field_symbols.md) | `ZR_TR16_FIELD_SYMBOLS` | 完成 |
| 17 | 運算與流程控制（IF/CASE/DO/WHILE/EXIT/CHECK） | [ex17](ex17_control_flow.md) | `ZR_TR17_CONTROL_FLOW` | 完成 |
| 18 | 字串與日期處理（CONCATENATE/SPLIT/位移/月初月末） | [ex18](ex18_string_date.md) | `ZR_TR18_STRING_DATE` | 完成 |
| 19 | Debugger 除錯（中斷點/單步/Watchpoint/ST22，附埋 bug 程式） | [ex19](ex19_debugging.md) | `ZR_TR19_DEBUGGING` | 完成 |
| 20 | Control Break 群組小計（AT NEW/AT END OF/SUM） | [ex20](ex20_control_break.md) | `ZR_TR20_CONTROL_BREAK` | 完成 |
| 21 | Z 資料表與 Open SQL 寫入（SE11/SM30/INSERT/UPDATE/MODIFY/DELETE、外鍵/Check Table、Search Help） | [ex21](ex21_ztable.md) | `ZTR21_STUD` + `ZTR21_CLASS` + `ZR_TR21_ZTABLE` | 完成 |
| 22 | Message Class 與多語言文字元素（SE91/Text Symbol/Selection Texts） | [ex22](ex22_texts_messages.md) | `ZTR22` + `ZR_TR22_TEXTS` | 完成 |
| 23 | 期末整合練習：訂單 Header/Detail（外鍵/Search Help 綜合運用、LUW all-or-nothing 實地驗證） | [ex23](ex23_orders.md) | `ZTR23_ORDH` + `ZTR23_ORDI` + `ZR_TR23_ORDERS` | 完成 |

> - 本階段不含 OOP（Local Class / Method / cl_salv_table 等），留待 SAP OOP 課程。
> - 課程目標：完課後能獨立寫出並看懂 `Z_INVENTORY_COST_REPORT` 等級的傳統報表。
> - ex17～ex22 的答案物件已於 2026-07-05 寫入 SAP（$TMP）並通過語法檢查，含 ex21 的 DDIC 三層件（Domain/DE `ZTR21_SCORE`、表 `ZTR21_STUD`，DDL 快照見 `ztr21_stud.tabl.abap`）與 ex22 的訊息類別 `ZTR22`（001–003）。
> - `ZR_TR22_TEXTS` 的 Text Symbols（001–003）／Selection Texts，以及 ex21 的 Table Maintenance Generator（SM30），已於 2026-07-05 在 SAP GUI 手動補齊（這兩項無法透過 ADT API 維護）。至此 ex17～ex22 全數完工。
> - ex21 於 2026-07-06 擴充 Header/Detail 關聯教學：新增 Domain/DE `ZTR21_KLASSE`、`ZTR21_KLNAME`、班級主檔表 `ZTR21_CLASS`（DDL 快照 `ztr21_class.tabl.abap`），`ZTR21_STUD` 加外鍵欄位 `KLASSE`（Check Table 指向 `ZTR21_CLASS`），程式補教學片段（外鍵只擋畫面輸入、不擋 Open SQL；JOIN 兩表複習）。Search Help `ZTR21_CLASSH` 與 `ZTR21_STUD` 的 SM30 維護畫面已於 SAP GUI 手動補齊確認，至此 ex21 全數完工。（過程中踩到一個坑：`ZTR21_CLASS-KLNAME` 一開始用內建型別 `CHAR(40)` 沒掛 Data Element，導致 Search Help 無法 Activate，已補建 DE `ZTR21_KLNAME` 修正，詳見 `.claude/rules/sap-adt-mcp.md` 第 10 節。）
> - 新增 ex23（2026-07-06）：期末整合練習「訂單 Header/Detail」，`ZTR23_ORDH`（訂單主檔）+ `ZTR23_ORDI`（訂單明細，`ORDNO` 同時是 Key 也是外鍵，比 ex21 更貼近 SAP 官方外鍵範例）+ 3 組 Domain/DE（`ZTR23_ORDNO`/`ZTR23_CUSTOMER`/`ZTR23_STATUS`，其中 `ZTR23_STATUS` 示範 Domain 固定值清單，跟 ex21 的區間值域是不同技巧）。程式 `ZR_TR23_ORDERS` 具體驗證 LUW all-or-nothing（Header+Detail 同一 LUW，中途失敗 ROLLBACK WORK 後連已成功的 Header 也一併消失）。Search Help `ZTR23_ORDHSH` 與 `ZTR23_ORDH` 的 SM30 維護畫面已於 SAP GUI 手動補齊確認，至此 ex23 全數完工，基礎課全部 23 題完課。

## 建議授課順序（題號 ≠ 順序）

**ex01 → ex02 → ex17（流程控制）→ ex18（字串日期）→ ex03 → ex04 → ex05 → ex19（除錯）→ ex16（Field-Symbol）→ ex06 → … → ex10 → ex22（訊息與文字元素）→ ex11 → ex20（群組小計）→ ex12 → ex14（INCLUDE 拆檔）→ ex15（Function Module）→ ex21（Z 資料表）→ ex13（期末綜合實作一）→ ex23（期末整合練習二，全課程最後一題）**

題號在 13 之後的主題都是後來補的，依主題插進對應位置授課，不重編題號（SAP 端答案程式依原題號命名）：ex17/ex18 是基本功，緊接變數宣告之後；ex19 除錯放在 internal table 之後（有足夠複雜度可供追蹤）；ex22 收攏 ex07 的 Selection Texts 伏筆與 ex10 首次登場的 MESSAGE；ex20 需要 JOIN 的資料、且是 ex12 列印排版的前置；ex21 需要 FM 觀念（SM30 的 function group）；期末實作 ex13 用到 ex14/ex15 技能；ex23 需要 ex21 的外鍵/Search Help 觀念才有意義，是全課程真正的最後一題，用「訂單 Header/Detail」把外鍵、Search Help、LUW 三條線收在一起。
