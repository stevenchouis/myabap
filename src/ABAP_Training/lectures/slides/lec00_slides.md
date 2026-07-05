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

# 講義 0
# SAP / ERP 背景知識

ABAP 基礎教育訓練

寫第一行 ABAP 之前，先建立整個工作環境的「地圖」

---

## 本講重點

- ERP 與 SAP：公司、產品、版本演進（R/3 → ECC → S/4HANA）
- 三層式架構與 SAP GUI、Client（MANDT）觀念
- 系統 Landscape：DEV / QAS / PRD 與傳輸請求
- SAP 模組總覽：FI / CO / SD / MM / PP / QM…
- 團隊角色：功能顧問／ABAP Developer／Basis
- 標準 vs 客製：為什麼我們寫的東西都是 Z 開頭

---

## 1. ERP 是什麼

**把財務、銷售、採購、生產、庫存、人資整合在同一套系統、同一份資料庫**

- **一筆交易，全流程連動**：接單 → 庫存預留 → 出貨 → 自動拋會計分錄
- **即時、單一事實**：老闆和倉庫看到的是同一筆庫存
- 代價：**流程被系統規範** → 所以需要「顧問」這個行業

SAP：全球 ERP 龍頭（德國，1972）
台灣常見的其他 ERP：Oracle、鼎新——概念相通、生態不同

---

## 2. SAP 產品與版本演進

| 名稱 | 年代 | 重點 |
|---|---|---|
| R/2 | 1980s | 大型主機時代 |
| R/3 | 1992 | **三層式架構**成型；老 SAP 人至今仍拿「R/3」泛稱 SAP |
| ECC | 2004 | R/3 後繼，市面上仍大量存在（ECC 6.0） |
| S/4HANA | 2015 | 底層改用 **HANA** in-memory DB，介面主推 **Fiori** |

- 不管哪一代，**應用邏輯都是 ABAP 寫的**——技能跨版本通用
- 本課程的傳統報表技能：主戰場是 ECC 與 S/4 沿用的既有客製

---

## 3. 三層式架構

```
使用者端   Presentation Layer   SAP GUI / 瀏覽器(Fiori)
              ↓ 只負責畫面
伺服器     Application Layer    ABAP 程式在這裡執行
              ↓ Open SQL
資料庫     Database Layer       所有資料集中一套 DB
```

- SAP GUI 只負責顯示畫面、收鍵盤滑鼠
- **你寫的 ABAP 全部在 Application Server 上跑**
  → 除錯、效能問題都在伺服器端，跟使用者電腦快慢無關

---

## 開發者常用 T-code

| T-code | 用途 |
|---|---|
| SE38 / SE80 | ABAP 編輯器／物件導覽 |
| SE11 / SE16N | 資料字典／看資料表內容 |
| SE37 | Function Module |
| SM30 | 維護表格資料 |
| ST22 | Dump 分析（程式當掉紀錄） |
| SM37 | 背景作業監控 |
| SPRO | 系統組態（功能顧問的主戰場） |

命令欄：`/n` 換 T-code（`/nSE38`）、`/o` 開新視窗

---

## 4. Client（MANDT）觀念

同一套系統可劃分多個 **Client**（3 碼數字，如 130）

- 登入時要選 Client
- 各 Client 的**業務資料與大部分設定互相隔離**
  （資料表第一欄 MANDT 就是它——講義 6 會再遇到）

> **程式碼是跨 Client 共用的！**
> 你在 130 改的程式，其他 Client 看到同一支
> 資料隔離、程式共用——初學最容易混淆的一點

---

## 5. Landscape 與傳輸請求（TR）

```
DEV（開發機） → QAS（測試機） → PRD（正式機）
   開發、單測      使用者驗收        上線使用
```

程式怎麼「搬」過去？靠 **Transport Request**：

- DEV 改物件 → 掛在 TR 底下（`$TMP` Local Object 例外，**不會傳輸**）
- 開發完成 → **Release** → import QAS → 測過 → import PRD
- TR 是稽核軌跡：誰、何時、改了什麼、搬去哪

> 團隊紀律：一個功能一個 TR；**沒有明確指示不擅自 Release**

---

<!-- _class: compact -->

## 6. SAP 模組總覽（必背的日常語言）

| 模組 | 全名 | 管什麼 |
|---|---|---|
| FI | Financial Accounting | 總帳、應收應付、資產 |
| CO | Controlling | 成本中心、內部訂單、成本分析 |
| SD | Sales & Distribution | 報價、訂單、出貨、開票 |
| MM | Materials Management | 請購、採購單、收貨、發票校驗 |
| PP | Production Planning | BOM、工單、排程 |
| QM | Quality Management | 檢驗批、品質通知（ZDQM 系列即 QM 客製） |
| PM | Plant Maintenance | 廠務/設備維護 |
| WM/EWM | Warehouse Mgmt | 倉儲（儲位層級） |
| HCM | Human Capital Mgmt | 組織、薪資、差勤 |
| PS | Project System | WBS、專案成本 |

模組高度整合：SD 出貨動 MM 庫存、拋 FI、算 CO
→ 跨模組報表（你未來的日常）常要 JOIN 好幾個模組的表

---

## 7. 團隊角色分工

| 角色 | 負責 | 主要工具 |
|---|---|---|
| 功能顧問 | 懂業務流程，用 SPRO 組態調整標準功能；寫 Spec 給開發 | SPRO、業務 T-code |
| **ABAP Developer（你）** | 依 Spec 開發客製：報表、介面、增強、表單 | SE38/SE80、除錯器 |
| Basis | 系統安裝、效能、權限、TR 搬版 | SM 系列、STMS |
| Key User | 提需求、做 UAT 驗收 | 業務 T-code |

流程：使用者提需求 → 顧問評估標準功能 → 不夠才開 Spec 客製
→ 開發 → 測試 → Basis 搬版上線

---

## 給 ABAP 開發者的兩個提醒

**看得懂 Spec 的模組語言是戰力的一半**
顧問說「撈 MB51 那些資料」「BSEG 太大不要直接查」
→ 你要接得住——模組知識隨案子累積

**客製類型縮寫 RICEF**
Report（報表）、Interface（介面）、Conversion（轉檔）、
Enhancement（增強）、Form（表單）
→ 本課程主攻 **R**，其餘實務中逐步接觸

---

## 8. 標準 vs 客製：Z 命名空間

**標準物件**：SAP 原廠交付
- 原則上**不可直接修改**（升級被覆蓋、失去原廠支援）
- 擴充只能走預留縫隙：Enhancement Point、BAdI、User-Exit

**客製物件**：客戶自行開發
- 一律 **Z 或 Y 開頭**（SAP 保留給客戶的命名空間）
- 課程裡所有程式叫 `ZR_...` 的原因

判讀技巧：Z/Y 開頭 → 自家寫的，找開發
標準名稱 → 找顧問查設定或 SAP Note

---

<!-- _class: compact -->

## 9. 名詞速查表（遇到再回來查）

| 名詞 | 意思 |
|---|---|
| NetWeaver / ABAP Platform | ABAP 執行環境的正式名稱 |
| Customizing | 顧問在 SPRO 做的組態（不寫程式的客製） |
| Dump | ABAP 執行期錯誤中止，紀錄在 ST22 |
| Background Job | 背景排程程式（SM36 排、SM37 看） |
| BAPI | 標準業務 API（RFC-enabled FM） |
| RFC | 跨系統呼叫 FM 的協定 |
| IDoc | SAP 系統間標準電子文件（介面常用） |
| SAP Note | 原廠修正與知識文件 |
| Fiori | S/4 世代網頁式 UI |
| CDS View | S/4 世代資料庫層 view（進階） |
| ADT / Eclipse | 新一代 ABAP 開發工具 |

---

<!-- _class: lead -->

# 課後任務

登入訓練系統，練習 `/n`、`/o`；用 ST22 看別人的 dump

把模組表抄一遍，對照自家公司用到哪些模組

想一個熟悉的業務流程，說出它經過哪些模組

**下一講 lec00a：動手裝環境**
