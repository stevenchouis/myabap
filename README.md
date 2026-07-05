# ABAP + Claude Code 初始檔案組合

給「純 ABAP 後端（Z 前綴命名空間、尚未使用 abapGit）」專案用的 Claude Code 起始設定。

## 目錄結構

```
.
├── CLAUDE.md                          # 專案記憶：命名慣例、開發流程
├── .mcp.json                          # 專案共用的 MCP 設定（Project scope，已進版控）
├── .gitignore
└── .claude/
    ├── settings.json                  # 工具權限規則（allow/ask/deny）
    ├── rules/
    │   ├── abap-style.md              # 只在改到 *.abap 檔案時載入
    │   └── transport-flow.md          # 傳輸請求檢查清單
    └── skills/
        ├── new-abap-class/SKILL.md    # 建立新類別骨架
        ├── release-transport/SKILL.md # 釋放傳輸請求前的完整檢查
        └── atc-review/SKILL.md        # ATC 檢查報告整理
```

## MCP 連線設定（Project scope）

### 架構說明：兩層橋接

`sap-adt` 這個 MCP Server 實際上是**兩層架構**疊起來的，理解這點才看得懂 `.mcp.json` 與 `.claude/rules/sap-adt-mcp.md` 裡出現的兩個不同位址是怎麼回事：

```text
Claude Code
   │  MCP 協定（HTTP，url 見 .mcp.json）
   ▼
MCP Server：Eclipse Plugin「SAP ADT MCP Server for Claude Code」
   │  在本機執行，對外暴露在 LAN 固定 IP（本專案是 192.168.68.56:3000，
   │  已在家用/公司路由器把這台電腦的區網 IP 保留固定）
   │  依 ADT API 規格組好參數，用 HTTP 呼叫下一層
   ▼
adt-rfc-bridge：本機 Python 橋接程式，監聽 http://127.0.0.1:8410
   │  收到 HTTP 格式的 ADT API 請求後，轉換成 RFC 呼叫
   │  用自己保存的 RFC 連線參數（Host IP / User / Password / Client / Router String）
   ▼
SAP Host（透過 SAProuter）
```

- `.mcp.json` 裡的 `url` 指向的是**第一層**（MCP Server／Eclipse Plugin）的位址：這台跑 Eclipse 的電腦在區網裡的固定 IP + port 3000。
- `.claude/rules/sap-adt-mcp.md` 裡提到的 `http://127.0.0.1:8410` 是**第二層**（adt-rfc-bridge）的位址——這是 MCP Server 和 bridge 之間的內部溝通，**只有 MCP Server 那台電腦自己看得到**，其他隊友的 Claude Code 不會直接碰到這個位址，只需要能連到 `.mcp.json` 裡那個 LAN IP 即可。
- 也因此，只有**跑 MCP Server（Eclipse Plugin）的那台電腦**需要裝 adt-rfc-bridge 並設定好 RFC 連線參數；其他隊友的電腦只要能連到區網、打得到 `192.168.68.56:3000` 就好，不需要在自己電腦上另外裝 bridge。

`.mcp.json` 已經內建兩個 Server，team clone 這份專案下來、開 Claude Code 就會自動偵測到（第一次會跳出是否信任的提示，選同意即可，不用再手動 `claude mcp add`）：

```json
{
  "mcpServers": {
    "sap-adt": {
      "type": "http",
      "url": "http://192.168.68.56:3000/mcp"
    },
    "sap-docs": {
      "type": "http",
      "url": "https://mcp-sap-docs.marianzeis.de/mcp"
    }
  }
}
```

這是用以下指令產生的（如果要在新環境重建，或改別的 URL，直接照這個指令重跑，Claude Code 會自動幫你改 `.mcp.json`，不需要手動編輯 JSON）：

```bash
claude mcp add --transport http --scope project sap-adt http://192.168.68.56:3000/mcp
claude mcp add --transport http --scope project sap-docs https://mcp-sap-docs.marianzeis.de/mcp
```

**要注意的坑：**

- `sap-adt` 指向的 `192.168.68.56` 是內網 IP。只有能連到這個網段的人（例如公司內網、VPN）才連得上；不同網路環境的隊友執行 Claude Code 時 `sap-adt` 會顯示連線失敗，屬正常現象，不是設定錯誤。若團隊分散在不同網路，考慮：
  - 把 `sap-adt` 換成大家都能連到的固定網域（而不是內網 IP），或
  - 個別隊友改回 `local`/`user` scope，各自指向自己能連到的位址：`claude mcp add --transport http --scope local sap-adt <你的位址>`（local scope 會覆蓋 `.mcp.json` 裡同名的 project scope 設定，優先權更高）。
- 這兩個 Server 目前沒有帶認證 Header。如果之後 `sap-adt` 加上驗證機制，記得用 `${VAR}` 展開，不要把 Token 明碼寫進 `.mcp.json`（因為這檔案會進版控）：
  ```json
  "sap-adt": {
    "type": "http",
    "url": "http://192.168.68.56:3000/mcp",
    "headers": { "Authorization": "Bearer ${SAP_ADT_TOKEN}" }
  }
  ```
  對應在每個人自己的環境變數（例如 shell profile 或 `.env`，不要進版控）設定 `SAP_ADT_TOKEN`。

## 使用步驟

1. 把整個資料夾內容複製到你的專案目錄下（或直接當成專案根目錄），並用 git 初始化/推上遠端 repo（這樣 `.mcp.json` 才能真正跟團隊共用）。
2. 打開 `CLAUDE.md`，把標記「請填入」「待補充」的地方換成實際系統資訊與團隊慣例。
3. 在專案目錄下執行 `claude`，第一次會問你要不要信任這個專案的 `.mcp.json`，選是。
4. 用 `/mcp` 確認 `sap-adt`、`sap-docs` 連線成功，`/permissions` 檢查權限規則。
5. **務必用 `/mcp` 看一下 `sap-adt` 實際暴露哪些工具名稱**，跟 `.claude/settings.json` 裡列的 `mcp__sap-adt__xxx` 比對，名稱不一致要手動修正（不同的 ADT MCP Server 實作，工具命名可能不同）。
6. 開始開發後可以直接用自然語言觸發 Skill，例如：
   - 「幫我建立一個處理訂單驗證的新類別」→ 觸發 `new-abap-class`
   - 「幫我跑一次 ATC 檢查」→ 觸發 `atc-review`
   - 「這個功能可以釋放傳輸請求了」→ 觸發 `release-transport`

## 這份設定的安全預設值

- `.claude/settings.json` 把「唯讀」操作（查原始碼、語法檢查、搜尋物件）設為免確認；`sap-docs`（文件查詢）整組免確認，因為是唯讀性質。
- 建立/修改/啟用物件需要你確認。
- **刪除物件、釋放/刪除傳輸請求直接被 deny**（Claude 完全無法執行），需要時請自己手動在 SAP GUI/Eclipse ADT 操作，或視需求把對應項目從 `deny` 移到 `ask`。
- `.mcp.json` 會進版控，代表**任何 clone 到這個 repo 的人都會看到 `sap-adt` 指向的內網位址**（但因為沒帶密碼，本身不算洩漏憑證）；`sap-docs` 是外部第三方架設的服務（非官方 SAP），建議團隊成員第一次使用前自己評估一下來源可信度。

## 之後要導入 abapGit 的話

- 把 `CLAUDE.md` 裡「版控狀態」段落更新掉。
- `.claude/rules/transport-flow.md` 底部已經預留了 abapGit 的建議段落，可以直接擴充。
