# 講義 21：建立 Z 資料表與 Open SQL 寫入（授課順序：接在講義 9（ALV）之後；Global Type 觀念回顧講義 25）

> 對應練習：[ex21](../ex21_ztable.md)｜答案物件：資料表 `ZTR21_STUD` + `ZTR21_CLASS`＋程式 `ZR_TR21_ZTABLE`

## 本講重點

- DDIC 三層件：Domain → Data Element → 表格欄位，各管什麼
- SE11 建立透明表：鍵欄位、Delivery Class、Technical Settings
- SM30 維護畫面（Table Maintenance Generator），以及一次維護多張表的 **Maintenance View**
- **Header／Detail 兩表關聯**：外鍵（Foreign Key）與檢查表（Check Table）
- **Search Help**：F4 值清單怎麼來的，跟外鍵的差別；需要多張表時的 **Help View**
- Open SQL 寫入：`INSERT` / `UPDATE` / `MODIFY` / `DELETE`
- LUW 與 `COMMIT WORK` / `ROLLBACK WORK` 觀念

## 1. DDIC 三層件：欄位是怎麼組成的

講義 6 學過「讀」標準表；講義 25 講過 DDIC 的系統地圖與 Global Type 觀念（何時重用標準型別、何時自建）——本講接著把「自建」這條路完整動手走一次：客製開發常需要自己的表存資料（參數表、log 表、暫存表——本專案的 ZDQM 系列就有）。SE11 的欄位定義是三層疊起來的：

| 層 | 管什麼 | 例 |
|---|---|---|
| **Domain（值域）** | **技術屬性**：型別、長度、小數位、允許值清單（Value Range）、轉換常式 | INT4、值域 0～999 |
| **Data Element（資料元素）** | **語意**：欄位標籤（F1 說明、畫面上的欄位名稱，可多語言） | 「學生成績」 |
| 表格欄位 | 引用一個 Data Element（或直接用內建型別） | `SCORE TYPE ztr21_score` |

為什麼分三層？**重複利用與一致性**：十張表都有「成績」欄位時，共用同一個 Data Element，標籤、F1 說明、值域全系統一致，改一處全生效。標準表的欄位全是這樣組的——這也是為什麼 `TYPE scarr-carrid` 能帶出那麼多語意（講義 6）。

實務折衷：**鍵欄位與有業務意義的欄位用 Data Element**；純技術性欄位（旗標、備註）可直接用內建型別（CHAR、INT4…）省事。課程練習兩種都做。

## 2. SE11 建立透明表

步驟（細節照練習 ex21 的規格做）：

1. SE11 → Database table → 輸入 `ZTR21_STUD` → Create
2. **Delivery Class**：`A`（應用資料，最常用）。速查：

| Class | 用途 |
|---|---|
| `A` | 應用資料（主檔/交易資料）——**預設選它** |
| `C` | 客戶自訂設定檔（Customizing，會跟著 TR 搬） |
| `L` | 暫存資料 |

3. Data Browser/Table View Maint.：選 `Display/Maintenance Allowed`（之後 SE16N/SM30 才能維護）
4. **Fields 頁籤**：第一欄一定是 `MANDT TYPE mandt` 且勾 **Key**（client 隔離，講義 0/6）；接著鍵欄位、資料欄位
5. **Technical Settings**（必填才能啟用）：Data Class `APPL0`（主檔類）、Size Category `0`（預估筆數級距，練習表選最小）
6. Enhancement Category（選單 Extras）：選 `Can be enhanced` 或 `Cannot be enhanced` 皆可（練習表無所謂，正式表依團隊規範）
7. 啟用（Ctrl+F3）——表就真的建在資料庫了，SE16N 可立刻查

> 命名：客製表 `Z` 開頭（本課 `ZTR21_STUD`）；欄位名限 16 字元。**表建錯欄位型別，上線後要改很痛**（要做轉檔），設計階段多想一分鐘。

## 3. SM30 維護畫面

讓使用者（或顧問）不寫程式就能維護表內容：

1. **先建 Function Group**：SE80 → 下拉選 Function Group → 輸入 `ZFG_TR21` → Yes → 填 Short Text → 存檔（Function Group 是產生出來的維護畫面程式的容器，講義 15 學過；Table Maintenance Generator 只能放進**已經存在**的 Function Group）
2. SE11 該表 → Utilities → **Table Maintenance Generator**
3. Authorization Group 練習用 `&NC&`（不檢核）；Function Group 填 `ZFG_TR21`；Maintenance type 選 one step（單畫面）
4. 產生後，SM30 輸入表名 → Maintain，就有現成的新增/修改/刪除畫面

實務上參數表、對照表幾乎都配 SM30；正式環境的維護權限與是否產 TR 由 Delivery Class 與權限控制。

### 3.1 Maintenance View：SM30 一次維護多張相關的表

上面的做法是對**一張表**產生維護畫面。實務上很常遇到「一筆資料分在兩張表」：例如幣別代碼放在 `TCURC`，幣別的中英文說明放在文字表 `TCURT`（每種語言一筆）。如果分開維護，使用者要進兩次 SM30，新增一個幣別還得記得去另一張表補說明。

**Maintenance View** 把這兩張表組成一個維護畫面。系統標準的 `V_TCURC` 就是這樣（2026-09-29 查系統定義）：

| 項目 | `V_TCURC` 的內容 |
|---|---|
| 主表（Primary Table） | `TCURC`（幣別代碼） |
| 附屬表（Secondary Table） | `TCURT`（幣別說明，文字表） |
| 欄位 | `WAERS`、`ISOCD`、`ALTWR`（來自 TCURC）、`LTEXT`（來自 TCURT） |

SM30 輸入 `V_TCURC` → Display 就能看到：同一個畫面上，代碼和說明在同一列，新增幣別時說明一起填，存檔時系統自動寫進兩張表。附屬表是**文字表**時，系統會自動只取「登入語言」那一筆說明。

規則（官方文件 `ABENDDIC_MAINTENANCE_VIEWS`）：

- 表與表之間**必須有外鍵**，連接條件直接沿用外鍵，不能自己寫（跟 Database View 不同）。
- 附屬表對主表必須是**多對一**，也就是主表每一筆最多對到附屬表一筆，存檔時才寫得回去。所以最典型的用法就是「主檔＋文字表」。
- 是 INNER JOIN；**程式不能 SELECT Maintenance View**，只能當 `TYPE` 用。程式要讀資料，還是直接讀那兩張表（或用 JOIN）。
- 各欄位可以設維護屬性，例如「唯讀」、「隱藏」。

建立步驟（SE11，GUI 操作）：

1. SE11 → **View** → 輸入名稱（如 `ZV_TR21_XXX`）→ Create → 類型選 **Maintenance view**
2. **Table/Join Conditions** 頁籤：填主表 → 按 **Relationships**，勾要加入的附屬表（系統依外鍵帶出連接條件）
3. **View Fields** 頁籤：按 **Table fields** 選要出現的欄位；主表的 Key 欄位必須全部包含
4. **Maint. Status** 頁籤：Access 選 `Read, change, delete and insert`。如果這個 View 只給人查詢，改選 `Read only`：SM30 開這個 View 時只能顯示，畫面上沒有 Change／Display 切換按鈕，有維護權限的人也改不了（講義 13 傳票清單 ZRFI0004 的查詢按鈕 `ZFI0037Q` 就是這樣做的）
5. 啟用 → Utilities → **Table Maintenance Generator**，跟上面一張表的做法一樣產生維護畫面
6. SM30 輸入 View 名稱測試

> 以上 SE11 畫面的按鈕與頁籤名稱依一般 SAP GUI 版本整理，如果你看到的畫面不一樣，請回報，講義會再修正。

## 4. Header／Detail 關聯：外鍵（Foreign Key）與檢查表（Check Table）

實務上很少有表是孤立的：訂單表要串客戶主檔、明細表要串產品主檔——本質都是「**Header（主檔，1 那一邊）／Detail（明細，多那一邊）**」的關聯。本課用「班級（Header）－學生（Detail）」示範，跟講義 6 的 SCARR（航空公司）－SPFLI（航線）是同一種關係，只是這次自己動手建。

### 4.1 觀念：Check Table 是什麼

- **檢查表（Check Table）**：被參考的那張表（本例 `ZTR21_CLASS`），扮演「合法值清單」的角色
- **外鍵表（Foreign Key Table）**：帶外鍵欄位的表（本例 `ZTR21_STUD` 的 `KLASSE` 欄位），欄位值必須存在於檢查表裡
- 一對多：一個班級（Header）可以有多個學生（Detail），Cardinality 設 `Many : 1`（本例的「多」是學生、「1」是班級）

SE11 用 Dictionary DDL（新版原始碼式編輯）寫的話，語法長這樣（跟講義 6 的 `SPFLI` 外鍵到 `SCARR` 是同一套）：

```abap
define table ztr21_stud {
  ...
  @AbapCatalog.foreignKey.label : 'Check Against Class'
  @AbapCatalog.foreignKey.screenCheck : true
  klasse : ztr21_klasse
    with foreign key [0..*,1] ztr21_class
      where mandt  = ztr21_stud.mandt
        and klasse = ztr21_stud.klasse;
  ...
}
```

`[0..*,1]`：左邊 `0..*` 是外鍵表這一側（多筆學生都可以指到同一班級，也可以還沒指定）、右邊 `1` 是檢查表那一側（每個 KLASSE 值在 `ZTR21_CLASS` 剛好對應 1 筆）。

### 4.2 外鍵只在「畫面輸入」擋人，不是資料庫 constraint

這是本題**最容易搞錯**的地方：`@AbapCatalog.foreignKey.screenCheck : true` 只影響**Dynpro 畫面**（SM30、Module Pool 的輸入欄位）在使用者離開欄位時做檢查——**Open SQL 的 `INSERT`/`UPDATE`/`MODIFY` 完全不會被擋**，程式塞一個 `ZTR21_CLASS` 沒有的班級代碼一樣會成功（`sy-subrc = 0`）。想在程式層也擋，要自己 `SELECT SINGLE` 檢查檢查表存不存在該筆，這不是系統自動做的事。

（跟其他資料庫的「Foreign Key Constraint」不一樣：那是資料庫引擎強制擋寫入；SAP DDIC 外鍵是應用層／畫面層的檢核機制，這個落差是很多人踩過的坑。）

### 4.3 Search Help：F4 選單哪裡來的

Search Help（搜尋輔助）解決的是另一個問題：**使用者不用背代碼，可以用 F4 選**。跟外鍵是兩件事——外鍵負責「擋不合法的值」，Search Help 負責「幫你選合法的值」，兩者可以疊加也可以只設一個：

- 只設外鍵沒設 Search Help：畫面會擋錯誤輸入，但沒有 F4 選單，要自己背代碼
- 只設 Search Help 沒設外鍵：F4 能選，但使用者若不透過 F4、手動打一個不存在的代碼，畫面不會擋

建立方式（SE11 → Search Help → Elementary Search Help）：
- **Selection Method**：資料來源表（本例 `ZTR21_CLASS`）
- **Search Help Parameters**：每個要出現在選單裡的欄位；哪一個是「查完之後要帶回畫面」的欄位（本例 `KLASSE`）勾 Import+Export+SH field，純顯示用的欄位（`KLNAME`）只勾 Export
- 建好後要**掛到 Data Element**（`ZTR21_KLASSE` 的 Further Characteristics 頁籤填 Search Help 名稱）才會在所有用到這個 DE 的欄位自動生效——這也是三層件「改一處全生效」精神的延伸

> **實測踩過的坑**：Selection Method 表（`ZTR21_CLASS`）裡每個要當 Search Help Parameter 的欄位，都必須引用一個 **Data Element**——`KLNAME` 一開始貪方便直接用內建型別 `CHAR(40)`，結果 Search Help **Activate 失敗**。Search Help 靠 Data Element 才能解析欄位的語意（標籤、型別），純內建型別的欄位沒有這層資訊可以掛。這也是三層件「共用 Data Element」精神的另一個實際理由：不是只有標籤好看，Search Help 這種進階功能還真的依賴它。

### 4.4 Help View：Search Help 需要多張表的資料時

Search Help 的 **Selection Method**（資料來源）可以是三種東西：一張表、一個 Database View（講義 11 §2.1），或一個 **Help View**。

- **一張表**：資料都在同一張表時用。如果只是要加上這張表的「文字表」說明，**不需要 Help View**，Selection Method 直接填主表，文字表的欄位也能當 Search Help 的參數（官方文件的建議）。
- **Help View**：需要從其他相關表帶出補充資訊時用。它跟 Database View 最大的差別是 **OUTER JOIN**：主表每一筆都一定會出現，附屬表找不到對應資料時，那些欄位就留空，不會把整筆資料排除掉。系統標準範例 `H_T005` 就是國家 `T005` 加國家名稱 `T005T`。

| | Database View 當來源 | Help View 當來源 |
|---|---|---|
| JOIN 種類 | INNER：附屬表沒資料，整筆消失 | OUTER：主表全部出現，附屬欄位留空 |
| 連接條件 | 自己定 | 必須沿用外鍵 |
| 程式能不能 SELECT | 可以 | 不行，只給 Search Help 用 |
| 適合 | 常用附屬表的欄位來篩選 | 附屬表只是補充說明 |

以「F4 選國家要順便看到國家名稱」為例：用 INNER JOIN 的話，還沒維護名稱的國家就不會出現在選單裡，使用者以為沒有這個國家；用 Help View 的 OUTER JOIN，國家照樣出現，只是名稱空白。

建立方式：SE11 → View → 類型選 **Help view**，後面的 Table/Join Conditions、View Fields 步驟跟 3.1 的 Maintenance View 一樣（連接條件同樣要沿用外鍵）；建好後在 Search Help 的 Selection Method 填這個 View 名稱。

## 5. Open SQL 寫入

讀是 SELECT；寫有四個指令，全部**用 sy-subrc 回報結果**（鐵律不變），`sy-dbcnt` 是影響筆數：

```abap
DATA gs_stud TYPE ztr21_stud.        " 直接用表名當結構型別

* INSERT：新增一筆；主鍵已存在 → sy-subrc = 4，不會蓋掉
gs_stud-id    = 'S0001'.
gs_stud-name  = '王小明'.
gs_stud-score = 85.
INSERT ztr21_stud FROM gs_stud.

* UPDATE：改既有資料；找不到 → sy-subrc = 4
UPDATE ztr21_stud SET score = 90 WHERE id = 'S0001'.

* MODIFY：有就改、沒有就新增（upsert）——參數表最愛用
MODIFY ztr21_stud FROM gs_stud.

* DELETE：刪除
DELETE FROM ztr21_stud WHERE id = 'S0001'.
```

多筆版本：`INSERT ztr21_stud FROM TABLE gt_stud.`（UPDATE/MODIFY/DELETE 同理有 `FROM TABLE`）。注意 INSERT FROM TABLE 遇到**任一筆主鍵重複就整批 dump**，除非加 `ACCEPTING DUPLICATE KEYS`（重複的跳過、sy-subrc = 4）。

- MANDT 欄位一樣不用（不要）自己塞，系統自動帶當前 client。
- 寫入欄位建議程式帶齊稽核欄（如異動者 `sy-uname`、異動日 `sy-datum`）——查問題時會感謝自己。

## 6. LUW 與 COMMIT WORK

資料庫的變更不是逐句永久生效，而是以 **LUW（Logical Unit of Work）**為單位，最後一次「確認」才真正落地：

```abap
INSERT ztr21_stud FROM gs_stud.
IF sy-subrc <> 0.
  ROLLBACK WORK.                " 整包撤銷：這個 LUW 內所有寫入取消
  MESSAGE '寫入失敗，已回復' TYPE 'E'.
ENDIF.
COMMIT WORK.                    " 整包確認：全部永久生效
```

- **概念**：一個業務動作的多筆寫入（如表頭＋明細）必須「全成功或全失敗」，不能寫一半——這就是 LUW 的意義。
- 報表程式跑完（或畫面切換）時系統會**隱含 commit**——所以練習程式沒寫 COMMIT WORK 資料多半也進去了，但**正式程式的寫入要明確 COMMIT／ROLLBACK**，把「哪裡算一個完整動作」寫清楚。
- 多人同時改同一筆怎麼辦？正式做法要配 **Lock Object**（SE11 建 `EZ...`，產生 ENQUEUE/DEQUEUE FM）——本課先認識名詞，實作屬進階課題。

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 表啟用不了 | Technical Settings 沒填（Data Class / Size Category） |
| SE16N 看不到剛寫的資料 | 寫入時 sy-subrc 其實是 4（沒檢查）；或在別的 client 查 |
| INSERT 一直 subrc = 4 | 主鍵重複——練習程式重跑前先 DELETE 舊測試資料，或改用 MODIFY |
| INSERT FROM TABLE 直接 dump | 批次裡有主鍵重複，沒加 ACCEPTING DUPLICATE KEYS |
| SM30 說表不能維護 | 建表時 Data Browser/Table View Maint. 選了不允許，或沒產 Maintenance 畫面 |
| 自己塞 MANDT | 不用，系統自動處理（跟 SELECT 一樣） |
| 以為外鍵能擋住程式寫入的髒資料 | 外鍵（screenCheck）只管畫面輸入，Open SQL 不受影響（見 4.2） |
| DE 掛了 Search Help 但 F4 還是沒選單 | Search Help 本身沒啟用，或掛的是舊版本；兩邊都要各自啟用一次 |
| Search Help 存檔/Activate 失敗 | Selection Method 表裡的欄位（如 `KLNAME`）沒引用 Data Element，只用了內建型別 |
| JOIN 兩表時把 MANDT 寫進 ON 條件 | 語法錯誤（GYA）：client 欄位由編譯器自動處理，不可在 ON 裡明寫 |

## 8. 課堂練習

完成 [ex21](../ex21_ztable.md)：建 Domain＋Data Element＋透明表 `ZTR21_STUD`、產 SM30 維護畫面；再建 Header 表 `ZTR21_CLASS`、幫 `KLASSE` 欄位設外鍵與 Search Help；最後寫程式跑完 INSERT / UPDATE / MODIFY / DELETE 全流程＋外鍵行為驗證＋JOIN，並驗證 sy-subrc。
