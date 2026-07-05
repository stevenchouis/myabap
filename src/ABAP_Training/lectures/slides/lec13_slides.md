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

# 講義 13
# 期末總整理——完整報表架構與實作攻略

ABAP 基礎教育訓練（最後一講）

對應練習 ex13｜答案程式 `ZR_TR13_CAPSTONE`

---

## 本講重點

- 把 15 講的技能拼成**一支正式等級的傳統報表**
- 完整報表的標準架構與撰寫順序
- 唯一的新技巧：**總頁數回填**（READ LINE / MODIFY LINE）
- 實作攻略與自我檢查清單
- 結業對照：讀懂正式程式 `Z_INVENTORY_COST_REPORT`

---

## 1. 期末目標：航班營收報表

選擇畫面過濾 → JOIN 取數 → 計算營收
→ 132 欄分頁排版 → 頁首頁尾 → 頁次「n / 總頁數」

**這正是實務傳統報表的完整形狀**
完成它 = 具備獨立接報表需求的能力

---

<!-- _class: compact -->

## 2. 完整報表架構（技能總地圖）

```abap
REPORT zr_tr13_capstone NO STANDARD PAGE HEADING
                        LINE-SIZE 132
                        LINE-COUNT 65(3).          " ← 講義 12
TABLES sflight.                                    " ← SELECT-OPTIONS 參考用

TYPES: BEGIN OF ty_rev, ... END OF ty_rev.         " ← 講義 3
DATA: gt_rev TYPE STANDARD TABLE OF ty_rev, ...    " ← 講義 4

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.   " ← 講義 7
  SELECT-OPTIONS: s_carrid FOR sflight-carrid,
                  s_fldate FOR sflight-fldate.
  PARAMETERS p_zero AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.                                    " ← 講義 10
  t_b1 = '查詢條件'.

START-OF-SELECTION.
  PERFORM get_data.                                " ← 講義 8
  PERFORM display_data.

END-OF-SELECTION.
  PERFORM update_total_pages.                      " ← 本講新技巧

TOP-OF-PAGE.                                       " ← 講義 12
END-OF-PAGE.
* FORM 區集中檔尾（正式版再依講義 14 拆 _TOP/_F01）
```

---

## 各 FORM 用到的技能

| FORM | 內容 | 講義 |
|---|---|---|
| `get_data` | INNER JOIN、IN 過濾、DELETE WHERE、LOOP 算營收＋MODIFY | 11、7、5 |
| `display_data` | 空表防呆、固定座標 WRITE、CURRENCY、合計 | 4、12 |
| `update_total_pages` | 總頁數回填 | **本講** |

---

## 3. 新技巧：總頁數回填

頁首要印「頁次 3 / 12」，但印第 3 頁時總頁數還不知道

**解法**：WRITE 先寫進 **List Buffer**，不是直接上螢幕
END-OF-SELECTION 時全部頁面已生成，`sy-pagno` = 總頁數
→ 回頭把每頁頁首的佔位字串改掉

```abap
* 頁首先印佔位符（TOP-OF-PAGE 內）：
WRITE: ... '頁次　　：', (3) sy-pagno NO-GAP, '/', '###'.

* 全部輸出完（END-OF-SELECTION）再回填：
FORM update_total_pages.
  DATA lv_total TYPE c LENGTH 3.
  lv_total = sy-pagno.                  " 此刻頁次 = 總頁數
  DO sy-pagno TIMES.
    READ LINE 2 OF PAGE sy-index.       " 讀回 → sy-lisel
    IF sy-subrc = 0.
      REPLACE '###' WITH lv_total INTO sy-lisel.
      MODIFY LINE 2 OF PAGE sy-index.   " 改完寫回 buffer
    ENDIF.
  ENDDO.
ENDFORM.
```

---

## 回填的三個要點

1. `READ LINE n OF PAGE p`：把第 p 頁第 n 行讀進 `sy-lisel`
2. `MODIFY LINE`：把改好的 `sy-lisel` 寫回同一行
3. 佔位符（`###`）要選**內容裡不會自然出現**的字串
   行號要跟頁首版型一致（範例中「頁次」在第 2 行）

---

## 4. 實作攻略（建議順序）

1. **先讓資料對**：宣告＋選擇畫面＋get_data
   用最陽春的 LOOP + WRITE 驗證 JOIN 與營收計算
   → 資料錯，排版再漂亮都是白工
2. **再排版**：畫欄位座標表，完成明細行與頁首標題
3. **再分頁**：加 LINE-COUNT 與 END-OF-PAGE，足量資料驗證
4. **最後回填總頁數**：頁首版型固定後才做
5. 全程鐵律：每個 SELECT / READ TABLE / CALL FUNCTION
   之後檢查 `sy-subrc`；查無資料要有友善訊息

---

## 5. 自我檢查清單（結業標準）

- ☐ 選擇畫面有 BLOCK 框與標題，條件全部生效
- ☐ JOIN 一次取數，**沒有迴圈內 SELECT**
- ☐ 營收計算正確（票價 × 已售座位，金額含幣別格式）
- ☐ 每頁頁首頁尾齊全、直欄筆直、跨頁正常
- ☐ 總頁數回填正確（每一頁顯示相同總頁數）
- ☐ 主流程只有 PERFORM；命名符合 gv_/gs_/gt_ 慣例
- ☐ 查無資料、輸入錯誤都有明確訊息，不會 dump

---

## 6. 結業對照：讀正式程式

打開 `Z_INVENTORY_COST_REPORT`（或 ZDQM 系列）對照閱讀：

結構跟你的期末作品**一模一樣**——
宣告（或 _TOP include）、選擇畫面、事件骨架、
FORM 區、分頁排版。差別只在業務邏輯的複雜度

**讀得懂、指得出每一段對應哪一講 → 本課程結業**

下一階段：OOP 課程（`src/ABAP_Training_OOP/`）
把同樣的邏輯改用 Class 組織

---

<!-- _class: lead -->

# 期末實作

完成 **ex13**：獨立完成航班營收報表

建議先不看答案程式，卡住時回查對應講義

完成後與 `zr_tr13_capstone` 對照，
比較自己與範本的取捨差異
