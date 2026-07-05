# Claude Code 設定總覽與複製指南

> 這份文件整理**這個專案用到哪些 Claude Code 客製化機制**（CLAUDE.md／rules／skills／plugin／MCP），並說明若要在**另一個新目錄**重現同一套「Claude Code + sap-adt MCP」開發環境，該複製哪些檔案、要改哪些地方。
>
> 團隊成員直接 `git clone` 這個 repo 的情境，設定步驟見 [README.md](../README.md) 的「MCP 連線設定」章節；本文件補的是**清單總覽**與**跨專案複製**的角度，兩者互補，不重複贅述細節。

## 1. 總覽表

| 類型 | 名稱 | 檔案位置 | Scope | 用途一句話 |
|---|---|---|---|---|
| 專案記憶 | CLAUDE.md | `CLAUDE.md` | 專案（進版控） | Claude Code 每次啟動自動讀取的專案規則總入口 |
| Rule | abap-style | `.claude/rules/abap-style.md` | 專案，`*.abap` 觸發載入 | 命名慣例、程式碼品質規範 |
| Rule | transport-flow | `.claude/rules/transport-flow.md` | 專案，`*.abap` 觸發載入 | 傳輸請求工作流程與釋放前檢查清單 |
| Rule | sap-adt-mcp | `.claude/rules/sap-adt-mcp.md` | 專案，需手動提及/讀取 | sap-adt MCP 工具的實測限制與 API workaround（本文件持續累積的踩坑記錄） |
| Skill | atc-review | `.claude/skills/atc-review/SKILL.md` | 專案 | 執行 ATC 檢查並整理報告 |
| Skill | new-abap-class | `.claude/skills/new-abap-class/SKILL.md` | 專案 | 依命名規範建立新類別骨架＋測試類別 |
| Skill | release-transport | `.claude/skills/release-transport/SKILL.md` | 專案 | 釋放傳輸請求前的完整檢查流程 |
| 權限設定 | settings.json | `.claude/settings.json` | 專案（進版控，team 共用） | MCP 工具的 allow/ask/deny 分類 |
| 權限設定（個人） | settings.local.json | `.claude/settings.local.json` | 本機（**gitignore，不進版控**） | 個人這台機器額外核准過的指令/工具，因人而異 |
| MCP Server | sap-adt | `.mcp.json` | 專案（進版控） | 透過 ADT 協定讀寫 SAP 系統物件 |
| MCP Server | sap-docs | `.mcp.json` | 專案（進版控） | SAP 相關文件查詢，唯讀，第三方非官方服務 |
| Plugin（全域） | github@claude-plugins-official | `~/.claude/settings.json`（使用者層級） | 使用者帳號，**不是專案** | GitHub PR / Issue 相關工具，官方 marketplace |
| Plugin（全域） | classify-change@appleboy-skills | 同上 | 使用者帳號 | 判斷改動屬於 Leaf Node 或 Core Code 的分類技能 |
| Plugin（全域） | plan-feature@appleboy-skills | 同上 | 使用者帳號 | 開發功能前的規劃技能 |

**重點觀念**：CLAUDE.md／rules／skills／`.mcp.json`／`settings.json` 是**專案層級**，會隨 git clone 帶到任何人的電腦；plugin 是**使用者層級**，跟著 Claude Code 帳號設定走，不會因為 clone 專案而自動出現，也不需要（也不能）用複製檔案的方式移植，要在新環境用 `/plugin` 指令另外啟用。

## 2. 各項目內容說明

### 2.1 CLAUDE.md（`CLAUDE.md`）

專案類型、命名空間、版控策略（單向快照，非 abapGit）、repo 目錄結構說明、命名慣例表、開發流程五條鐵律（先搜尋避免重複、一功能一 TR、改完先語法檢查、不自動 release、傳輸細節另見 rules）、風格規範摘要、MCP 連線摘要、待補清單（SAP 系統資訊、team 風格細節等）。**這是 Claude Code 每次啟動都會自動載入的檔案，內容要精簡，只放「猜不到」的資訊。**

### 2.2 Rules（`.claude/rules/*.md`）

Rule 檔案支援 frontmatter 的 `paths:` 條件，符合的檔案被讀取/編輯時才自動載入，減少不相關情境下的雜訊：

- **abap-style.md**：`paths: **/*.abap` 等——縮排、變數前綴命名（`lv_`/`gv_`/`iv_`/`ev_`/`rv_`…）、方法長度、例外類別慣例、禁止過時語法。
- **transport-flow.md**：`paths: **/*.abap`——傳輸請求一功能一 TR、釋放前檢查清單、**不自動釋放**的鐵律、未來導入 abapGit 的預留段落。
- **sap-adt-mcp.md**：**沒有 `paths:` 限制**（純文字知識庫，不綁檔案類型），記錄這個 MCP server 實測發現的所有限制與繞過方法——404 路徑錯誤、搜尋工具失效、語法檢查要走 checkruns API、INCLUDE/Function Module/測試類別的建立流程、DDIC 物件與 Message Class 的建立方式、鎖定殘留的清鎖手法，以及本次校正過的 `settings.json` 工具名稱對照。**這份是踩坑最多、最值得在新專案延續的檔案**，遇到 MCP 工具行為怪異先查這裡。

### 2.3 Skills（`.claude/skills/*/SKILL.md`）

Skill 用自然語言描述一套**多步驟工作流程**，讓 Claude 在符合觸發情境時依序執行，而不是單一工具呼叫：

- **atc-review**：跑 ATC 檢查 → 按嚴重度分類 → 每項給原因與建議修法但**不自動修改** → 固定格式輸出。
- **new-abap-class**：確認命名 → 產生 PUBLIC/PRIVATE/CONSTRUCTOR 骨架＋測試類別骨架 → 詢問 Package 與 Transport Request（不自己決定）→ 語法檢查 → **不自動建立/啟用**。
- **release-transport**：列出 TR 內容確認範圍 → 語法檢查 → ATC 檢查（有嚴重項目就停止） → 確認測試類別 → 搜尋殘留 BREAK-POINT → 總結後**明確詢問是否要釋放** → 只有使用者明確回覆才動作。

三份 skill 都貫徹同一個原則：**有副作用的動作一律先確認，不靜默執行**——這是本專案在 `.claude/settings.json` 與 CLAUDE.md 都反覆強調的紅線。

### 2.4 MCP 設定（`.mcp.json`，Project scope）

```json
{
  "mcpServers": {
    "sap-adt": { "type": "http", "url": "http://192.168.68.56:3000/mcp" },
    "sap-docs": { "type": "http", "url": "https://mcp-sap-docs.marianzeis.de/mcp" }
  }
}
```

- `sap-adt`：透過 ADT (ABAP Development Tools) 協定讀寫 SAP 系統物件，指向**內網 IP**，只有連得到該網段的人能用。
- `sap-docs`：SAP 官方/社群文件查詢，唯讀，第三方（非 SAP 官方）架設的服務。

> ⚠️ **待確認的落差**：CLAUDE.md 目前寫的 IP 是 `192.168.68.56`，`.mcp.json` 實際設定也是 `192.168.68.56`，但 `README.md` 的「MCP 連線設定」章節寫的是 `192.168.68.61`。兩份文件的 IP 不一致，本次整理沒有足夠資訊判斷哪個是目前真正在用的位址，**建議實際連線驗證後，統一修正 CLAUDE.md 或 README.md 其中錯誤的一份**，避免新加入的隊友按錯誤位址浪費時間排查。

### 2.5 權限設定（`.claude/settings.json`）

分三類：

- **allow**（唯讀、無副作用，靜默執行）：`sap_get_source`、`sap_object_structure`、`sap_syntax_check`、`sap_search_object`、`sap_usage_references`、`sap_run_unit_test`、`sap_inactive_objects`、`sap_abap_docu`、`sap_sql_query`、`sap-docs__*`。
- **ask**（有副作用，需使用者確認）：`sap_set_source`、`sap_create_object`、`sap_activate`、`sap_lock`、`sap_unlock`、`sap_atc_run`。
- **deny**（鎖死，不可執行）：`sap_delete_object`、`sap_transport_release`、`sap_transport_delete`——**這三個目前是命名猜測的預留位**，這版 sap-adt MCP 並未實際暴露刪除/釋放傳輸的專屬工具（無獨立的建立傳輸請求工具，`sap_create_object`／`sap_set_source` 用 `transport` 參數代收單號）。若之後 MCP server 版本新增了這類工具，**務必先用 `/mcp` 或 Claude Code 的工具搜尋確認實際名稱**再更新這份清單，詳細校正過程見 `.claude/rules/sap-adt-mcp.md` 第 9 節。

`.claude/settings.local.json` 是**個人本機設定**（已 gitignore，不進版控），內容是這台機器上已核准過的額外指令/工具，因人而異、因除錯過程而異，**不建議複製到新專案**，讓每個人依實際需要自然累積即可。

## 3. 複製到新目錄／新專案的操作指南

以下假設新目錄要接同一台 sap-adt MCP server（同網段、同 SAP 系統），只是換一個獨立的 Claude Code 專案（例如另一個 ABAP 開發或教材專案）。

### 3.1 需要複製的檔案

```
CLAUDE.md                          # 整份複製後改內容（見下）
.mcp.json                          # 整份複製，通常不用改（除非要換 MCP server 位址）
.gitignore                         # 至少要有 .claude/settings.local.json 這條
.claude/settings.json              # 整份複製，通常不用改（工具權限跟專案無關）
.claude/rules/sap-adt-mcp.md       # 整份複製，強烈建議——這是最有價值的踩坑知識庫
.claude/rules/abap-style.md        # 依新專案的風格規範調整後複製（不是通用檔）
.claude/rules/transport-flow.md    # 依新專案的傳輸流程調整後複製（不是通用檔）
.claude/skills/*/SKILL.md          # 三份都可整份複製，內容是通用工作流程，不綁特定專案
```

**不要複製**：`.claude/settings.local.json`（個人設定，且已 gitignore）；`src/` 底下的程式快照與教材（那是這個專案的內容，不是設定）。

### 3.2 複製後要改的地方

| 檔案 | 要改的內容 |
|---|---|
| `CLAUDE.md` | 專案類型、Repo 結構段落（換成新專案實際目錄）、命名空間慣例（若新專案的 Z 前綴規則不同）、SAP 系統 ID/Client/語言待補清單、命名慣例表（Package 等） |
| `.mcp.json` | 若新專案要接**不同的** sap-adt MCP server（不同 IP/Port）或不同的 sap-docs 服務，才需要改 `url`；接同一套系統則不用改 |
| `.claude/rules/abap-style.md` | 縮排、關鍵字大小寫、方法長度上限等——若新專案團隊風格不同就調整；若同團隊可原樣複製 |
| `.claude/rules/transport-flow.md` | 傳輸請求流程若新專案有不同規範（例如已改用 abapGit）需要調整對應段落 |
| `.claude/rules/sap-adt-mcp.md` | 通常不用改內容，但檔頭的「本機 ADT 代理位址」若新環境的本地代理 port 不同（`http://127.0.0.1:8410` 這類），要更新註記 |
| `.claude/skills/*/SKILL.md` | 通常不用改，是通用工作流程；若新專案有不同的 Package/TR 命名慣例，可以在 skill 裡補充 |

### 3.3 不需要複製、但要在新環境另外處理的部分

- **Plugin**（`github@claude-plugins-official`、`classify-change@appleboy-skills`、`plan-feature@appleboy-skills`）：這些是**使用者帳號層級**設定（存在 `~/.claude/settings.json`，不在專案目錄裡），只要是同一個 Claude Code 帳號登入，換到哪個專案目錄都自動可用，**不需要也無法用複製檔案的方式移植**。如果是換一台電腦/新帳號要重現，用 `/plugin marketplace add appleboy/skills` 加入 marketplace 後再啟用對應 skill。
- **`.claude/settings.local.json`**：新環境會在使用過程中自然產生，不用預先準備。

### 3.4 複製後的驗證步驟

1. 用 Claude Code 開啟新目錄，觸發 `.mcp.json` 的信任提示，選擇同意。
2. 執行 `/mcp` 確認 `sap-adt`、`sap-docs` 兩個 server 都連線成功。
3. **務必核對 `sap-adt` 實際暴露的工具名稱**跟 `.claude/settings.json` 裡列的是否一致（不同版本/不同 ADT MCP 實作，工具命名可能不同——本專案自己就在 2026-07-05 抓到一次全部對不上的落差，見 `.claude/rules/sap-adt-mcp.md` 第 9 節）。
4. 執行 `/permissions` 確認 allow/ask/deny 清單套用正確。
5. 用一個唯讀操作（如搜尋既有物件）測試 `sap-adt` 實際能不能打到 SAP 系統。

## 4. 與 README.md 的分工

- **README.md**：給第一次加入這個 repo 的人看，著重「clone 下來之後怎麼設定、常見網路連線的坑（內網 IP、跨網段隊友怎麼辦）」。
- **本文件**：給要在**別的專案**重現同一套 Claude Code 客製化環境的人看，著重「有哪些檔案、各自做什麼、複製時要改哪裡」。

兩份文件都提到 sap-adt 的 IP 位址，若之後確認正確位址，**兩處都要同步更新**，避免再次出現本文件第 2.4 節提到的落差。
