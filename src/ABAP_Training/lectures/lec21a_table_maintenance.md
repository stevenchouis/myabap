# 講義 21a：Maintenance View、Help View 與 JOIN 串 Z 表（授課順序：接在講義 12 之後、講義 13 之前）

> 對應練習：[ex21a](../ex21a_table_maintenance.md)｜答案物件：程式 `ZR_TR21A_JOIN`
>
> 延續[講義 21](lec21_ztable.md) 建好的 `ZTR21_STUD`（學生）、`ZTR21_CLASS`（班級）與 SM30 維護畫面。本講需要 JOIN（講義 11），所以放在這裡；學完接著上第一階段總整理（講義 13），傳票清單的會計主管表 `ZFI0037` 就是用本講的手法維護。

## 本講重點

- **Maintenance View**：SM30 一次維護多張相關的表；設成 `Read only` 做查詢專用
- **Help View**：Search Help 需要多張表的資料時
- 用 JOIN 把 Header／Detail 兩張 Z 表串起來讀

## 1. Maintenance View：SM30 一次維護多張相關的表

講義 21 的做法是對**一張表**產生維護畫面。實務上很常遇到「一筆資料分在兩張表」：例如幣別代碼放在 `TCURC`，幣別的中英文說明放在文字表 `TCURT`（每種語言一筆）。如果分開維護，使用者要進兩次 SM30，新增一個幣別還得記得去另一張表補說明。

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
4. **Maint. Status** 頁籤：Access 選 `Read, change, delete and insert`。如果這個 View 只給人查詢，改選 `Read only`：SM30 開這個 View 時只能顯示，畫面上沒有 Change／Display 切換按鈕，有維護權限的人也改不了（下一講，講義 13 的傳票清單 ZRFI0004，查詢按鈕 `ZFI0037Q` 就是這樣做的）
5. 啟用 → Utilities → **Table Maintenance Generator**，跟講義 21 一張表的做法一樣產生維護畫面
6. SM30 輸入 View 名稱測試

> 以上 SE11 畫面的按鈕與頁籤名稱依一般 SAP GUI 版本整理，如果你看到的畫面不一樣，請回報，講義會再修正。

## 2. Help View：Search Help 需要多張表的資料時

Search Help 的 **Selection Method**（資料來源）可以是三種東西：一張表（講義 21 的 `ZTR21_CLASSH` 就是）、一個 Database View（講義 11 §2.1），或一個 **Help View**。

- **一張表**：資料都在同一張表時用。如果只是要加上這張表的「文字表」說明，**不需要 Help View**，Selection Method 直接填主表，文字表的欄位也能當 Search Help 的參數（官方文件的建議）。
- **Help View**：需要從其他相關表帶出補充資訊時用。它跟 Database View 最大的差別是 **OUTER JOIN**：主表每一筆都一定會出現，附屬表找不到對應資料時，那些欄位就留空，不會把整筆資料排除掉。系統標準範例 `H_T005` 就是國家 `T005` 加國家名稱 `T005T`。

| | Database View 當來源 | Help View 當來源 |
|---|---|---|
| JOIN 種類 | INNER：附屬表沒資料，整筆消失 | OUTER：主表全部出現，附屬欄位留空 |
| 連接條件 | 自己定 | 必須沿用外鍵 |
| 程式能不能 SELECT | 可以 | 不行，只給 Search Help 用 |
| 適合 | 常用附屬表的欄位來篩選 | 附屬表只是補充說明 |

以「F4 選國家要順便看到國家名稱」為例：用 INNER JOIN 的話，還沒維護名稱的國家就不會出現在選單裡，使用者以為沒有這個國家；用 Help View 的 OUTER JOIN，國家照樣出現，只是名稱空白。

建立方式：SE11 → View → 類型選 **Help view**，後面的 Table/Join Conditions、View Fields 步驟跟第 1 節的 Maintenance View 一樣（連接條件同樣要沿用外鍵）；建好後在 Search Help 的 Selection Method 填這個 View 名稱。

## 3. 程式裡把兩張 Z 表串起來讀

Maintenance View、Help View 都不能在程式裡 `SELECT`。程式要讀「學生＋班級名稱」，直接用講義 11 的 JOIN：

```abap
SELECT s~id s~name s~klasse c~klname
  FROM ztr21_stud AS s
  LEFT OUTER JOIN ztr21_class AS c
    ON c~klasse = s~klasse
  INTO CORRESPONDING FIELDS OF TABLE gt_join
  ORDER BY s~id.
```

- 用 `LEFT OUTER JOIN`：講義 21 的練習程式故意寫進一筆班級代碼 `ZZZZ`（不存在），INNER JOIN 會把這個學生整筆漏掉；LEFT OUTER 會保留，只是班級名稱空白。
- `ON` 條件**不能**寫 `MANDT`：client 欄位由編譯器自動處理，寫了會語法錯誤（GYA）。
- 班級代碼有值、班級名稱卻是空的，就是「外鍵沒擋住的髒資料」，程式可以用這個條件把它們找出來。

## 4. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| 程式 `SELECT` Maintenance View 語法錯誤 | Maintenance View／Help View 只能給 SM30／Search Help 用，程式改讀原表或用 JOIN |
| JOIN 兩表時把 MANDT 寫進 ON 條件 | 語法錯誤（GYA）：client 欄位由編譯器自動處理，不可在 ON 裡明寫 |

## 5. 課堂練習

完成 [ex21a](../ex21a_table_maintenance.md)：建一個唯讀的 Maintenance View；最後寫程式用 LEFT OUTER JOIN 串學生與班級，並找出班級不存在的學生。
