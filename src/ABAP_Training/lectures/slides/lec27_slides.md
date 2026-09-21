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

# 講義 27
# 並行控制與 Lock Object

ABAP 基礎教育訓練（授課順序：接在講義 21 之後）

對應練習 ex27｜答案物件 Lock Object `EZTR21_STUD`＋程式 `ZR_TR27_LOCK_OBJECT`

---

## 本講重點

- 多人同時改同一筆資料為什麼會出問題
- Enqueue Server／Lock Table（觀念）
- SE11 建立 **Lock Object**（`ENQU`）
- 自動產生的 `ENQUEUE_*`／`DEQUEUE_*` FM
- **Lock Mode**（E／S／X／O）
- **SM12 跟 Lock Object 的關係**
- 鎖卡住殘留怎麼排查與清除

---

## 1. 一個會出事的情境

兩個承辦人 A、B 同時打開**同一個學號**

1. A 打開 `S0001`，成績 85
2. B 也打開 `S0001`，同樣 85
3. A 改成 90，存檔
4. B 把自己畫面上的 85 改成 78，存檔
   → **B 蓋掉 A 剛存的 90**

**遺失更新（Lost Update）**：多人系統的經典並行問題

---

## 1.1 解法：Lock Object

不是「程式自己判斷」（比對時間戳記容易漏）
而是 SAP 系統層級的機制

- A 要改之前先**登記**（ENQUEUE）
  → 系統記下「這筆現在被 A 佔用」
- B 也想改 → 系統查到已有人登記 → 丟出例外擋下 B
- A 做完 **解除登記**（DEQUEUE）→ B 才能繼續

---

## 2. Enqueue Server 與 Lock Table

- SAP 有獨立的**鎖定管理員（Enqueue Server）**
- 維護**鎖定表**：誰、鎖了哪張表哪一筆、什麼模式
- 這張表**不是資料庫表**，是 Kernel 記憶體裡管理的（SM12 可查）

關鍵特性：

- 跟資料庫交易（COMMIT／ROLLBACK）**沒有直接關係**
- **只在程式主動呼叫 ENQUEUE 時才生效**，不會自動擋 Open SQL 的 `UPDATE`
- 跟外鍵「只擋畫面、不擋 Open SQL」同一種概念

---

## 3. SE11 建立 Lock Object

1. SE11 → **Lock Object** → 名稱**一定要 `E` 開頭**（如 `EZTR21_STUD`）
2. **Tables**：Primary Table 填 `ZTR21_STUD`
3. **Lock Parameters**：勾整個主鍵（`MANDT`＋`ID`）＝鎖一筆
4. **Lock Mode**：練習選 `E`
5. 存檔、Activate

啟用瞬間系統**自動產生兩個 FM**：
`ENQUEUE_EZTR21_STUD`、`DEQUEUE_EZTR21_STUD`

查詢：SE11 → Utilities → **Generated Objects**，或 SE37 直接查
Import 參數名稱 = Lock Parameters 勾選的欄位

---

<!-- _class: compact -->

## 4. Lock Mode

| Lock Mode | 說明 | 適用 |
|---|---|---|
| **E**（Exclusive／Write） | 同時只有**一人**；同一使用者可疊加，要 DEQUEUE 相同次數 | **最常用**，本練習選這個 |
| S（Shared／Read） | 多人可同時持有，但有人持有時別人拿不到 E | 允許多人讀、寫入互斥 |
| X（Exclusive，不可累加） | 類似 E，但同一使用者重複 ENQUEUE 會失敗 | 連自己都不能重入 |
| O（Optimistic） | 不真的鎖，只記錄狀態供比對 | 長時間編輯、不想占著鎖 |

練習只用 `E`，其他先有印象即可

---

<!-- _class: compact -->

## 5. 程式呼叫：ENQUEUE → 編輯 → DEQUEUE

```abap
CALL FUNCTION 'ENQUEUE_EZTR21_STUD'
  EXPORTING
    mandt          = sy-mandt
    id             = lv_id
  EXCEPTIONS
    foreign_lock   = 1    " 別人已經鎖住了
    system_failure = 2
    OTHERS         = 3.
IF sy-subrc <> 0.
  MESSAGE '資料正被其他人編輯中，請稍後再試' TYPE 'I'.
  RETURN.
ENDIF.

" ... 編輯邏輯（UPDATE／INSERT／MODIFY）...

CALL FUNCTION 'DEQUEUE_EZTR21_STUD'
  EXPORTING
    mandt = sy-mandt
    id    = lv_id.
```

---

## 5.1 三個重點

1. `ENQUEUE` 一定要接 `EXCEPTIONS`，`sy-subrc <> 0`
   → **絕對不能無視例外直接往下編輯**
2. `DEQUEUE` 沒有 EXCEPTIONS 可接，但**一定要呼叫**
   忘記解鎖 → 資料一直卡住，直到 Session 結束才自動清
3. E 模式同一使用者可重複 ENQUEUE（次數疊加）
   → 呼叫幾次 ENQUEUE，就要**相同次數** DEQUEUE

---

## 6. SM12 跟 Lock Object 的關係

| 角色 | 說明 |
|---|---|
| Lock Object（SE11） | **設計圖**：鎖哪張表、哪些欄位、什麼模式 |
| 鎖定表（Lock Table） | **施工結果**：每次 ENQUEUE 成功新增一筆，DEQUEUE 移除 |
| SM12 | **查看窗口**：列出整個系統目前所有鎖，本身不鎖任何東西 |

SM12 每一列 = 某支程式 ENQUEUE 之後、還沒 DEQUEUE 的狀態

---

<!-- _class: compact -->

## 6.1 SM12 欄位對應

| SM12 欄位 | 對應到 |
|---|---|
| Table Name | Lock Object 的 Primary Table（`ZTR21_STUD`） |
| Lock argument | Lock Parameters 的實際值（如 `130S0001`） |
| User name | 呼叫 `ENQUEUE_*` 的使用者 |
| Time | 鎖定建立時間 |
| Transaction Code／Program | 哪個 T-code／程式呼叫的 |

---

## 7. 雙視窗測試：實際看到被擋下來

`FOREIGN_LOCK` 只有**另一個使用者／Session** 持有鎖時才會發生

1. 開兩個 SAP GUI 視窗（或兩個帳號）
2. 視窗 A 跑程式，`ENQUEUE` 成功後用中斷點或 `WAIT UP TO 30 SECONDS` 停住
3. 視窗 B 對**同一學號**跑同一支程式 → `sy-subrc = 1`
4. **SM12** 看得到視窗 A 的那一筆
5. A `DEQUEUE` 或結束後，SM12 那筆消失，B 再試就成功

---

## 7.1 什麼情況鎖會「卡住」

沒機會正常 `DEQUEUE`，鎖殘留在鎖定表：

- `ENQUEUE` 成功後、`DEQUEUE` 前發生 **Dump**
- 使用者在維護畫面放著不管，或直接關掉 SAP GUI
- **無頭測試工具**呼叫需要畫面互動的功能（如 `VIEW_MAINTENANCE_CALL`），卡住後被強制斷線

---

## 7.2 排查與清除

1. **SM12** 輸入 Table Name 或自己的 User → 看有沒有殘留
2. 多數情況不用擔心：Session 終止時 Kernel 通常會自動清（可能有短暫延遲）
3. 過一段時間還在 → 選取那一列 → **Delete Locks**

> 手動刪除是維運層級操作
> **先確認這個鎖真的沒人在用**，否則等於強行打斷別人的作業

遇到 `FOREIGN_LOCK` 想不通是誰鎖的 → **先去 SM12 看一眼**

---

<!-- _class: lead -->

# 課堂練習

完成 **ex27**：

建 Lock Object `EZTR21_STUD`，
寫程式 ENQUEUE → 編輯 → DEQUEUE，
雙視窗實測 `FOREIGN_LOCK`，並在 SM12 觀察鎖定記錄
