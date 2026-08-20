# CDS View 課程練習 9：Extend View

## Lecture

### 這一課要教什麼

進階篇第一課。基礎篇學的是「怎麼從零設計 CDS View」，進階篇第一個主題反過來：**不修改原始碼、幫一個已經存在（甚至是別人維護、你沒有寫入權限）的 CDS View 加欄位**。這個機制叫 **Extend View**，語法是 `extend view`。

這在企業實務上很常見：想像 `ZI_CDS01_CARRIER` 是別的團隊維護的共用 View，你的專案需要多一個欄位，但你不想（也可能不能）直接改別人的原始碼——`extend view` 讓你另外建一個獨立物件，把新欄位「掛」上去，原始物件完全不動。

### 語法元素講解

```abap
@AbapCatalog.sqlViewAppendName: '<Append View 名稱，≤14~16碼>'
extend view <既有 View 名稱> with <這個 Extend 物件自己的名稱>
{
  <新欄位清單>
}
```

- **`@AbapCatalog.sqlViewAppendName`**：Extend View 底層也會建一個 DDIC Append View 物件，這個 annotation 指定它的名稱（限制長度比一般 `sqlViewName` 更短，這門課專案先前在 Enhancement 課程 en03 遇過「17 碼會報錯」的先例，這一課用 11 碼保守起見）
- **`extend view <目標> with <自己的名稱>`**：`<目標>` 是要擴充的既有 View，`<自己的名稱>` 是這個 Extend 物件的正式物件名稱（Repository 裡看到的是這個名稱，不是目標 View 的名稱）
- **欄位清單**：可以是常數字面值（這一課示範的做法）、也可以是透過新增 Association 接到其他表的欄位（進階用法，跟 cds03 的 Association 語法完全相通）

### 完整範例

```abap
@AbapCatalog.sqlViewAppendName: 'ZCCDS09CEXT'
extend view ZI_CDS01_CARRIER with ZC_CDS09_CARRIER_EXT
{
  'ACTIVE' as Status
}
```

這段程式碼幫 cds01 建的 `ZI_CDS01_CARRIER`（航空公司基本 View）加了一個 `Status` 欄位。**重點：這一課驗證完之後，重新讀取 `ZI_CDS01_CARRIER` 的原始碼，內容跟 cds01 建立時一字不差**——`extend view` 不會、也不能修改目標物件的原始碼，新欄位是在啟用時由系統自動「疊」上去的。

**⚠️ 這一課的實測結果，跟原本課綱草案的預期有出入**：草案原本以為要先在 `ZI_CDS01_CARRIER` 加 `@Metadata.allowExtensions: true` 才能被擴充（這是另一個相關課程——Fiori Elements fe08——學到的規則，那邊講的是「CDS View 要被 Metadata Extension／DDLX annotate 前要開這個開關」）。**這一課實測發現：`extend view`（加欄位）完全不需要這個開關，`ZI_CDS01_CARRIER` 建立時完全沒有加 `@Metadata.allowExtensions`，`extend view` 照樣一次成功**——證實「允許 Metadata Extension（加 UI Annotation）」跟「允許 Extend View（加欄位）」是兩種獨立的擴充機制，各自的啟用條件不同，不能拿其中一個的規則套用到另一個。

### 跟 DDIC Append Structure／Customer Include 的類比與差異

Enhancement 課程 en02 教過兩種幫**傳統 DDIC 表格**加欄位、不改原始碼的機制：Append Structure（掛一個額外結構上去）、Customer Include（表格自己預留 `include ci_<表名>;` 的插槽）。`extend view` 是同一個設計哲學在 **CDS View** 這一層的對應版本：

| | DDIC 表格層級（en02 教過） | CDS View 層級（這一課） |
|---|---|---|
| 機制 | Append Structure／Customer Include | `extend view` |
| 掛的對象 | 資料庫表格結構 | CDS View 的欄位清單 |
| 需不需要目標物件配合預留插槽 | Customer Include 需要（`include ci_xxx` 要事先存在）；Append Structure 不需要 | 不需要（這一課的 `ZI_CDS01_CARRIER` 完全沒有為擴充做任何準備） |
| 影響範圍 | 底層資料庫表格結構真的變寬 | 只影響這個 CDS View 的查詢結果欄位清單，底層表格完全不動 |

**核心共通點**：兩者都是「不修改原始碼、用一個獨立物件掛擴充內容上去」——這是 SAP 系統裡處理「別人的標準物件需要客製化」這個問題的一貫思路，只是每個物件層級（表格 vs. View）各自有專屬的實作機制。

### Eclipse ADT 建立 CDS View：Step by Step

1. 對著 `$TMP` 套件右鍵 → New → Other ABAP Repository Object → 篩選 `Data Definition` → Name `ZC_CDS09_CARRIER_EXT`（**注意物件名稱是這個 Extend 物件自己的名稱，不是 `ZI_CDS01_CARRIER`**）
2. Templates 畫面選 **Define View（obsolete as of AS ABAP 7.57）**（延續本課程一貫限制）——**不要**選 Reference Object（這次不是查表，是擴充另一個 View）
3. 手動打上面的完整內容
4. Ctrl+S → Activate
5. 重新讀取（Ctrl+Shift+A 搜尋）`ZI_CDS01_CARRIER`，確認原始碼完全沒變；用 Data Preview 查 `ZI_CDS01_CARRIER`，確認 `Status` 欄位出現且每列都是 `ACTIVE`

### 這一課學到的東西，接下來會怎麼用

- cds10（Custom Entity）：另一種「資料來源不是表格」的建模方式
- cds16（期末整合）：Extend View 可以用來幫最終案例的某個共用 View 補上進階篇才需要的欄位，不用回頭改基礎篇的物件

## Eclipse ADT Step by Step（重點回顧）

1. 建全新物件 `ZC_CDS09_CARRIER_EXT`（不是修改 `ZI_CDS01_CARRIER`）
2. Templates 選「Define View (obsolete as of AS ABAP 7.57)」，不選 Reference Object
3. `extend view ZI_CDS01_CARRIER with ZC_CDS09_CARRIER_EXT { ... }`
4. Activate 後，查詢 `ZI_CDS01_CARRIER`（目標物件，不是 Extend 物件）就能看到新欄位

## 學習目標

- 能寫出 `extend view <目標> with <自己的名稱> { ... }` 語法，並知道 `@AbapCatalog.sqlViewAppendName` 的作用
- 能講出「查詢新欄位要查目標 View（`ZI_CDS01_CARRIER`），不是查 Extend 物件本身（`ZC_CDS09_CARRIER_EXT`）」這個容易搞混的細節
- 能舉證「`extend view` 完全不修改目標物件原始碼」（用這一課的實測讀回結果佐證）
- 知道這系統上 `extend view` 不需要 `@Metadata.allowExtensions`，並能講出這跟 Metadata Extension（fe08 學到的規則）是兩種獨立機制的具體差異
- 能講出 `extend view` 跟 DDIC Append Structure／Customer Include 的類比關係（同一個設計哲學在不同物件層級的實作）

## 物件清單

| 物件 | 名稱 | 型別 |
|---|---|---|
| CDS Extend View | `ZC_CDS09_CARRIER_EXT` | `DDLS/DF` |
| 驗證程式 | `ZR_CDS09_DEMO` | `PROG/P` |

全部物件都在 `$TMP` 套件，已建立並啟用（讀取 active 版本內容與寫入內容逐字相符，且已確認 `ZI_CDS01_CARRIER` 原始碼未受影響）。

## 動手練習（留待後續補做）

1. 在 `ZI_CDS02_FLIGHT`（cds02 建的 View）上做一次 `extend view`，加一個新的常數欄位或簡單運算欄位
2. 試著在 `extend view` 的欄位清單裡加一個新的 Association（接到另一張你熟悉的表），驗證「透過 Association 帶進新關聯資料」這種進階用法是否可行
3. 建好後跟我核對語法

## 驗證方式

`ZR_CDS09_DEMO` 透過 `programrun` 無頭驗證，查詢 `ZI_CDS01_CARRIER`（原始物件，非 Extend 物件）確認新欄位 `Status` 正確出現：

```text
=== Query ZI_CDS01_CARRIER (original view, now carrying the extended field) ===
AA  American Airlines    ACTIVE
AB  Air Berlin           ACTIVE
AC  Air Canada           ACTIVE
AF  Air France           ACTIVE
AZ  Alitalia             ACTIVE
=== Sanity check: all rows carry Status = ACTIVE from the extension ===
MATCH: extended field Status is available on the original view, row count          5
```

同時已用 `sap_get_source(version=active)` 重新讀取 `ZI_CDS01_CARRIER`，確認內容跟 cds01 建立時逐字相符，證實 `extend view` 沒有改動目標物件的原始碼。

## 思考題

1. 如果兩個不同的團隊都對 `ZI_CDS01_CARRIER` 各自做了一次 `extend view`（各自加了不同的新欄位），你覺得最終查詢 `ZI_CDS01_CARRIER` 會不會同時看到兩邊加的欄位？
2. 如果 `ZI_CDS01_CARRIER` 本身以後被刪除或改名，掛在它上面的 `ZC_CDS09_CARRIER_EXT` 會發生什麼事？
3. 回顧「跟 DDIC Append Structure／Customer Include 的類比」那一節，你覺得 `extend view` 比較像哪一種（不需要目標配合預留插槽，還是需要）？

## 答案

見 `zc_cds09_carrier_ext.ddls.abap`、`zr_cds09_demo.prog.abap`。SAP 端物件：`ZC_CDS09_CARRIER_EXT`（Extend View）、`ZR_CDS09_DEMO`（驗證程式）。動手練習由你在 Eclipse 動手建立，稍後補做，沒有固定答案快照。
