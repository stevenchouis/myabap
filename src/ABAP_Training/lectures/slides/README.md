# 基礎 ABAP 課程投影片（slides）

本目錄是各講的投影片，依授課順序排列（與 [../README.md](../README.md) 講義清單的「順序」一致）。每講三種格式：

- `.md`：投影片原稿（Marp 語法），修改內容改這個檔
- `.html`：瀏覽器直接開啟播放
- `.pptx`：PowerPoint 版

修改 `.md` 後，在專案根目錄執行 `node tools/md2slides.js` 重新產生 `.html` 與 `.pptx`。

| 順序 | 講義 | 主題 | 投影片 |
|---|---|---|---|
| 0 | [lec00](../lec00_sap_overview.md) | SAP / ERP 背景知識：模組、角色分工、系統架構 | [html](lec00_slides.html)／[pptx](lec00_slides.pptx)／[md](lec00_slides.md) |
| 0a | [lec00a](../lec00a_gui_workbench.md) | 環境準備：SAP GUI 安裝登入、ABAP Workbench 導覽 | [html](lec00a_slides.html)／[pptx](lec00a_slides.pptx)／[md](lec00a_slides.md) |
| 1 | [lec01](../lec01_syntax_basics.md) | 語法基礎：statement、句點、註解、鏈式寫法 | [html](lec01_slides.html)／[pptx](lec01_slides.pptx)／[md](lec01_slides.md) |
| 2 | [lec02](../lec02_type_like.md) | 變數與 TYPE / LIKE / CONSTANTS | [html](lec02_slides.html)／[pptx](lec02_slides.pptx)／[md](lec02_slides.md) |
| 3 | [lec17](../lec17_control_flow.md) | 運算與流程控制：IF / CASE / DO / WHILE / CHECK | [html](lec17_slides.html)／[pptx](lec17_slides.pptx)／[md](lec17_slides.md) |
| 4 | [lec18](../lec18_string_date.md) | 字串與日期處理：CONCATENATE / SPLIT / 位移 | [html](lec18_slides.html)／[pptx](lec18_slides.pptx)／[md](lec18_slides.md) |
| 5 | [lec03](../lec03_structures.md) | Local Type 與 Structure | [html](lec03_slides.html)／[pptx](lec03_slides.pptx)／[md](lec03_slides.md) |
| 6 | [lec04](../lec04_itab_basics.md) | Internal Table 基礎：APPEND / LOOP / READ TABLE | [html](lec04_slides.html)／[pptx](lec04_slides.pptx)／[md](lec04_slides.md) |
| 7 | [lec05](../lec05_itab_advanced.md) | Internal Table 進階：SORT / MODIFY / DELETE | [html](lec05_slides.html)／[pptx](lec05_slides.pptx)／[md](lec05_slides.md) |
| 8 | [lec19](../lec19_debugging.md) | 除錯 Debugger：中斷點、單步、Watchpoint、ST22 | [html](lec19_slides.html)／[pptx](lec19_slides.pptx)／[md](lec19_slides.md) |
| 9 | [lec16](../lec16_field_symbols.md) | Field-Symbol：ASSIGN / LOOP ASSIGNING | [html](lec16_slides.html)／[pptx](lec16_slides.pptx)／[md](lec16_slides.md) |
| 10 | [lec06](../lec06_sap_table.md) | 讀 SAP Table：航班模型與 SELECT | [html](lec06_slides.html)／[pptx](lec06_slides.pptx)／[md](lec06_slides.md) |
| 11 | [lec07](../lec07_selscreen.md) | 選擇畫面：PARAMETERS / SELECT-OPTIONS / IN | [html](lec07_slides.html)／[pptx](lec07_slides.pptx)／[md](lec07_slides.md) |
| 12 | [lec25](../lec25_ddic_overview.md) | Data Dictionary 總覽與 Global Type：重用標準型別、Check Table 指向標準表 | [html](lec25_slides.html)／[pptx](lec25_slides.pptx)／[md](lec25_slides.md) |
| 13 | [lec08a](../lec08a_package_transport.md) | Package 與傳輸請求：SE80 建 Package、SE10 Request/Task 與釋放順序、TR 與版本、釋放後再修改掛新 TR、STMS 匯入佇列 | [html](lec08a_slides.html)／[pptx](lec08a_slides.pptx)／[md](lec08a_slides.md) |
| 14 | [lec08](../lec08_modularize.md) | 模組化：FORM / USING / CHANGING（補充：Subroutine Pool 與跨程式 PERFORM） | [html](lec08_slides.html)／[pptx](lec08_slides.pptx)／[md](lec08_slides.md) |
| 15 | [lec15](../lec15_function_module.md) | Function Module：SE37 與 CALL FUNCTION | [html](lec15_slides.html)／[pptx](lec15_slides.pptx)／[md](lec15_slides.md) |
| 16 | [lec10](../lec10_events.md) | Report Event：事件流程與互動清單 | [html](lec10_slides.html)／[pptx](lec10_slides.pptx)／[md](lec10_slides.md) |
| 17 | [lec22](../lec22_texts_messages.md) | Message Class 與多語言文字元素：SE91 / Text Symbol | [html](lec22_slides.html)／[pptx](lec22_slides.pptx)／[md](lec22_slides.md) |
| 18 | [lec11](../lec11_join.md) | 多表 JOIN 與 CORRESPONDING FIELDS | [html](lec11_slides.html)／[pptx](lec11_slides.pptx)／[md](lec11_slides.md) |
| 19 | [lec20](../lec20_control_break.md) | Control Break 群組小計：AT NEW / AT END OF / SUM | [html](lec20_slides.html)／[pptx](lec20_slides.pptx)／[md](lec20_slides.md) |
| 19a | [lec20a](../lec20a_sql_aggregate.md) | SQL 聚合與子查詢：GROUP BY / HAVING / DISTINCT / 子查詢（傳統寫法） | [html](lec20a_slides.html)／[pptx](lec20a_slides.pptx)／[md](lec20a_slides.md) |
| 20 | [lec12](../lec12_print_layout.md) | 列印排版與頁面規劃 | [html](lec12_slides.html)／[pptx](lec12_slides.pptx)／[md](lec12_slides.md) |
| 21 | [lec14](../lec14_include_split.md) | INCLUDE 拆檔：TOP / F01 慣例 | [html](lec14_slides.html)／[pptx](lec14_slides.pptx)／[md](lec14_slides.md) |
| 22 | [lec13](../lec13_capstone.md) | 第一階段總整理（傳統報表收尾）：完整報表架構與實作攻略 | [html](lec13_slides.html)／[pptx](lec13_slides.pptx)／[md](lec13_slides.md) |
| 23 | [lec09](../lec09_alv.md) | Functional ALV 與 MACRO；進階篇（第 8 節起）：REUSE_ALV_GRID_DISPLAY_LVC 可編輯 ALV、STYLEFNAME 反灰、EDT_CLL_CB/DATA_CHANGED | [html](lec09_slides.html)／[pptx](lec09_slides.pptx)／[md](lec09_slides.md) |
| 24 | [lec21](../lec21_ztable.md) | 建立 Z 資料表與 Open SQL 寫入：SE11 / SM30 | [html](lec21_slides.html)／[pptx](lec21_slides.pptx)／[md](lec21_slides.md) |
| 25 | [lec27](../lec27_lock_object.md) | 並行控制與 Lock Object：SE11 建自訂 Lock Object、ENQUEUE/DEQUEUE FM、SM12 | [html](lec27_slides.html)／[pptx](lec27_slides.pptx)／[md](lec27_slides.md) |
| 26 | [lec28](../lec28_auth_wrapper.md) | 進階選修：客製 Table Maintenance 的權限防護與並行控制——SU21 自訂權限物件、Lock Object 鎖定範圍粗於主鍵、VIEW_MAINTENANCE_CALL、SE93 T-code、App bar 按鈕 CALL TRANSACTION | [html](lec28_slides.html)／[pptx](lec28_slides.pptx)／[md](lec28_slides.md) |
| 27 | [lec23](../lec23_orders.md) | 期末整合練習：訂單 Header/Detail、外鍵/Search Help/LUW 綜合運用 | [html](lec23_slides.html)／[pptx](lec23_slides.pptx)／[md](lec23_slides.md) |
| 28 | [lec26](../lec26_modern_syntax.md) | 進階選修：新式語法總覽——字串模板／New Open SQL Inline Declaration／COND／SWITCH／VALUE／REDUCE／FILTER | [html](lec26_slides.html)／[pptx](lec26_slides.pptx)／[md](lec26_slides.md) |
