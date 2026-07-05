# 講義 10：Report Event——事件流程與互動清單

> 對應練習：[ex10](../ex10_events.md)｜答案程式：`ZR_TR10_EVENTS`

## 本講重點

- Report 程式的真相：**不是從上跑到下，而是事件驅動**
- 事件時序：INITIALIZATION → AT SELECTION-SCREEN → START-OF-SELECTION → END-OF-SELECTION
- 清單事件：TOP-OF-PAGE / END-OF-PAGE
- 互動清單：AT LINE-SELECTION 與 HIDE 機制、`sy-lsind`
- `MESSAGE` 訊息類型

## 1. 事件驅動：位置無關，時機決定

Report 程式由一塊塊「事件區塊」組成：事件關鍵字出現到下一個事件關鍵字（或 FORM 區）之前的程式碼屬於該事件，**由系統在對應時機呼叫**，跟寫在檔案裡的先後順序完全無關。你可以把 TOP-OF-PAGE 寫在最後面，它照樣在每頁開頭執行。

> 隱含規則：程式開頭第一段「不屬於任何事件」的可執行程式碼，隱含屬於 START-OF-SELECTION。初學建議一律明寫事件關鍵字，不靠隱含。

## 2. 事件時序總表

| 順序 | 事件 | 觸發時機 | 典型用途 |
|---|---|---|---|
| 1 | `LOAD-OF-PROGRAM` | 程式載入（最早） | 少用，先認識 |
| 2 | `INITIALIZATION` | 選擇畫面顯示**之前** | 給選擇畫面預設值、框標題 |
| 3 | `AT SELECTION-SCREEN OUTPUT` | 選擇畫面每次顯示前 | 動態調整畫面（進階） |
| 4 | `AT SELECTION-SCREEN` | 使用者按執行後、主邏輯**之前** | **驗證輸入**，擋下錯誤條件 |
| 5 | `START-OF-SELECTION` | 驗證通過後 | **主處理**：取數、加工、輸出 |
| 6 | `END-OF-SELECTION` | 主處理結束 | 總結、合計、（期末）總頁數回填 |
| - | `TOP-OF-PAGE` | 基本清單每頁開頭（由該頁第一個 WRITE 觸發） | 頁首、表頭 |
| - | `END-OF-PAGE` | 每頁到達保留行區（需 LINE-COUNT n(m)） | 頁尾 |
| - | `AT LINE-SELECTION` | 使用者雙擊清單行（或 F2） | 互動明細（第二層清單） |

## 3. 各事件重點與範例

### 3.1 INITIALIZATION：預設值

```abap
INITIALIZATION.
  t_b1 = '查詢條件'.                 " BLOCK 框標題
  gs_score-sign   = 'I'.            " 給 SELECT-OPTIONS 預設範圍 0~100
  gs_score-option = 'BT'.
  gs_score-low    = 0.
  gs_score-high   = 100.
  APPEND gs_score TO s_score.
```

### 3.2 AT SELECTION-SCREEN：輸入驗證

```abap
AT SELECTION-SCREEN.
  LOOP AT s_score INTO gs_score.
    IF gs_score-low < 0 OR gs_score-high > 999.
      MESSAGE '成績範圍請輸入 0～999' TYPE 'E'.
    ENDIF.
  ENDLOOP.
```

`MESSAGE ... TYPE 'E'` 在這個事件裡的效果：顯示錯誤、**把使用者留在選擇畫面**，改對了才放行。訊息類型速覽：

| TYPE | 效果 |
|---|---|
| `I` | 彈窗訊息，按確定繼續 |
| `S` | 狀態列訊息，不中斷 |
| `W` | 警告（選擇畫面上可按 Enter 硬過） |
| `E` | 錯誤：擋在選擇畫面 |
| `A` | 中止：程式直接結束 |

### 3.3 START-OF-SELECTION / END-OF-SELECTION

```abap
START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display_data.

END-OF-SELECTION.
  ULINE.
  WRITE: / '符合條件筆數：', gv_count.
```

### 3.4 TOP-OF-PAGE：每頁表頭

```abap
TOP-OF-PAGE.
  WRITE: / '學生成績清單（雙擊任一行看明細）'.
  ULINE.
```

注意觸發者是「**輸出**」：該頁第一個 WRITE 執行時系統先跑 TOP-OF-PAGE。一行都沒輸出就不會有頁首。（分頁與 END-OF-PAGE 的細節在講義 12。）

## 4. 互動清單：AT LINE-SELECTION 與 HIDE

需求：清單只顯示摘要，使用者**雙擊某行**看明細。問題是——雙擊時程式怎麼知道那行是哪筆資料？答案是 `HIDE`：

```abap
* 輸出時：把這一行對應的鍵值「藏」進該行
LOOP AT gt_students INTO gs_student WHERE score1 IN s_score.
  WRITE: / gs_student-id, gs_student-name, gs_student-score1.
  HIDE gs_student-id.               " 這行清單暗中記住學號
ENDLOOP.
CLEAR gs_student-id.                " 防呆：雙擊非資料行時不要撈到殘留值

* 雙擊時：系統自動把該行 HIDE 過的值還原回變數
AT LINE-SELECTION.
  IF gs_student-id IS INITIAL.
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

機制整理：

- `HIDE 變數.`：輸出目前行時，偷偷記下「這一行 ↔ 這個變數當時的值」。
- 使用者雙擊某行 → 系統把那一行 HIDE 的值**塞回同名變數** → 觸發 AT LINE-SELECTION。
- `sy-lsind`：目前清單層級（基本清單 0，第一層明細 1，最多 20 層）。AT LINE-SELECTION 裡的 WRITE 輸出到**新的一層**清單，返回鍵會一層層退回。
- 雙擊「沒 HIDE 過的行」不會還原任何值——所以輸出完要 CLEAR，並在事件裡檢查 IS INITIAL。

## 5. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| INITIALIZATION 的預設值沒出現 | 事件名拼錯（被當成普通程式碼歸入 START-OF-SELECTION） |
| 驗證訊息跳完程式照跑 | TYPE 用了 `I`/`S`——擋人要用 `E` |
| 雙擊任何行都顯示同一筆 | 忘了在輸出迴圈裡 HIDE，變數殘留最後一筆 |
| 雙擊空白行出現殘留資料 | 輸出後沒 CLEAR + 事件裡沒檢查 IS INITIAL |
| TOP-OF-PAGE 沒執行 | 該頁沒有任何 WRITE 輸出 |
| 程式碼寫在事件關鍵字之前 | 隱含屬於 START-OF-SELECTION，時序跟預期不同 |

## 6. 課堂練習

完成 [ex10](../ex10_events.md)：完整走一遍六個事件——預設範圍、輸入驗證、主處理、總結、頁首、雙擊明細（HIDE + sy-lsind）。
