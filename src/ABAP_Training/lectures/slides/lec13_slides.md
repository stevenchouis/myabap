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
# 第一階段總整理——完整報表架構與實作攻略

ABAP 基礎教育訓練（授課順序：接在講義 14 之後；傳統報表階段收尾）

對應練習 ex13｜答案程式 `ZR_TR13_CAPSTONE`

---

## 本講重點

- 把前面各講（ALV 除外）的技能拼成**一支正式等級的傳統報表**
- 完整報表的標準架構與撰寫順序
- 唯一的新技巧：**總頁數回填**（READ LINE / MODIFY LINE）
- 實作攻略與自我檢查清單
- 第一階段結業對照：讀懂正式程式 `Z_INVENTORY_COST_REPORT`

---

## 1. 總整理目標：航班營收報表

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

**解法**：WRITE 先寫進**清單緩衝區（List Buffer）**（講義 10 第 3.5 節），不是直接上螢幕
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

`MODIFY CURRENT LINE`＝改寫最近一次 READ LINE 讀到的那一行（舊程式常見）

---

<!-- _class: compact -->

## 3.1 一份清單多張文件：每張各自「n / 總頁數」

`sy-pagno` 是**整份清單**的頁數 → 要自己記每張文件的**起訖頁**

```abap
AT NEW carrid.
  NEW-PAGE.                         " 每張文件從新頁開始
  CLEAR gs_docpage.  gs_docpage-doc = gs_flight-carrid.
ENDAT.
WRITE: / gs_flight-connid, gs_flight-fldate.
IF gs_docpage-first_page = 0.
  gs_docpage-first_page = sy-pagno.   " 第一行寫出後 = 第一頁
ENDIF.
AT END OF carrid.
  gs_docpage-last_page = sy-pagno.    " 最後一行寫出後 = 最後一頁
  APPEND gs_docpage TO gt_docpage.
ENDAT.
```

回填：總頁數 = last − first + 1；第 n 頁 = 實際頁 − first + 1
→ `READ LINE 1 OF PAGE 實際頁` → REPLACE → MODIFY LINE

實測：AA `1/4～4/4`、LH `1/10～10/10`、UA 重新從 `1/8`；一頁的文件自然 `1/1`

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

## 5. 自我檢查清單（第一階段結業標準）

- ☐ 選擇畫面有 BLOCK 框與標題，條件全部生效
- ☐ JOIN 一次取數，**沒有迴圈內 SELECT**
- ☐ 營收計算正確（票價 × 已售座位，金額含幣別格式）
- ☐ 每頁頁首頁尾齊全、直欄筆直、跨頁正常
- ☐ 總頁數回填正確（每一頁顯示相同總頁數）
- ☐ 主流程只有 PERFORM；命名符合 gv_/gs_/gt_ 慣例
- ☐ 查無資料、輸入錯誤都有明確訊息，不會 dump

---

## 6. 第一階段結業對照：讀正式程式

打開 `Z_INVENTORY_COST_REPORT`（或 ZDQM 系列）對照閱讀：

結構跟你的總整理作品**一模一樣**——
宣告（或 _TOP include）、選擇畫面、事件骨架、
FORM 區、分頁排版。差別只在業務邏輯的複雜度

**讀得懂、指得出每一段對應哪一講 → 傳統報表階段結業**

下一階段：OOP 課程（`src/ABAP_Training_OOP/`）
把同樣的邏輯改用 Class 組織

---

<!-- _class: compact -->

## 6.1 實戰閱讀：傳票清單 ZRFI0004

真實客戶程式（2006 起多人多次修改），原始碼：`lectures/cases/zrfi0004.prog.abap`，**只供閱讀**

| 區塊 | 講義 |
|---|---|
| 舊式宣告：`TABLES`、`OCCURS 0 WITH HEADER LINE`、macro `cls` | 2、5 §8、9 |
| 選擇畫面：`MATCHCODE OBJECT`、`NO-DISPLAY`、程式自己填 range 表 | 7 |
| `AUTHORITY-CHECK`、`FUNCTION KEY`＋`CALL TRANSACTION` | 28（先看懂） |
| `MESSAGE ... STOP`、`SELECT ... ENDSELECT` | 10、6 §4 |
| `FOR ALL ENTRIES`、`APPENDING`、`saknr AS hkont` | 11 |
| `AT NEW` 後 `READ TABLE ... INDEX`（繞過 `*` 遮蔽） | 20 |
| `WRITE AT (t_optfm-xxx)` 欄寬結構、`SKIP TO LINE`、中文寬度 | 12 |
| 每張傳票「頁碼 n/總頁數」回填 | 13 §3 |

---

## 兩顆按鈕：Parameter Transaction（講義 28 才教建立）

```abap
CASE sscrfields-ucomm.
  WHEN 'FC01'. CALL TRANSACTION 'ZFI0037'.    " 維護
  WHEN 'FC02'. CALL TRANSACTION 'ZFI0037Q'.   " 查詢
ENDCASE.
```

- `ZFI0037`／`ZFI0037Q` 不是程式，是 **SE93 建的 Parameter Transaction**
- 呼叫 **SM30**，預先填好要開的表／View，跳過初始畫面
- `ZFI0037` → 表 `ZFI0037`（會計主管表）：可新增、修改
- `ZFI0037Q` → **Read only 的 Maintenance View**：只能顯示，沒有 Change／Display 切換
- 只把 T-code 設成顯示模式擋不住：有權限的人在 SM30 按切換就能改
- Maintenance View 見講義 21；SE93 建立步驟見講義 28 §7

---

<!-- _class: compact -->

## ZRFI0004 的分頁設計：自己控制整頁 65 行

| 行號 | 內容 |
|---|---|
| 1～6 | 空白（`SKIP TO LINE 7`） |
| 7～14 | 公司名、標題、表頭資訊、欄位標題 |
| 15～54 | 明細，每筆 4 行，**每頁最多 10 筆**（`MOD 10`），10 筆剛好排滿 |
| 55～59 | 簽核欄、本頁合計、累頁合計（`SKIP TO LINE 55`） |
| 60～65 | 過帳日期、會計文件、**第 64 行「頁碼 n/&」** |

- 頁尾 60～65 是自己印的 → 寫 `65(6)` 會被系統保留 → 所以改 `65(0)`
- 第 65 行印完，下一筆 `WRITE /` 超出頁面 → **系統自動換頁**
- 每張傳票 `NEW-PAGE` 後寫 `sy-pagno = 1` → 頁碼從 1 算
  但 `READ LINE ... OF PAGE` 要**實際頁序** → 另用 `l_total_page` 記錄
  → 寫入系統欄位的代價：之後要一直記得它跟實際對不上

---

## ZRFI0004：看得懂，自己寫時換個做法

| 寫法 | 建議 |
|---|---|
| `sy-pagno = 1.` | 用 3.1 的起訖頁做法，不改系統欄位 |
| 回填迴圈後才 `w_subrc = sy-subrc` 判斷有無明細 | sy-subrc **馬上**檢查，有無明細直接判斷 |
| LOOP 內逐筆 `SELECT SINGLE` | 整批讀進內表或 JOIN（講義 11） |
| 全部內表帶 Header Line | 內表＋獨立 work area（講義 5 §8） |
| 三段簽核欄 IF 分支大量重複 | 抽成 FORM，差異用參數（講義 8） |
| 大量註解掉的舊程式碼 | 舊版交給 TR 版本管理（講義 8a） |

---

<!-- _class: compact -->

## 6.2 用前面所學，完成一支好的傳票清單

範例程式：`lectures/cases/zr_tr13_zrfi0004.prog.abap`（`$TMP` 可直接執行）

| 步驟 | 做法 | 講義 |
|---|---|---|
| 1. 需求 | 條列條件、輸出單位、每頁規則、簽核規則；**有疑問找使用者確認** | — |
| 2. 版面 | 65 行配置表、欄寬集中在 `gs_width` 結構 | 12 |
| 3. 宣告 | TYPES＋內表＋work area、`gt_/gs_/gv_`、`DATA gv_x TYPE bkpf-x` 當 FOR 參考 | 2、3、5、7 |
| 4. 骨架 | 事件裡只有 PERFORM；勾選框 → `NO-DISPLAY` range；查無資料 `STOP` | 7、10 |
| 5. 讀資料 | **整批讀、迴圈只 READ TABLE**；FAE 空表防呆；查詢前先 CLEAR | 6、11、4 |
| 6. 輸出 | 每 10 筆或最後一筆印簽核欄；簽核欄**一個 FORM** | 8、12 |
| 7. 頁碼 | 起訖頁回填，行號用 `sy-linno` 記錄，不改 `sy-pagno` | 13 §3.1 |
| 8. 驗證 | 跟正式程式逐行比對，刻意挑邊界情況 | — |

---

<!-- _class: compact -->

## 驗證：跟正式程式 ZRFI0004 逐行比對

比對程式：同條件 `SUBMIT ... EXPORTING LIST TO MEMORY` 兩支程式
→ `LIST_FROM_MEMORY` ＋ `LIST_TO_ASCI` 轉文字 → 逐行比較

| 條件（公司 1000） | 涵蓋 | 行數 | 結果 |
|---|---|---|---|
| 2026 過帳 | 剛好 10 筆、沒有明細 | 3,315 | 相同 |
| 2024 三種狀態 | 暫存、被刪除的暫存 | 8,905 | 相同 |
| 2022 部分文件 | 12～18 筆（跨 2 頁） | 3,120 | 相同 |
| 2021 部分文件 | 26 筆（跨 3 頁） | 650 | 相同 |

比對找出原程式兩個問題（要回報使用者確認，不是默默改掉）：
- 沒有明細的傳票，匯率 0 經轉換常式 `EXCRT` 顯示成**空白**（有明細的印 1.00000）
- 選擇畫面的「文件日期」條件，SELECT **沒有用到**

---

<!-- _class: lead -->

# 第一階段總整理實作

完成 **ex13**：獨立完成航班營收報表

建議先不看答案程式，卡住時回查對應講義

完成後與 `zr_tr13_capstone` 對照，
比較自己與範本的取捨差異
