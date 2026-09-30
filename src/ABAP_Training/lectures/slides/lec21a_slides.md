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

# 講義 21a
# Maintenance View、Help View 與 JOIN 串 Z 表

ABAP 基礎教育訓練（授課順序：接在講義 12 之後、講義 13 之前）

對應練習 ex21a｜答案：程式 `ZR_TR21A_JOIN`

---

## 本講重點

- 延續講義 21 的 `ZTR21_STUD`／`ZTR21_CLASS` 與 SM30 維護畫面
- **Maintenance View**：一次維護多張表；`Read only` 做查詢專用
- **Help View**：Search Help 需要多張表時
- JOIN 串 Header／Detail 兩張 Z 表

學完接講義 13：傳票清單的會計主管表 `ZFI0037` 就是這樣維護

---

<!-- _class: compact -->

## 1. Maintenance View：SM30 一次維護多張表

典型：主檔＋文字表。標準範例 `V_TCURC` = 幣別 `TCURC` ＋ 說明 `TCURT`
→ SM30 同一列填代碼與說明，存檔自動寫進兩張表；文字表自動取登入語言

- 表之間**必須有外鍵**，連接條件沿用外鍵
- 附屬表對主表**多對一**（主表一筆最多對一筆）
- INNER JOIN；**程式不能 SELECT**，只能當 `TYPE`

建立：SE11 → View → **Maintenance view** → Table/Join Conditions（主表＋**Relationships** 勾附屬表）
→ View Fields（主表 Key 全部要有）→ Maint. Status（查詢專用選 `Read only`）→ 啟用 → **Table Maintenance Generator** → SM30

---

## 2. Help View：Search Help 需要多張表時

Selection Method 可以是：一張表／Database View／**Help View**

| | Database View | Help View |
|---|---|---|
| JOIN | INNER：附屬表沒資料 → 整筆消失 | **OUTER**：主表全出現，附屬欄位留空 |
| 連接條件 | 自己定 | 沿用外鍵 |
| 程式 SELECT | 可以 | 不行 |

- 只是加「文字表」說明 → 不需要 Help View，Selection Method 直接填主表
- 標準範例 `H_T005` = 國家 `T005` ＋ 名稱 `T005T`

---

## 3. 程式裡把兩張 Z 表串起來讀

Maintenance View／Help View 程式都不能 SELECT → 用 JOIN（講義 11）

```abap
SELECT s~id s~name s~klasse c~klname
  FROM ztr21_stud AS s
  LEFT OUTER JOIN ztr21_class AS c
    ON c~klasse = s~klasse
  INTO CORRESPONDING FIELDS OF TABLE gt_join
  ORDER BY s~id.
```

- LEFT OUTER：班級 `ZZZZ`（不存在）的學生也要列出
- `ON` 不可寫 `MANDT`（編譯器自動處理）
- 班級代碼有值、名稱空白 → 外鍵沒擋住的髒資料

---

## 4. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 程式 SELECT Maintenance View 報錯 | 只能給 SM30／Search Help 用 |
| JOIN 的 ON 條件寫了 MANDT | 語法錯誤：client 欄位由編譯器自動處理 |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex21a**：

建唯讀的 Maintenance View `ZV_TR21_STUD`

寫程式 LEFT OUTER JOIN 學生與班級，找出班級不存在的學生
