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

# 講義 21
# 建立 Z 資料表與 Open SQL 寫入

ABAP 基礎教育訓練（授課順序：接在講義 15 之後）

對應練習 ex21｜答案：表 `ZTR21_STUD` + `ZTR21_CLASS`＋程式 `ZR_TR21_ZTABLE`

---

## 本講重點

- DDIC 三層件：Domain → Data Element → 表格欄位
- SE11 建立透明表：鍵欄位、Delivery Class、Technical Settings
- SM30 維護畫面（Table Maintenance Generator）
- **Header／Detail 兩表關聯**：外鍵（Foreign Key）與檢查表（Check Table）
- **Search Help**：F4 值清單怎麼來的，跟外鍵的差別
- Open SQL 寫入：`INSERT` / `UPDATE` / `MODIFY` / `DELETE`
- LUW 與 `COMMIT WORK` / `ROLLBACK WORK`

---

## 1. DDIC 三層件

| 層 | 管什麼 | 例 |
|---|---|---|
| **Domain** | **技術屬性**：型別、長度、值域、轉換常式 | INT4、值域 0～999 |
| **Data Element** | **語意**：欄位標籤、F1 說明（多語言） | 「學生成績」 |
| 表格欄位 | 引用 DE（或直接用內建型別） | `SCORE TYPE ztr21_score` |

為什麼分三層？**重複利用與一致性**：
十張表共用同一個 DE → 標籤、F1、值域全系統一致，改一處全生效
（`TYPE scarr-carrid` 帶出那麼多語意的原因——講義 6）

實務折衷：鍵欄位與業務欄位用 DE；
純技術欄位（旗標、備註）直接用內建型別省事

---

## 2. SE11 建立透明表

1. SE11 → Database table → `ZTR21_STUD` → Create
2. **Delivery Class**：`A`（應用資料，預設選它）
   `C` = Customizing 設定檔（跟著 TR 搬）、`L` = 暫存
3. Data Browser/Table View Maint.：`Display/Maintenance Allowed`
4. **Fields**：第一欄一定是 `MANDT TYPE mandt` 且勾 **Key**
   接著鍵欄位、資料欄位
5. **Technical Settings**（必填才能啟用）：
   Data Class `APPL0`、Size Category `0`
6. 啟用——表就真的建在資料庫了，SE16N 可立刻查

> 表建錯欄位型別，上線後要改很痛（要轉檔）
> **設計階段多想一分鐘**

---

## 3. SM30 維護畫面

讓使用者不寫程式就能維護表內容：

1. SE11 該表 → Utilities → **Table Maintenance Generator**
2. Authorization Group 練習用 `&NC&`（不檢核）
   Function Group `ZFG_TR21`（畫面程式的容器）
   Maintenance type：one step（單畫面）
3. 產生後 → SM30 輸入表名 → Maintain
   → 現成的新增/修改/刪除畫面

實務上參數表、對照表幾乎都配 SM30

---

## 4. Header／Detail 關聯：外鍵與 Check Table

訂單－客戶、明細－產品……本質都是 **Header（1）／Detail（多）** 關聯
本課示範：班級（Header）－學生（Detail），跟講義 6 的 SCARR－SPFLI 同一種關係

- **Check Table**：被參考的表（`ZTR21_CLASS`），扮演「合法值清單」
- **外鍵表**：帶外鍵欄位的表（`ZTR21_STUD.KLASSE`），值必須存在於 Check Table

```abap
klasse : ztr21_klasse
  with foreign key [0..*,1] ztr21_class
    where mandt  = ztr21_stud.mandt
      and klasse = ztr21_stud.klasse;
```

`[0..*,1]`：多筆學生（外鍵表）對應 1 筆班級（檢查表）

---

<!-- _class: compact -->

## 外鍵只擋畫面，不擋程式！

`@AbapCatalog.foreignKey.screenCheck : true` **只影響 Dynpro 畫面**（SM30、Module Pool）

> **Open SQL 的 INSERT/UPDATE/MODIFY 完全不受外鍵約束**
> 程式塞一個 Check Table 沒有的班級代碼一樣 `sy-subrc = 0`

跟一般資料庫的 Foreign Key Constraint 不一樣：
那是資料庫引擎強制擋寫入；SAP DDIC 外鍵是**應用層／畫面層**機制

要在程式擋，得自己 `SELECT SINGLE` 檢查 Check Table

---

## Search Help：F4 選單哪裡來的

跟外鍵是兩件事：外鍵「擋不合法的值」、Search Help「幫你選合法的值」

- 只設外鍵沒設 Search Help：會擋錯，但沒 F4，要背代碼
- 只設 Search Help 沒設外鍵：F4 能選，但手動打錯的畫面不會擋

建立（SE11 → Search Help → Elementary Search Help）：
- **Selection Method**：資料來源表（`ZTR21_CLASS`）
- **Parameters**：`KLASSE`（Import+Export+SH field）、`KLNAME`（純顯示，僅 Export）
- 建好要**掛到 Data Element**（`ZTR21_KLASSE` → Search Help 欄位）才會全面生效

---

## 5. Open SQL 寫入四指令

全部**用 sy-subrc 回報結果**；`sy-dbcnt` 是影響筆數：

```abap
DATA gs_stud TYPE ztr21_stud.    " 表名直接當結構型別

* INSERT：新增；主鍵已存在 → sy-subrc = 4，不會蓋掉
INSERT ztr21_stud FROM gs_stud.

* UPDATE：改既有資料；找不到 → sy-subrc = 4
UPDATE ztr21_stud SET score = 90 WHERE id = 'S0001'.

* MODIFY：有就改、沒有就新增（upsert）——參數表最愛
MODIFY ztr21_stud FROM gs_stud.

* DELETE：刪除
DELETE FROM ztr21_stud WHERE id = 'S0001'.
```

---

## 批次寫入與兩個習慣

多筆版本：`INSERT ztr21_stud FROM TABLE gt_stud.`

> **INSERT FROM TABLE 遇任一筆主鍵重複就整批 dump**
> 除非加 `ACCEPTING DUPLICATE KEYS`（重複跳過、subrc = 4）

兩個習慣：

- MANDT 一樣**不要**自己塞——系統自動帶當前 client
- 寫入帶齊**稽核欄**（`sy-uname` 異動者、`sy-datum` 異動日）
  查問題時會感謝自己

---

## 6. LUW 與 COMMIT WORK

變更以 **LUW**（Logical Unit of Work）為單位，確認才落地：

```abap
INSERT ztr21_stud FROM gs_stud.
IF sy-subrc <> 0.
  ROLLBACK WORK.       " 整包撤銷：LUW 內所有寫入取消
  MESSAGE '寫入失敗，已回復' TYPE 'E'.
ENDIF.
COMMIT WORK.           " 整包確認：全部永久生效
```

- 表頭＋明細必須「**全成功或全失敗**」——LUW 的意義
- 程式跑完系統會隱含 commit（練習沒寫也多半進去了）
  但**正式程式的寫入要明確 COMMIT／ROLLBACK**
- 多人同改一筆 → **Lock Object**（ENQUEUE/DEQUEUE）
  先認識名詞，屬進階課題

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 表啟用不了 | Technical Settings 沒填 |
| SE16N 看不到剛寫的資料 | sy-subrc 其實是 4；或在別的 client 查 |
| INSERT 一直 subrc = 4 | 主鍵重複——重跑前先清舊測試資料 |
| INSERT FROM TABLE 直接 dump | 沒加 ACCEPTING DUPLICATE KEYS |
| SM30 說表不能維護 | 建表時維護選項不允許、或沒產畫面 |
| 自己塞 MANDT | 不用，系統自動處理 |
| 以為外鍵能擋程式寫入的髒資料 | 外鍵只管畫面輸入，Open SQL 不受影響 |
| JOIN 的 ON 條件寫了 MANDT | 語法錯誤：client 欄位由編譯器自動處理 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex21**：

建 Domain＋Data Element＋透明表 `ZTR21_STUD`＋班級主檔 `ZTR21_CLASS`
`KLASSE` 欄位設外鍵＋Search Help，產 SM30 維護畫面

寫程式跑完 INSERT / UPDATE / MODIFY / DELETE
＋外鍵行為驗證＋JOIN，全流程並驗證 sy-subrc
