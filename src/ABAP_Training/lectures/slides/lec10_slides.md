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

# 講義 10
# Report Event——事件流程與互動清單

ABAP 基礎教育訓練

對應練習 ex10｜答案程式 `ZR_TR10_EVENTS`

---

## 本講重點

- Report 程式的真相：**不是從上跑到下，而是事件驅動**
- 事件時序：INITIALIZATION → AT SELECTION-SCREEN
  → START-OF-SELECTION → END-OF-SELECTION
- 清單事件：TOP-OF-PAGE / END-OF-PAGE
- 互動清單：AT LINE-SELECTION 與 HIDE 機制、`sy-lsind`
- `MESSAGE` 訊息類型

---

## 1. 事件驅動：位置無關，時機決定

程式由「事件區塊」組成：事件關鍵字到下一個事件關鍵字之間的程式碼屬於該事件，**由系統在對應時機呼叫**

- 跟寫在檔案裡的先後順序**完全無關**
- TOP-OF-PAGE 寫在最後面，照樣在每頁開頭執行

> 隱含規則：開頭第一段「不屬於任何事件」的程式碼
> 隱含屬於 START-OF-SELECTION
> → 初學建議**一律明寫**事件關鍵字

---

## 2. 事件時序總表

| 順序 | 事件 | 觸發時機 | 典型用途 |
|---|---|---|---|
| 1 | `LOAD-OF-PROGRAM` | 程式載入 | 少用 |
| 2 | `INITIALIZATION` | 選擇畫面**之前** | 預設值、框標題 |
| 3 | `AT SELECTION-SCREEN OUTPUT` | 畫面每次顯示前 | 動態調畫面 |
| 4 | `AT SELECTION-SCREEN` | 按執行後、主邏輯**前** | **驗證輸入** |
| 5 | `START-OF-SELECTION` | 驗證通過後 | **主處理** |
| 6 | `END-OF-SELECTION` | 主處理結束 | 總結、合計 |
| - | `TOP-OF-PAGE` | 每頁開頭（WRITE 觸發） | 頁首、表頭 |
| - | `END-OF-PAGE` | 到達保留行區 | 頁尾 |
| - | `AT LINE-SELECTION` | 雙擊清單行 | 互動明細 |

---

## 3. INITIALIZATION 與輸入驗證

```abap
INITIALIZATION.
  t_b1 = '查詢條件'.                 " BLOCK 框標題
  gs_score-sign   = 'I'.            " SELECT-OPTIONS 預設 0~100
  gs_score-option = 'BT'.
  gs_score-low    = 0.
  gs_score-high   = 100.
  APPEND gs_score TO s_score.

AT SELECTION-SCREEN.
  LOOP AT s_score INTO gs_score.
    IF gs_score-low < 0 OR gs_score-high > 999.
      MESSAGE '成績範圍請輸入 0～999' TYPE 'E'.
    ENDIF.
  ENDLOOP.
```

`TYPE 'E'` 在此事件的效果：顯示錯誤、**把使用者留在選擇畫面**

---

## MESSAGE 訊息類型速覽

| TYPE | 效果 |
|---|---|
| `I` | 彈窗訊息，按確定繼續 |
| `S` | 狀態列訊息，不中斷 |
| `W` | 警告（選擇畫面上可按 Enter 硬過） |
| `E` | 錯誤：**擋在選擇畫面** |
| `A` | 中止：程式直接結束 |

> 訊息「內容」與「型別」是分開的：
> 同一句話用 E 是擋人、用 S 只是通知
> （訊息內容集中管理 → Message Class，講義 22）

---

## TOP-OF-PAGE：每頁表頭

```abap
TOP-OF-PAGE.
  WRITE: / '學生成績清單（雙擊任一行看明細）'.
  ULINE.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display_data.

END-OF-SELECTION.
  ULINE.
  WRITE: / '符合條件筆數：', gv_count.
```

> 觸發者是「**輸出**」：該頁第一個 WRITE 執行時
> 系統先跑 TOP-OF-PAGE；一行都沒輸出就不會有頁首
> （分頁與 END-OF-PAGE 細節 → 講義 12）

---

## 4. 互動清單：HIDE 機制

需求：雙擊某行看明細——程式怎麼知道那行是哪筆？

```abap
* 輸出時：把這一行的鍵值「藏」進該行
LOOP AT gt_students INTO gs_student.
  WRITE: / gs_student-id, gs_student-name, gs_student-score1.
  HIDE gs_student-id.               " 這行清單暗中記住學號
ENDLOOP.
CLEAR gs_student-id.                " 防呆：雙擊非資料行時不撈殘留值

* 雙擊時：系統把該行 HIDE 的值還原回同名變數
AT LINE-SELECTION.
  IF gs_student-id IS INITIAL.
    WRITE / '請雙擊資料行'.
  ELSE.
    READ TABLE gt_students INTO gs_detail
         WITH KEY id = gs_student-id.
    WRITE: / '=== 明細（第', sy-lsind, '層清單）==='.
  ENDIF.
```

---

## HIDE 機制整理

1. `HIDE 變數.`：輸出目前行時，記下「這一行 ↔ 變數當時的值」
2. 雙擊某行 → 系統把該行 HIDE 的值**塞回同名變數**
   → 觸發 AT LINE-SELECTION
3. `sy-lsind`：清單層級（基本清單 0，明細 1，最多 20 層）
   事件裡的 WRITE 輸出到**新的一層**，返回鍵一層層退
4. 雙擊「沒 HIDE 過的行」不會還原任何值
   → 輸出完要 CLEAR ＋ 事件裡檢查 IS INITIAL

---

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| INITIALIZATION 預設值沒出現 | 事件名拼錯（被歸入 START-OF-SELECTION） |
| 驗證訊息跳完程式照跑 | TYPE 用了 `I`/`S`——擋人要用 `E` |
| 雙擊任何行都顯示同一筆 | 忘了 HIDE，變數殘留最後一筆 |
| 雙擊空白行出現殘留資料 | 沒 CLEAR + 沒檢查 IS INITIAL |
| TOP-OF-PAGE 沒執行 | 該頁沒有任何 WRITE |
| 程式碼寫在事件關鍵字之前 | 隱含屬於 START-OF-SELECTION |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex10**：

完整走一遍六個事件——
預設範圍、輸入驗證、主處理、總結、
頁首、雙擊明細（HIDE + sy-lsind）
