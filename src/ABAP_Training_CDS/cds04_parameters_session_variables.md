# CDS View 課程練習 4：Parameters 與 Session Variables

## Lecture

### 這一課要教什麼

cds01～cds03 建的每個 CDS View，篩選條件（如果有的話）都是寫死的常數。cds02 的思考題 2 已經問過：「`DaysSinceYearStart` 用固定字串 `'20260101'` 當參考日寫死在 CDS View 裡，這樣設計有什麼潛在問題？」——這一課要正式回答這個問題，教兩個讓 CDS View 變得「動態」的機制：

1. **Parameters**：讓消費端在查詢時**主動傳入**一個值，View 內部用這個值做篩選或運算
2. **Session Variables**：View 內部**自動取用**當下執行環境的系統資訊（今天日期、目前使用者），不需要消費端傳入

兩者都是「讓 CDS View 不要把值寫死」的手段，差別在於：Parameters 的值由消費端決定，Session Variables 的值由系統當下狀態決定。

### 語法元素講解

**① `with parameters` 宣告**：寫在 `define view <名稱>` 之後、`as select from` 之前：

```abap
define view ZI_CDS04_FLIGHT
  with parameters
    p_carrid : s_carr_id
  as select from sflight
{ ... }
```

- 參數名稱習慣上以 `p_` 開頭（跟 Association 的 `_` 前綴一樣，是慣例不是語法強制）
- 型別（這裡 `s_carr_id`）通常直接引用一個既有的 Data Element，這樣參數才會自動帶有正確的長度跟語意
- 可以宣告多個參數，用逗號分隔

**② `$parameters.<name>`**：在 View 內部（`WHERE` 子句、`ON` 條件、欄位運算式都可以）引用參數目前的值：

```abap
where carrid = $parameters.p_carrid
```

**⚠️ WHERE 子句在這系統的位置**：寫在整個欄位清單 `{ }` 的**後面**，不是 `select from` 跟 `{ }` 中間——這跟一般 SQL 直覺（`WHERE` 通常緊接在 `FROM` 之後）不一樣，這系統的舊式 `define view` 語法要求 `WHERE` 放在最後：

```abap
define view ZI_CDS04_FLIGHT
  with parameters
    p_carrid : s_carr_id
  as select from sflight
{
  ...欄位清單...
}
where carrid = $parameters.p_carrid
```

**③ Open SQL 呼叫帶參數的 CDS View**：消費端（ABAP 程式）查詢時，參數值用小括號＋等號傳入：

```abap
SELECT carrid, connid, fldate
  FROM zi_cds04_flight( p_carrid = 'AA' )
  INTO TABLE @DATA(lt_result).
```

**④ 內建 Session Variable**：不用宣告，直接在 View 內部使用 `$session.<name>`：

| Session Variable | 意思 |
|---|---|
| `$session.system_date` | 執行當下的系統日期 |
| `$session.system_time` | 執行當下的系統時間 |
| `$session.user` | 目前執行這個查詢的使用者帳號 |
| `$session.client` | 目前的 Client（一般不需要手動用到，Open SQL／CDS 本來就會自動處理 Client 隔離） |

```abap
$session.user   as QueriedByUser
```

**⚠️ 這系統實測出來的一個限制**：`$session.system_date` 直接當作內建函數的參數傳進去會報錯：

```text
Function DATS_DAYS_BETWEEN: At position  1, only Expressions,Literals,Columns,P allowed
```

要先用 `CAST` 包一層（即使目標型別跟原本型別相同）才會被接受成合法的函數參數：

```abap
dats_days_between( cast( $session.system_date as abap.dats ), fldate )   as DaysFromToday
```

啟用時會多一句無害的警告（`CAST SESSION_CONTEXT('SAP_S... to identical type DATS`，代表「你在做一個型別沒變的 CAST」），這只是提醒、不擋啟用。**但如果只是拿 `$session.system_date` 做單純比較（不當函數參數），不需要這個 CAST**，直接寫 `fldate < $session.system_date` 就可以（這一課的 `TimeStatus` 分類就是這樣寫，也符合 cds02 教過的「CASE WHEN 條件只能用純欄位/常數比較」的限制——`$session.system_date` 是系統變數，不是運算式或函數呼叫，可以安全放進 `CASE WHEN` 條件裡）。

### 完整範例：`ZI_CDS04_FLIGHT`

```abap
@AbapCatalog.sqlViewName: 'ZICDS04FLGT'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS04: Flight with Parameters and Session Variables'
define view ZI_CDS04_FLIGHT
  with parameters
    p_carrid : s_carr_id
  as select from sflight
{
  key carrid,
  key connid,
  key fldate,
      price,
      currency,
      seatsmax,
      seatsocc,

      dats_days_between( cast( $session.system_date as abap.dats ), fldate )   as DaysFromToday,

      $session.user                                        as QueriedByUser,

      case
        when fldate < $session.system_date then 'PAST'
        when fldate = $session.system_date then 'TODAY'
        else                                     'FUTURE'
      end                                                    as TimeStatus
}
where carrid = $parameters.p_carrid
```

這個範例直接回答了 cds02 思考題 2：`DaysSinceYearStart` 原本寫死參考日 `'20260101'`，現在換成 `$session.system_date`，每次查詢都會自動用「執行當下的今天」當參考日，不用每次改程式碼、也不會因為時間過去而讓寫死的日期變得不合理。

### 動態篩選的應用場景

Parameters 最常見的用途是讓同一個 CDS View 服務不同的呼叫端，各自篩選出自己需要的子集——例如這一課的 `p_carrid`，讓消費端可以選擇要查 `AA` 還是 `LH`，不需要為每家航空公司各建一個專屬 View。Session Variables 最常見的用途是「跟執行環境相關、但不該讓消費端每次手動傳入」的資訊——像「今天」「目前使用者」這種資訊，讓消費端每次呼叫都要記得傳，既麻煩又容易出錯（今天忘記更新、傳錯使用者），系統自動取用才是合理設計。

### Eclipse ADT 建立 CDS View：Step by Step

1. 對著 `$TMP` 套件右鍵 → **New** → **Other ABAP Repository Object** → 篩選 `Data Definition` → **Next**
2. Name：`ZI_CDS04_FLIGHT`，Description：`CDS04 Parameters and Session Variables`，Package：`$TMP` → **Next** → Transport 畫面直接 **Finish**
3. Templates 畫面選 **Define View（obsolete as of AS ABAP 7.57）**
4. Reference Object 選 `SFLIGHT`
5. 改成上面「完整範例」的內容——**注意 `with parameters` 這段要寫在 `define view` 跟 `as select from` 中間，`where` 子句要寫在整個欄位清單 `{ }` 之後**
6. **Ctrl+S** 存檔 → **Activate**（Ctrl+F3）
7. 右鍵 → **Open With** → **Data Preview**——因為這個 View 有宣告 Parameters，Data Preview 打開時會先跳出一個輸入框要求填 `p_carrid` 的值（例如輸入 `AA`），填完才會顯示查詢結果，這是 Parameters 化 CDS View 特有的行為

### 這一課學到的東西，接下來會怎麼用

- cds05：分層設計——這一課的 Parameters 會被拿來示範「疊層時怎麼把參數轉傳給下一層」（語法跟 Open SQL 呼叫不一樣，用冒號不是等號）
- cds06：Access Control——`$session.user` 除了拿來顯示，也是權限控管情境常會用到的資訊
- cds08（期中整合）：把 Parameters／Session Variables 一起疊進最終案例

## Eclipse ADT Step by Step（重點回顧）

1. 對著 `$TMP` 套件右鍵 → New → Other ABAP Repository Object → `Data Definition`
2. 填 Name／Description／Package，Transport 畫面直接 Finish
3. Templates 畫面選「Define View (obsolete as of AS ABAP 7.57)」
4. 選 `SFLIGHT` 當 Reference Object
5. 改成本課要求的完整內容，注意 `with parameters` 跟 `where` 子句的位置
6. Ctrl+S 存檔 → Activate
7. Data Preview 會先跳出參數輸入框，填值後才看得到結果

## 學習目標

- 能寫出 `with parameters` 宣告，並用 `$parameters.<name>` 在 `WHERE` 子句裡引用參數值
- 知道這系統的 `WHERE` 子句要寫在整個欄位清單 `{ }` 之後，不是緊接在 `FROM` 之後
- 能講出 Open SQL 呼叫帶參數 CDS View 的語法（小括號＋等號：`view( p1 = value1 )`）
- 能寫出至少兩個內建 Session Variable（`$session.system_date`／`$session.user`）並知道各自的用途
- 知道 `$session.system_date` 當函數參數用時，這系統要求先 `CAST`（即使型別沒變），但當純比較用時不需要
- 能講出 Parameters 跟 Session Variables 的本質差異：前者由消費端決定值，後者由系統當下狀態決定值
- 能判斷什麼情境該用 Parameters（同一個 View 服務不同篩選需求）、什麼情境該用 Session Variables（跟執行環境相關、不該要求消費端每次手動傳入的資訊）

## 物件清單

| 物件 | 名稱 | 型別 |
|---|---|---|
| CDS Interface View | `ZI_CDS04_FLIGHT` | `DDLS/DF` |
| 驗證程式 | `ZR_CDS04_DEMO` | `PROG/P` |

全部物件都在 `$TMP` 套件，已建立並啟用（讀取 active 版本內容與寫入內容逐字相符）。

**動手練習物件**（你自己動手建，名稱自訂，不算在上面正式的課程物件清單裡）：

| 物件 | 建議名稱 | 型別 | 對應練習 |
|---|---|---|---|
| CDS View（`SPFLI`，帶 Parameters） | `ZI_CDS04_ROUTE`（自訂） | `DDLS/DF` | 動手練習 |

## 動手練習

**輪到你了**：用標準表 `SPFLI` 建一個新的 CDS View（物件名稱、套件 `$TMP`，命名自訂，例如 `ZI_CDS04_ROUTE`），要求：

1. 宣告一個 Parameter `p_cityfrom`（型別可以參考 `SPFLI-CITYFROM` 用的 Data Element `S_FROM_CIT`），用來篩選「從某個城市出發」的航線
2. `WHERE` 子句用 `$parameters.p_cityfrom` 篩選 `cityfrom`
3. 加一個欄位用 `$session.user` 顯示查詢者
4. 用 Data Preview 驗證：填入一個真實存在的出發城市（例如 `FRANKFURT`），確認只查得到從那個城市出發的航線

建好、啟用成功後跟我說一聲（貼程式碼或截圖都可以），我會幫你核對語法。

**如果你想額外挑戰一下**：試著把 `$session.system_date` 直接當函數參數傳給 `DATS_DAYS_BETWEEN`（不加 CAST），實際看一次啟用失敗的錯誤訊息，再加回 `CAST` 修正——親眼看過這個錯誤，比只是讀講義印象更深。

## 驗證方式

`ZR_CDS04_DEMO` 透過 `programrun` 無頭驗證，分別用不同的參數值查詢，確認：

1. 參數篩選正確生效（`p_carrid = 'AA'` 查出來的資料全部是 `AA`）
2. 換一個參數值（`p_carrid = 'LH'`）查出完全不同的資料集
3. `QueriedByUser` 正確顯示執行查詢的使用者
4. `TimeStatus` 正確依 `$session.system_date` 分類

實際執行結果：

```text
=== 1. Parameterized query: p_carrid = AA ===
AA  0017 2018/10/29      2,852- PAST   MONICA
AA  0017 2018/11/30      2,820- PAST   MONICA
AA  0017 2019/01/01      2,788- PAST   MONICA
AA  0017 2019/02/02      2,756- PAST   MONICA
AA  0017 2019/03/06      2,724- PAST   MONICA
=== 2. All rows have carrid = AA? ===
MATCH: parameter filter applied correctly, row count          5
=== 3. Parameterized query: p_carrid = LH (different parameter value) ===
LH  0400 2018/09/30 PAST
LH  0400 2018/11/01 PAST
LH  0400 2018/12/03 PAST
=== 4. System date used for comparison ===
sy-datum: 2026/08/20
```

`p_carrid = 'AA'` 只查到 `AA` 的資料、換成 `'LH'` 立刻查到不同的資料集，證實 Parameters 篩選正確生效；`QueriedByUser` 正確顯示 `MONICA`；因為系統日期是 `2026/08/20`（第 4 段的 `sy-datum` 佐證），所有測試資料（航班日期都在 2018～2019 年）自然全部落在 `PAST`，`DaysFromToday` 也正確顯示負值（距今幾千天前）。

**動手練習的驗證方式**：Eclipse 啟用成功＋用 Data Preview 看查詢結果，貼程式碼給我核對語法。

## 思考題

1. 這一課的 Parameter `p_carrid` 沒有預設值，代表**每次查詢都一定要傳**，不傳會怎麼樣？（提示：親自在 Eclipse 的 Data Preview 畫面試試看，如果輸入框留空直接確認）
2. `$session.user` 顯示的是「執行這個查詢的技術使用者」（這一課看到的是 `MONICA`，也就是 MCP 連線帳號），如果同一個 CDS View 之後被 Fiori Elements 或別的應用程式呼叫，`$session.user` 顯示的值會不會不一樣？為什麼？
3. cds02 的 `DaysSinceYearStart` 用寫死常數 `'20260101'`，這一課的 `DaysFromToday` 改用 `$session.system_date`——如果你現在想比較兩個版本在「明年」執行會有什麼不同結果，你能想像得出來嗎？
4. 如果一個 CDS View 同時宣告了 Parameters 又用了 Session Variables，你覺得哪一種資訊比較適合當 Parameter、哪一種比較適合當 Session Variable？回顧「動態篩選的應用場景」那一節，試著用自己的話重新歸納一次判斷原則。

## 答案

見 `zi_cds04_flight.ddls.abap`、`zr_cds04_demo.prog.abap`。SAP 端物件：`ZI_CDS04_FLIGHT`（CDS View）、`ZR_CDS04_DEMO`（驗證程式）。動手練習（基於 `SPFLI` 帶 Parameters 的 CDS View）由你在 Eclipse 動手建立，沒有固定答案快照——建好後跟我核對即可。
