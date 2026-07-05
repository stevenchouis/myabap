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

# 講義 19
# 除錯 Debugger

ABAP 基礎教育訓練（授課順序：接在講義 5 之後）

對應練習 ex19（附埋了 3 個 bug 的程式）｜答案 `ZR_TR19_DEBUGGING`

---

## 本講重點

- 三種進入 Debugger 的方式：`/h`、Session 中斷點、`BREAK-POINT`
- 單步鍵 F5 / F6 / F7 / F8 的分工
- 看變數值、看 internal table、改變數值重跑
- Watchpoint：值變了才停
- ST22 dump 分析：找回「案發那一行」
- 除錯的思考方法：先假設、再驗證

---

## 1. 進入 Debugger 的三種方式

| 方式 | 操作 | 適用 |
|---|---|---|
| 命令欄 `/h` | 執行前輸入 `/h` 再執行 | 想從頭跟一遍 |
| **Session 中斷點** | 游標停某行 → Ctrl+Shift+F12 | **最常用**：停在懷疑的那行；登出即消失 |
| `BREAK-POINT.` | 程式裡寫死 | 臨時手段 |

> **團隊規範**：`BREAK-POINT` / `BREAK 帳號.`
> commit／傳輸前**必須清乾淨**

進入後：上方原始碼（黃色箭頭 = 目前停的行）、下方變數區

---

## 2. 單步四鍵（背起來）

| 鍵 | 名稱 | 效果 |
|---|---|---|
| `F5` | Step Into | 走一步；遇 PERFORM / CALL **走進去** |
| `F6` | Step Over | 走一步；遇 PERFORM / CALL **跑完跳過** |
| `F7` | Return | 目前這層跑完，**回到呼叫端** |
| `F8` | Continue | 跑到下一個中斷點（沒有就跑完） |

實戰節奏：
F8 衝到懷疑區域 → F6 逐行走主流程
→ 確認要進哪個 FORM 再 F5 進去 → 進錯了 F7 出來

---

## 3. 看變數、看內表、改值

- **看單值**：原始碼**雙擊變數名** → 下方變數區
- **看內表**：雙擊內表名 → Table 檢視，整張表逐列顯示
- **系統欄位**：變數區直接輸入 `sy-subrc`、`sy-tabix`
  → READ TABLE 之後 sy-subrc 是多少，**眼見為憑**
- **改值**：變數區改掉按 Enter
  - 不改程式先驗證「如果這裡是 0 會怎樣」
  - 只影響**這一次執行**

---

## 4. Watchpoint：值變了才停

「`gv_total` 不知道被誰改壞了」——逐行追太慢：

1. Debugger 內按「Create Watchpoint」
2. 填變數名（可加條件，如 `gv_total > 1000`）
3. F8

**該變數一被改動（或條件成立）程式立刻停下**
停的位置就是兇手那一行

→ 抓「全域變數被莫名改掉」的殺手鐧

---

## 5. ST22：程式已經當掉了怎麼查

dump 時不要只截圖——進 **ST22** 找紀錄，看四個段落：

| 段落 | 內容 |
|---|---|
| Runtime Errors | 錯誤類型 |
| Error analysis | 白話說明 |
| **Source Code Extract** | **案發那一行**（>>>>> 標記） |
| Chosen variables | 當下相關變數的值 |

| 常見 dump | 成因 | 講次 |
|---|---|---|
| COMPUTE_INT_ZERODIVIDE | 除以零 | 17 |
| CONVT_NO_NUMBER | 字元轉數值失敗 | 2 |
| GETWA_NOT_ASSIGNED | field-symbol 未指派 | 16 |
| TIME_OUT | 迴圈沒出口 | 17 |

---

## 6. 除錯的思考方法

工具只是手段，方法才省時間：

1. **先重現**：找到穩定重現的輸入條件
2. **提出假設**：
   - 輸出是殘留值？→ 多半 sy-subrc 沒檢查（講義 4）
   - 改了沒生效？→ 多半忘了 MODIFY / 忘了啟用
3. **用 Debugger 驗證假設**：中斷點下在假設的案發點
   ——而不是漫無目的逐行走
4. **修一個、驗一個**：不要憑感覺一口氣改三處

---

## 7. 常見錯誤與陷阱

| 症狀 | 原因 |
|---|---|
| `/h` 打了沒反應 | 要在**執行前**輸入 |
| 中斷點隔天不見了 | Session 中斷點登出即失效（特性） |
| F5 進到標準程式深處 | F7 逐層返回，下次該處用 F6 |
| 正式機想 debug 改資料 | 權限受控，本來就不該有——DEV/QAS 重現 |
| BREAK-POINT 留到傳輸 | release 前全文搜尋 BREAK |

---

<!-- _class: lead -->

# 課堂練習

完成 **ex19**：

一支「會動但全是錯」的程式
（3 個 bug：殘留值、白改、除零 dump）

**規則：先用 Debugger 定位證據，再動手修**
每個 bug 要能說出「停在哪行、看到什麼值、為什麼錯」
