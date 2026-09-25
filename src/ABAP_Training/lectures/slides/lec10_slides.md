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

ABAP 基礎教育訓練（授課順序：接在講義 15 之後）

對應練習 ex10｜答案程式 `ZR_TR10_EVENTS`

---

## 本講重點

- Report 程式的真相：**不是從上跑到下，而是事件驅動**
- 事件時序：INITIALIZATION → AT SELECTION-SCREEN
  → START-OF-SELECTION → END-OF-SELECTION
- 清單事件：TOP-OF-PAGE / END-OF-PAGE
- **清單緩衝區（List Buffer）**：WRITE 先寫進記憶體
- 互動清單：AT LINE-SELECTION 與 **HIDE**（隱藏區、寫回時機、使用規則）
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

<!-- _class: compact -->

## 3.5 清單緩衝區（List Buffer）

`WRITE`／`ULINE`／`SKIP` 先寫進記憶體的**清單緩衝區**，不是即時上螢幕

| 清單 | 寫進緩衝區 | 顯示到畫面 |
|---|---|---|
| 基本清單（`sy-lsind` 0） | START-／END-OF-SELECTION、TOP-OF-PAGE | 這些事件**全部跑完**後 |
| 明細清單（1、2…） | AT LINE-SELECTION | 事件**跑完**後 |

裡面有：每一行的**文字**、**分頁資訊**、**隱藏區**（HIDE 的值）
每一層清單各一份；F3 退回上一層直接從緩衝區重顯，不重跑程式

| 能回頭處理已寫好的行 | 在哪一講 |
|---|---|
| `HIDE`：雙擊時寫回變數 | 本講第 4 節 |
| `READ LINE`：讀回 `sy-lisel`（也寫回 HIDE 值） | 講義 13 |
| `MODIFY LINE`：改完寫回（總頁數回填） | 講義 13 |

---

## 4. 為什麼需要 HIDE

`WRITE` 到畫面後，清單只是**文字**，跟 internal table 沒關係了

- 雙擊第 3 行：系統只知道「第 3 行被點」，不知道是哪位學生
- 此時 `gs_student` 放的是迴圈最後一筆，不是被點的那筆

→ 輸出時要替每一行**另外記下鍵值**：這就是 `HIDE`

```abap
HIDE 變數.
HIDE: 變數1, 變數2.        " 可同時記多個
```

把「變數**當下**的值」綁到「**目前這一行**」，存進這層清單的**隱藏區（Hide Area）**

---

<!-- _class: compact -->

## 4.1 隱藏區（Hide Area）是什麼

緩衝區（3.5）裡跟 HIDE 有關的兩部分：

| 清單緩衝區的兩部分 | 內容 | 看得到嗎 |
|---|---|---|
| 清單內容 | 每一行 `WRITE` 的文字 | 看得到 |
| **隱藏區** | 每一行 `HIDE` 的「變數＋當時的值」 | **看不到** |

兩者依**行號**對應——想成**每一行背面貼一張便利貼**：

- `WRITE`：寫在正面給使用者看
- `HIDE gs_student-id`：背面貼「`gs_student-id = S0002`」
- 雙擊 → 翻到背面，把 `'S0002'` 寫回變數 → 執行 `AT LINE-SELECTION`
- 頁首、分隔線沒便利貼 → 什麼都不寫回

**每一層清單各有一份**：明細層再 HIDE 不會蓋掉基本清單；返回上一層，便利貼還在

---

<!-- _class: compact -->

## 4.2 隱藏區長什麼樣、何時寫回

| 清單行（看得到） | 隱藏區（看不到） |
|---|---|
| `S0001 王小明  78  91` | `gs_student-id = 'S0001'` |
| `S0002 李小美  88  95` | `gs_student-id = 'S0002'` |
| `S0003 陳大文  60  72` | `gs_student-id = 'S0003'` |
| 頁首、`ULINE`、合計行 | （沒有 HIDE，什麼都沒存） |

雙擊 `S0002` 那行 →
1. 系統先把 `'S0002'` **寫回** `gs_student-id`
2. 再觸發 `AT LINE-SELECTION`
3. 程式用 `gs_student-id` 去 `READ TABLE` 找明細
4. 明細 `WRITE` 到**新的一層清單**（`sy-lsind` = 1），F3 返回

---

<!-- _class: compact -->

## 4.3 完整範例

```abap
LOOP AT gt_students INTO gs_student WHERE score1 IN s_score.
  WRITE: / gs_student-id, gs_student-name, gs_student-score1.
  HIDE gs_student-id.               " 緊接在 WRITE 之後
ENDLOOP.
CLEAR gs_student-id.                " 清掉迴圈留下的最後一筆

AT LINE-SELECTION.
  IF gs_student-id IS INITIAL.      " 點到沒 HIDE 的行
    WRITE / '請雙擊資料行'.
  ELSE.
    READ TABLE gt_students INTO gs_detail WITH KEY id = gs_student-id.
    IF sy-subrc = 0.
      WRITE: / '=== 學生明細（第', sy-lsind, '層清單）===',
             / '學號：', gs_detail-id,
             / '姓名：', gs_detail-name.
    ENDIF.
  ENDIF.
```

---

<!-- _class: compact -->

## 4.4 HIDE 使用規則

1. **緊接在 `WRITE` 之後**：綁的是游標所在行；寫在前面會綁到上一行
2. **只能 HIDE 全域變數**：FORM 的區域變數 → dump `HIDE_NO_LOCAL`
3. **只能 HIDE 平面型別**：欄位或全欄位結構；不能 internal table、`string`
   實務只 HIDE **鍵值**，明細在事件裡再查
4. **只有 HIDE 過的變數會寫回**：點到沒 HIDE 的行，變數仍是最後一筆
   → 輸出完 `CLEAR`，事件裡檢查 `IS INITIAL`
5. **鍵值要能唯一識別**：航班要 HIDE `carrid`、`connid`、`fldate`

> 實測：HIDE 寫在 WRITE 前，雙擊 S0001 取回 S0002（下一筆）；
> 沒 HIDE 的行，變數保留**上一次雙擊**的值

| 系統欄位 | 意義 |
|---|---|
| `sy-lsind` | 清單層級（基本 0、明細 1…最多 20） |
| `sy-lilli` | 被雙擊的是第幾行 |
| `sy-lisel` | 被雙擊那行的畫面文字（不要拿來切字串取鍵值） |

---

## 4.5 多層清單、串到另一支報表

- 在 `AT LINE-SELECTION` 輸出明細時**再 HIDE**，就能在明細上再雙擊往下鑽
  每一層清單有自己的隱藏區
- 明細已有現成報表 → 用 HIDE 取回的鍵值呼叫它：

```abap
AT LINE-SELECTION.
  IF gs_student-id IS NOT INITIAL.
    SUBMIT zr_student_detail          " 另一支報表
      WITH p_id = gs_student-id       " 對方的 PARAMETERS p_id
      AND RETURN.                     " 看完回到本清單
  ENDIF.
```

- 沒加 `VIA SELECTION-SCREEN` → 對方選擇畫面**跳過**，直接顯示清單
- `AND RETURN` → F3 回到本清單（已實測）

**關鍵都一樣：靠 HIDE 知道使用者點的是哪一筆**

---

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| INITIALIZATION 預設值沒出現 | 事件名拼錯（被歸入 START-OF-SELECTION） |
| 驗證訊息跳完程式照跑 | TYPE 用了 `I`/`S`——擋人要用 `E` |
| 雙擊任何行都顯示同一筆 | 忘了 HIDE，變數殘留最後一筆 |
| 顯示的是上一行的資料 | `HIDE` 寫在 `WRITE` 之前 |
| dump `HIDE_NO_LOCAL` | HIDE 了 FORM 的區域變數 |
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
