---
name: new-abap-class
description: 依團隊命名規範建立新的 ABAP 類別骨架，並附上對應的測試類別。當使用者要求「建立新類別」「新增 ZCL」或類似需求時使用。
---

# 建立新的 ABAP 類別

依照使用者指定的類別用途，建立符合規範的類別骨架：

1. 確認類別名稱符合 `ZCL_` 前綴，若使用者沒給完整名稱，依用途建議一個。
2. 產生類別骨架：
   - `PUBLIC SECTION`：對外方法簽章
   - `PRIVATE SECTION`：內部屬性與輔助方法
   - `CONSTRUCTOR`：需要初始化的依賴一律透過建構子注入
3. 附上對應的 Local Test Class：
   - `FOR TESTING RISK LEVEL HARMLESS DURATION SHORT`
   - 針對每個 public 方法至少建立一個測試方法骨架
4. 詢問使用者：
   - 這個類別要放進哪個 Package（`ZPKG_xxx`）
   - 對應哪個 Transport Request（不要自己決定）
5. 產生後先跑語法檢查，回報結果給使用者，**不要自動建立/啟用物件**，先給使用者確認程式碼內容。
