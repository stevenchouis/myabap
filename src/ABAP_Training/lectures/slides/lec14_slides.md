---
marp: true
theme: default
paginate: true
headingDivider: false
style: |
  section {
    font-family: 'Microsoft JhengHei', 'Noto Sans TC', sans-serif;
    font-size: 26px;
    padding: 60px;
  }
  section.lead {
    text-align: center;
    justify-content: center;
  }
  section.lead h1 { font-size: 56px; }
  code, pre {
    font-family: Consolas, 'Courier New', monospace;
  }
  pre {
    font-size: 21px;
    line-height: 1.45;
  }
  table { font-size: 23px; }
  section.compact pre { font-size: 19px; }
  section.compact table { font-size: 20px; }
  blockquote {
    border-left: 6px solid #0a6ed1;
    padding-left: 16px;
    color: #333;
    background: #eef6fc;
  }
  footer { color: #999; }
---

<!-- _class: lead -->
<!-- _paginate: false -->

# 講義 14
# INCLUDE 拆檔——TOP / F01 慣例

ABAP 基礎教育訓練

對應練習 ex14｜答案：`ZR_TR14_CAPSTONE` + `_TOP` / `_F01`

---

## 本講重點

- INCLUDE 的本質：**原地展開的程式碼片段**
  不是獨立可執行的程式
- 實務拆檔慣例：`_TOP`（宣告）、`_F01`（FORM）
- 主程式只剩骨架：一眼看懂整支程式
- 建立、啟用 INCLUDE 的注意事項

---

## 1. INCLUDE 的本質

程式一大（正式報表動輒上千行），單一檔案難維護：

```abap
REPORT zr_tr14_capstone.

INCLUDE zr_tr14_top.        " 展開：全域宣告
...
INCLUDE zr_tr14_f01.        " 展開：FORM 副程式
```

- 編譯時如同把 INCLUDE 的文字**貼進**該位置
  → 跟直接寫在主程式裡**完全等價**，拆檔是為了「人」
- INCLUDE 程式**不能單獨執行**、沒有自己的變數空間
- 同一個 INCLUDE 可被多支程式共用
  → **改共用 INCLUDE 前先 Where-Used**

---

## 2. 實務拆檔慣例

| 檔案 | 內容 | 命名 |
|---|---|---|
| 主程式 | REPORT、INCLUDE 清單、事件流程 | `ZXXX` |
| TOP include | TYPES / DATA / 選擇畫面 | `ZXXX_TOP` |
| FORM include | 所有 FORM 副程式 | `ZXXX_F01`（F02、F03…） |

本專案實例：`ZDQM0001` + `ZDQM0001F01`

---

## 拆完的主程式（就是全部）

```abap
REPORT zr_tr14_capstone.

INCLUDE zr_tr14_top.        " 全域宣告 + 選擇畫面

INITIALIZATION.
  t_b1 = '查詢條件'.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display_data.

* FORM 的 INCLUDE 放最後：插在事件中間會造成
* 後續程式碼 "statement not accessible"
INCLUDE zr_tr14_f01.        " FORM 副程式
```

**順序規則**（原地展開，位置就是一切）：
1. `_TOP` 放最前——宣告必須在使用之前
2. `_F01` 放最後——FORM 區塊會吃掉後面的事件

---

## 3. 建立方式（SE38）

1. 先建主程式，寫下 `INCLUDE zr_xxx_top.`
2. 語法檢查會問「INCLUDE 不存在，要建立嗎？」
   → 確認 → 系統帶你建 INCLUDE Program
3. 把宣告 / FORM 搬進對應 INCLUDE，主程式留骨架
4. **啟用要一起啟用**：主程式與所有 INCLUDE 都要 active

> INCLUDE 單獨檢查/啟用需要「主程式 context」
> 共用 INCLUDE 時選錯 context 會看到**假錯誤**
> （ADT / MCP 工具的對應注意事項見 `.claude/rules/sap-adt-mcp.md`）

---

## 4. 什麼該拆、什麼不該拆

- 幾十行的小程式**不用拆**——拆檔是為了大程式，不是儀式
- 判斷點：宣告區＋FORM 超過一兩百行、或多人同時維護
- 共用 INCLUDE 是「**隱形的耦合**」：
  新程式間要共用邏輯，優先 Function Module（下一講）
  或 Class，而不是共用 INCLUDE

---

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| "statement not accessible" | F01 後面還有事件程式碼——移到檔尾 |
| INCLUDE 裡變數「未宣告」 | 順序錯：TOP 必須先展開 |
| 單獨開 INCLUDE 檢查滿江紅 | 少了主程式 context |
| 改了共用 INCLUDE，別支程式壞了 | 先 Where-Used 再動手 |
| INCLUDE 按 F8 沒反應 | 它本來就不可執行，執行主程式 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex14**：

把之前完成的報表拆成
主程式＋`_TOP`＋`_F01` 三支

驗證行為與拆檔前完全一致
