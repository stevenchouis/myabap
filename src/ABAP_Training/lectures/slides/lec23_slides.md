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

# 講義 23
# 期末整合練習：訂單 Header/Detail

ABAP 基礎教育訓練（授課順序：接在講義 21 之後）

對應練習 ex23｜答案：表 `ZTR23_ORDH` + `ZTR23_ORDI`＋程式 `ZR_TR23_ORDERS`

---

## 本講重點

- 貨真價實的 Header/Detail：跟 SAP 標準 VBAK/VBAP、EKKO/EKPO 同一種結構
- Domain **固定值清單**（跟講義 21 的區間是不同技巧）
- 外鍵欄位本身就是 Key 的寫法
- **LUW all-or-nothing 實地驗證**

---

## 1. ex21 vs ex23：關聯性質不一樣

| | ex21（班級／學生） | ex23（訂單／明細） |
|---|---|---|
| 關聯性質 | 分類查詢 | 交易資料 |
| 外鍵欄位是不是 Key | 不是 | **是** |
| 沒有這筆關聯合理嗎 | 合理（可以還沒分班） | **不合理**（明細一定屬於某訂單） |

```abap
@AbapCatalog.foreignKey.screenCheck : true
key ordno  : ztr23_ordno not null
  with foreign key [0..*,1] ztr23_ordh
    where mandt = ztr23_ordi.mandt
      and ordno = ztr23_ordi.ordno;
```

外鍵欄位前面多了 `key`——跟 SAP 官方文件 SPFLI/SCARR 範例完全對應

---

## 2. Domain 固定值清單 vs 區間

| Domain 技巧 | 適合情境 | 本課範例 |
|---|---|---|
| 區間（Interval） | 數值有連續合法範圍 | `ZTR21_SCORE`：0～999 |
| 固定值清單 | 只有少數離散合法值 | `ZTR23_STATUS`：N/R/C |

選項少又固定 → 固定值清單（畫面自動出現 F4 選單，不用額外建 Search Help）
選項多或會變動（班級、產品）→ 還是要用 Search Help + 外鍵

---

<!-- _class: compact -->

## 3. LUW all-or-nothing：實地示範

```abap
INSERT ztr23_ordh FROM gs_ordh.     " Header 成功，sy-subrc = 0
INSERT ztr23_ordi FROM gs_ordi.     " 明細 001 成功，sy-subrc = 0
INSERT ztr23_ordi FROM gs_ordi.     " 故意重複 INSERT，sy-subrc = 4

IF sy-subrc <> 0.
  ROLLBACK WORK.                    " 整個 LUW 撤銷——連前面成功的 Header 也不見！
ENDIF.

SELECT SINGLE * FROM ztr23_ordh INTO @DATA(gs_check) WHERE ordno = 'ORD0002'.
" sy-subrc = 4：查無此訂單
```

> **關鍵**：INSERT 當下 `sy-subrc = 0` 只代表「這個陳述式」成功
> **COMMIT WORK 之前，一切都還可以整包撤銷**——不管中間有幾個動作各自回報成功

---

## 為什麼不能每個 INSERT 後面就 COMMIT？

如果 Header INSERT 完馬上 COMMIT，之後才發現明細失敗：

> Header 已經**真的、永久地**寫進資料庫了
> ROLLBACK 也救不回來 → 變成「只有訂單頭沒有明細」的髒資料

**正式程式的交易邊界**：一組業務上「必須一起成功」的動作之間不能插 COMMIT，
全部做完、確認沒問題，最後**一次性** COMMIT WORK

---

## 4. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| Search Help Activate 失敗 | Selection Method 欄位沒有 Data Element |
| 以為 ROLLBACK 只撤銷「最後一個」INSERT | 錯——LUW 整包處理，不分先後 |
| Header+Detail 中間插了 COMMIT WORK | 一旦 COMMIT 就永久生效，之後 ROLLBACK 救不回來 |
| ORDER BY 放在 INTO TABLE 後面 | 語法錯誤：要寫在 INTO TABLE **之前** |
| 外鍵設了 Screen Check 還是插入孤兒明細 | 正常——DDIC 外鍵只擋畫面，不擋 Open SQL |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex23**：

建訂單 Header/Detail 兩張表（外鍵＋固定值 Domain＋Search Help）

驗證 LUW all-or-nothing、外鍵行為、JOIN 輸出

基礎課第二個期末整合練習——完成代表主線融會貫通
