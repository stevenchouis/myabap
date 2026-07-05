# 練習 23：期末整合練習——訂單 Header/Detail

> 授課順序：接在練習 21（Z 資料表／外鍵／Search Help）之後，作為基礎課的第二個期末整合練習（第一個是 ex13）。講義見 [lec23](lectures/lec23_orders.md)。

## 學習目標

- 綜合運用 ex21 學過的 DDIC 三層件、外鍵（Foreign Key／Check Table）、Search Help，做一個貨真價實的**訂單 Header/Detail**（單頭/單身）資料模型——跟 SAP 標準的 VBAK/VBAP（銷售訂單）、EKKO/EKPO（採購單）是同一種結構
- 親手驗證 **LUW（Logical Unit of Work）「全成功或全失敗」**：Header 和 Detail 在同一筆交易裡，只要有一步失敗就整包撤銷，不留下「只有訂單頭沒有明細」的髒資料
- 再次確認 DDIC 外鍵只在畫面輸入生效、不影響 Open SQL 的行為
- 複習 JOIN、`sy-subrc` 檢查等前面學過的技能

## 事前準備

物件都建在套件 `$TMP`。名稱請照下表（多人共用系統時把 `TR23` 換成 `TR23_<縮寫>`，並同步調整程式中的表名）。

## 第一部分：SE11 建 DDIC 物件

1. **Domain** `ZTR23_ORDNO`：Data Type `CHAR`，Length `10`（不設值域）→ 啟用
2. **Data Element** `ZTR23_ORDNO`：參考上面的 Domain；Field Label 填「訂單號」→ 啟用（**這個 DE 稍後會同時用在 Header 和 Detail 兩張表的訂單號欄位**，示範 DE 共用）
3. **Domain** `ZTR23_CUSTOMER`：Data Type `CHAR`，Length `40`（不設值域）→ 啟用
4. **Data Element** `ZTR23_CUSTOMER`：參考上面的 Domain；Field Label 填「客戶」→ 啟用（這個欄位之後會是 Search Help 的顯示參數，**一定要有 DE**——ex21 踩過的坑：內建型別欄位當 Search Help Parameter 會導致 Activate 失敗）
5. **Domain** `ZTR23_STATUS`：Data Type `CHAR`，Length `1`；這次改用**固定值清單**（跟 ex21 `ZTR21_SCORE` 的「區間」是不同技巧）：Value Range 頁籤逐筆加入 `N`（New）、`R`（Released/Confirmed）、`C`（Cancelled）三個固定值 → 啟用
6. **Data Element** `ZTR23_STATUS`：參考上面的 Domain；Field Label 填「訂單狀態」→ 啟用
7. **新透明表** `ZTR23_ORDH`（Header／訂單主檔）：

| 欄位 | Key | 型別來源 | 說明 |
|---|---|---|---|
| MANDT | ✔ | Data Element `MANDT` | client |
| ORDNO | ✔ | Data Element `ZTR23_ORDNO` | 訂單號 |
| CUSTOMER | | Data Element `ZTR23_CUSTOMER` | 客戶 |
| ORDDATE | | 內建型別 `DATS` | 訂單日期 |
| STATUS | | Data Element `ZTR23_STATUS` | 訂單狀態（N/R/C） |
| UPDUSER | | Data Element `SYUNAME` | 異動者 |
| UPDDATE | | Data Element `SYDATUM` | 異動日 |

   - Delivery Class `A`；Technical Settings 同 ex21（Data Class `APPL0`、Size Category `0`）→ 啟用
8. **新透明表** `ZTR23_ORDI`（Detail／訂單明細）：

| 欄位 | Key | 型別來源 | 說明 |
|---|---|---|---|
| MANDT | ✔ | Data Element `MANDT` | client |
| ORDNO | ✔ | Data Element `ZTR23_ORDNO` | 訂單號（**同時是 Key 也是外鍵**） |
| ITEMNO | ✔ | 內建型別 `NUMC` 3 | 序號 |
| PRODUCT | | 內建型別 `CHAR` 20 | 產品（純描述用欄位，**故意不建 DE**，對照 ex21 講過的「純技術/非查詢欄位可省事用內建型別」） |
| QTY | | 內建型別 `INT4` | 數量 |
| PRICE | | 內建型別 `DEC` 9,2 | 單價（先不處理幣別，教學簡化） |
| UPDUSER | | Data Element `SYUNAME` | 異動者 |
| UPDDATE | | Data Element `SYDATUM` | 異動日 |

   - `ORDNO` 欄位的 **Foreign Key** 對話框：Check Table 填 `ZTR23_ORDH`，Cardinality 選 `Many : 1`（多筆明細對應一個訂單），開啟 **Screen Check**——注意這次外鍵欄位本身就是 Key，跟 ex21 的 `KLASSE`（非 Key 外鍵）不一樣，是更貼近 SAP 官方文件範例（`SPFLI` 外鍵到 `SCARR`）的寫法
   - Delivery Class `A`；Technical Settings 同上 → 啟用
9. **維護畫面**：至少幫 `ZTR23_ORDH` 產生 Table Maintenance Generator（Authorization Group `&NC&`、Function Group 自訂如 `ZFG_TR23`）；`ZTR23_ORDI` 的維護畫面視情況決定要不要做
10. **Search Help** `ZTR23_ORDHSH`（SE11 → Search Help → Elementary Search Help）：
    - Selection Method：`ZTR23_ORDH`
    - Search Help Parameters：`ORDNO`（勾 Import Parameter + Export Parameter + SelOnScr，設為 SH field）、`CUSTOMER`（只勾 Export Parameter，純顯示用）
    - 存檔啟用，套件 `$TMP`
    - 回到 Data Element `ZTR23_ORDNO` → Change → **Further Characteristics** 頁籤 → Search Help 欄位填 `ZTR23_ORDHSH` → 存檔啟用

## 第二部分：程式 ZR_TR23_&lt;縮寫&gt;

依序完成（**每一步都檢查 `sy-subrc` 並輸出結果**）：

1. 開場防呆：清掉本程式會用到的舊測試訂單（`ORD0001`、`ORD0002` 的 Header+Item，以及外鍵教學用的孤兒明細 `ZZZZZZZZZZ`）——注意先刪明細再刪主檔
2. **正常情境**：`INSERT` 一筆 Header `ORD0001`（客戶「王小美商行」、日期 `sy-datum`、狀態 `N`）+ 兩筆明細（`NOTEBOOK` x2、`MOUSE` x5），走完 `COMMIT WORK`
3. **【重點】LUW all-or-nothing 示範**：
   - `INSERT` Header `ORD0002`（應該成功）
   - `INSERT` 明細 001（應該成功）
   - 故意再 `INSERT` 同一筆明細 001——觀察 `sy-subrc = 4`（主鍵重複，模擬「處理到一半失敗」）
   - 偵測到失敗後 `ROLLBACK WORK`
   - 用 `SELECT SINGLE` 查 Header `ORD0002`——觀察**連已經 INSERT 成功的 Header 也一起消失了**（因為還沒 COMMIT）
4. **複習 ex21**：`INSERT` 一筆明細，`ORDNO` 指向一個不存在的訂單號（如 `ZZZZZZZZZZ`）——觀察 Open SQL 依然成功（`sy-subrc = 0`），對比 SM30 畫面輸入會被外鍵擋下來
5. 用 `INNER JOIN` 把 `ZTR23_ORDH` 和 `ZTR23_ORDI` 串起來，印出 `ORD0001` 的完整內容（訂單號／客戶／日期／狀態／序號／產品／數量／單價）
6. 結尾 `COMMIT WORK`（把第 4 步的孤兒明細也一併確認落地）

## 預期輸出（範例）

```
清除舊測試明細：        0 筆
清除舊測試主檔：        0 筆
=== 正常情境：建立訂單 ORD0001 ===
INSERT Header ORD0001：sy-subrc =          0
INSERT Item ORD0001/001（NOTEBOOK）：sy-subrc =          0
INSERT Item ORD0001/002（MOUSE）：sy-subrc =          0
  → COMMIT WORK 完成，ORD0001 連同兩筆明細正式落地。

=== LUW 示範：建立訂單 ORD0002，過程中失敗 → ROLLBACK WORK ===
INSERT Header ORD0002：sy-subrc =          0
INSERT Item ORD0002/001（第一次）：sy-subrc =          0
INSERT Item ORD0002/001（重複 INSERT，模擬處理失敗）：sy-subrc =          4
  → 偵測到 sy-subrc <> 0，執行 ROLLBACK WORK：整個 LUW（含之前的 Header INSERT）全部撤銷。
查詢 Header ORD0002（ROLLBACK 之後）：sy-subrc =          4
  → 查無此訂單！雖然 Header 當時 INSERT 是成功的（sy-subrc = 0），
     但因為整個過程還沒 COMMIT WORK，ROLLBACK WORK 把同一個 LUW 裡
     「已經寫入但尚未提交」的 Header 也一併撤銷了。
     這就是 LUW（Logical Unit of Work）「all-or-nothing」的意義：
     一筆訂單裡只要有任何一步失敗，寧可整包撤銷，也不要留下「只有 Header 沒有明細」的髒資料。

=== 複習 ex21：DDIC 外鍵不會擋 Open SQL ===
INSERT Item ORDNO=ZZZZZZZZZZ（訂單不存在於 ZTR23_ORDH）：sy-subrc =          0
  → 對比：sy-subrc = 0，程式端 INSERT 依然成功！
  → DDIC 外鍵（screenCheck）只在 SM30／Dynpro 這類畫面輸入時發生作用，
     不是資料庫層的 constraint，Open SQL 呼叫不受影響，資料正確性仍要靠程式自行檢查。

=== JOIN 查詢：ORD0001 完整內容（訂單／客戶／日期／狀態／序號／產品／數量／單價） ===
ORD0001 王小美商行     2026/07/05 N   001 NOTEBOOK          2    25000.00
ORD0001 王小美商行     2026/07/05 N   002 MOUSE              5      500.00

=== 最終 COMMIT WORK 完成 ===
```

## 思考題

1. 為什麼第 3 步的 Header `ORD0002` 明明 `INSERT` 成功（`sy-subrc = 0`），`ROLLBACK WORK` 之後卻查不到？跟 `COMMIT WORK` 的位置有什麼關係？
2. 如果把第 2 步（正常情境）的 Header INSERT 和兩筆明細 INSERT 中間插入一個 `COMMIT WORK`，再讓其中一筆明細失敗，還能靠 `ROLLBACK WORK` 撤銷整筆訂單嗎？為什麼？
3. `ZTR23_ORDI` 的 `ORDNO` 欄位同時是 Key 也是外鍵，跟 `ex21` 的 `KLASSE`（外鍵但不是 Key）比起來，資料模型的意義有什麼不同？（提示：想想「這筆明細沒有訂單號合理嗎？」）
4. 如果要讓程式層也擋下第 4 步那種「訂單不存在」的髒資料，應該怎麼寫？寫在哪一步比較合理？

## 答案

見 `zr_tr23_orders.prog.abap`（SAP 端程式 `ZR_TR23_ORDERS`）；資料表定義快照見 `ztr23_ordh.tabl.abap`、`ztr23_ordi.tabl.abap`。Domain／Data Element／Search Help 無程式碼快照（DDIC metadata 物件，非 source-based）。
