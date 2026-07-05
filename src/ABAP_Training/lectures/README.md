# 基礎 ABAP 上課講義（lectures）

本目錄是基礎 ABAP 教育訓練的**上課講義**：每講涵蓋重要觀念、詳細語法與完整範例，與上層目錄的練習題（`exNN`）一一對應——先講課（lecNN）、再實作（exNN）、最後對答案（`zr_trNN_*.prog.abap`）。

## 講義清單（依授課順序排列）

| 順序 | 講義 | 主題 | 對應練習 |
|---|---|---|---|
| 0 | [lec00](lec00_sap_overview.md) | SAP / ERP 背景知識：模組、角色分工、系統架構 | （無，觀念課） |
| 0a | [lec00a](lec00a_gui_workbench.md) | 環境準備：SAP GUI 安裝登入、ABAP Workbench 導覽 | （無，環境課） |
| 1 | [lec01](lec01_syntax_basics.md) | 語法基礎：statement、句點、註解、鏈式寫法 | [ex01](../ex01_syntax_basics.md) |
| 2 | [lec02](lec02_type_like.md) | 變數與 TYPE / LIKE / CONSTANTS | [ex02](../ex02_type_like.md) |
| 3 | [lec17](lec17_control_flow.md) | 運算與流程控制：IF / CASE / DO / WHILE / CHECK | [ex17](../ex17_control_flow.md) |
| 4 | [lec18](lec18_string_date.md) | 字串與日期處理：CONCATENATE / SPLIT / 位移 | [ex18](../ex18_string_date.md) |
| 5 | [lec03](lec03_structures.md) | Local Type 與 Structure | [ex03](../ex03_structures.md) |
| 6 | [lec04](lec04_itab_basics.md) | Internal Table 基礎：APPEND / LOOP / READ TABLE | [ex04](../ex04_itab_basics.md) |
| 7 | [lec05](lec05_itab_advanced.md) | Internal Table 進階：SORT / MODIFY / DELETE | [ex05](../ex05_itab_advanced.md) |
| 8 | [lec19](lec19_debugging.md) | 除錯 Debugger：中斷點、單步、Watchpoint、ST22 | [ex19](../ex19_debugging.md) |
| 9 | [lec16](lec16_field_symbols.md) | Field-Symbol：ASSIGN / LOOP ASSIGNING | [ex16](../ex16_field_symbols.md) |
| 10 | [lec06](lec06_sap_table.md) | 讀 SAP Table：航班模型與 SELECT | [ex06](../ex06_sap_table.md) |
| 11 | [lec07](lec07_selscreen.md) | 選擇畫面：PARAMETERS / SELECT-OPTIONS / IN | [ex07](../ex07_selscreen.md) |
| 12 | [lec08](lec08_modularize.md) | 模組化：FORM / USING / CHANGING | [ex08](../ex08_modularize.md) |
| 13 | [lec09](lec09_alv.md) | Functional ALV 與 MACRO | [ex09](../ex09_alv.md) |
| 14 | [lec10](lec10_events.md) | Report Event：事件流程與互動清單 | [ex10](../ex10_events.md) |
| 15 | [lec22](lec22_texts_messages.md) | Message Class 與多語言文字元素：SE91 / Text Symbol | [ex22](../ex22_texts_messages.md) |
| 16 | [lec11](lec11_join.md) | 多表 JOIN 與 CORRESPONDING FIELDS | [ex11](../ex11_join.md) |
| 17 | [lec20](lec20_control_break.md) | Control Break 群組小計：AT NEW / AT END OF / SUM | [ex20](../ex20_control_break.md) |
| 18 | [lec12](lec12_print_layout.md) | 列印排版與頁面規劃 | [ex12](../ex12_print_layout.md) |
| 19 | [lec14](lec14_include_split.md) | INCLUDE 拆檔：TOP / F01 慣例 | [ex14](../ex14_include_split.md) |
| 20 | [lec15](lec15_function_module.md) | Function Module：SE37 與 CALL FUNCTION | [ex15](../ex15_function_module.md) |
| 21 | [lec21](lec21_ztable.md) | 建立 Z 資料表與 Open SQL 寫入：SE11 / SM30 | [ex21](../ex21_ztable.md) |
| 22 | [lec13](lec13_capstone.md) | 期末總整理：完整報表架構與實作攻略 | [ex13](../ex13_capstone.md) |
| 23 | [lec23](lec23_orders.md) | 期末整合練習二：訂單 Header/Detail、外鍵/Search Help/LUW 綜合運用 | [ex23](../ex23_orders.md) |

> 講義編號跟練習題號一致（lec16 對 ex16），所以授課順序不等於編號順序：流程控制/字串（lec17/18）緊接變數之後、除錯（lec19）在 internal table 之後、Field-Symbol（lec16）接在除錯之後、訊息與文字元素（lec22）緊接事件講次收攏 MESSAGE 與 Selection Texts、群組小計（lec20）在 JOIN 與列印排版之間、Z 資料表（lec21）在 FM 之後，期末總整理（lec13）在此之後，訂單 Header/Detail（lec23）需要 lec21 的外鍵/Search Help 觀念，是全課程真正的最後一講。

## 使用方式

- 每講建議 60～90 分鐘：講觀念與語法（投影講義）→ 帶著做範例 → 學員自行完成對應練習題。
- 範例程式碼都可以直接貼進 SE38 的 `$TMP` 測試程式執行（少數需要航班測試資料，先跑一次報表 `SAPBC_DATA_GENERATOR`）。
- md 修改後在 repo 根目錄執行 `node tools/md2pdf.js src/ABAP_Training/lectures` 重產 PDF 講義。

## 課程定位

- 目標：完課後能獨立寫出並看懂 `Z_INVENTORY_COST_REPORT` 等級的傳統報表程式。
- 範圍：傳統報表寫法（WRITE 清單、FORM、Functional ALV）；OOP（Class / Method / `cl_salv_table`）留待 OOP 課程（`src/ABAP_Training_OOP/`）。
- 語法風格：以課堂系統實際可跑的傳統語法為主，新語法（7.40 之後的行內宣告等）在相關講次以「對照」方式帶到。
