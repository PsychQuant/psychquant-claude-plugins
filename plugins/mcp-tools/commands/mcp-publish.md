---
description: 首次發布 MCP Server 到官方 MCP Registry（server.json 設定、認證、發布、驗證）
argument-hint: [project-name]
allowed-tools: Read, Write, Edit, Bash(brew:*), Bash(curl:*), Bash(mcp-publisher:*), Bash(shasum:*), Bash(git:*), Bash(gh:*), Bash(ls:*), Bash(cat:*), Bash(which:*), Bash(open:*), Bash(python3:*), Bash(cd:*), Grep, Glob, AskUserQuestion
---

# MCP Publish - 發布到 MCP Registry

首次將 MCP Server 發布到 [官方 MCP Registry](https://registry.modelcontextprotocol.io)。

**前置作業**：請先用 `/mcp-tools:mcp-deploy` 完成 GitHub Release。

## 參數

- `$1` = 專案名稱（可選，如 `che-ical-mcp`）

---

## Phase 0: 環境檢查

### Step 1: 確認專案目錄

如果提供了 `$1`，嘗試 `cd` 到該目錄：

```bash
# 常見位置
ls -d ~/Developer/mcp/$1 2>/dev/null || ls -d ~/Developer/$1 2>/dev/null
```

否則確認當前目錄是 MCP 專案。

### Step 2: 檢查 GitHub Release 是否存在

```bash
REPO_URL=$(git remote get-url origin 2>/dev/null)
OWNER_REPO=$(echo "$REPO_URL" | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com[:/]\(.*\)/\1/')
gh release list --repo "$OWNER_REPO" --limit 3
```

**沒有 Release？** 提示：
> 請先執行 `/mcp-tools:mcp-deploy` 建立 GitHub Release。

### Step 3: 取得專案資訊

```bash
# 專案名稱
PROJECT_NAME=$(basename $(pwd))

# 最新版本和 Release 資訊
LATEST_TAG=$(gh release list --repo "$OWNER_REPO" --limit 1 --json tagName -q '.[0].tagName')
echo "專案: $PROJECT_NAME"
echo "Repo: $OWNER_REPO"
echo "最新版本: $LATEST_TAG"
```

### Step 4: 安裝 mcp-publisher CLI

```bash
which mcp-publisher
```

如果未安裝：

```bash
brew install mcp-publisher
```

如果 brew 不可用，使用 curl：

```bash
curl -fsSL https://registry.modelcontextprotocol.io/cli/install.sh | sh
```

驗證安裝：

```bash
mcp-publisher --version
```

### Step 5: 檢查是否已發布過

```bash
curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?search=$PROJECT_NAME" | python3 -m json.tool 2>/dev/null || echo "尚未發布"
```

如果 `metadata.count > 0`，提示使用者：
> 此專案似乎已在 Registry 上。如要更新版本，修改 server.json 的版本號後重新 `mcp-publisher publish`。

---

## Phase 1: 建立 server.json

### Step 1: 確認是否已有 server.json

```bash
ls server.json 2>/dev/null
```

如果已存在，跳到 Step 5 驗證內容。

### Step 2: 收集必要資訊

```bash
# Binary 名稱（Swift 專案）
BINARY_NAME=$(ls mcpb/server/ | grep -v '.sh' | grep -v '.mcpb' | head -1)

# 從 manifest.json 或 Package.swift 取得描述
cat mcpb/manifest.json 2>/dev/null
```

### Step 3: 計算 SHA-256 Hash

```bash
# 使用本地 binary（如果剛 deploy 過，應與 Release 一致）
shasum -a 256 mcpb/server/$BINARY_NAME | awk '{print $1}'
```

**重要**：`fileSha256` 必須對應 GitHub Release 上的 binary。建議從 Release 下載驗證：

```bash
DOWNLOAD_URL="https://github.com/$OWNER_REPO/releases/download/$LATEST_TAG/$BINARY_NAME"
curl -sL "$DOWNLOAD_URL" -o /tmp/_verify_binary
shasum -a 256 /tmp/_verify_binary | awk '{print $1}'
rm /tmp/_verify_binary
```

如果兩個 hash 不一致，使用 Release 上的 hash。

### Step 4: 編寫 server.json

**⚠️ 重要：所有欄位名使用 camelCase**

#### Swift (MCPB Binary) 模板

```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "io.github.kiki830621/{project-name}",
  "description": "{description, max 100 chars}",
  "version": "{version}",
  "repository": {
    "url": "https://github.com/kiki830621/{project-name}",
    "source": "github"
  },
  "packages": [
    {
      "registryType": "mcpb",
      "identifier": "https://github.com/kiki830621/{project-name}/releases/download/v{version}/{BinaryName}",
      "version": "{version}",
      "transport": {
        "type": "stdio"
      },
      "fileSha256": "{sha256-hash}"
    }
  ]
}
```

#### Python (PyPI) 模板

```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "io.github.kiki830621/{project-name}",
  "description": "{description, max 100 chars}",
  "version": "{version}",
  "repository": {
    "url": "https://github.com/kiki830621/{project-name}",
    "source": "github"
  },
  "packages": [
    {
      "registryType": "pypi",
      "identifier": "{pypi-package-name}",
      "version": "{version}",
      "transport": {
        "type": "stdio"
      }
    }
  ]
}
```

#### TypeScript (npm) 模板

```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "io.github.kiki830621/{project-name}",
  "description": "{description, max 100 chars}",
  "version": "{version}",
  "repository": {
    "url": "https://github.com/kiki830621/{project-name}",
    "source": "github"
  },
  "packages": [
    {
      "registryType": "npm",
      "identifier": "{npm-package-name}",
      "version": "{version}",
      "transport": {
        "type": "stdio"
      }
    }
  ]
}
```

**⚠️ 常見格式錯誤**：

| 錯誤 | 正確 |
|------|------|
| `"name": "che-word-mcp"` | `"name": "io.github.kiki830621/che-word-mcp"` |
| `"version_detail": {...}` | `"version": "1.0.0"` |
| `"registry_type"` (snake_case) | `"registryType"` (camelCase) |
| `"file_sha256"` (snake_case) | `"fileSha256"` (camelCase) |
| `"repository": { "license": "MIT" }` | 不支援 `license`，移除 |
| 缺少 `transport` | 必須包含 `"transport": {"type": "stdio"}` |
| packages 中含 `name`、`environment`、`runtime` | 這些欄位不被接受 |
| `description` 超過 100 字元 | 精簡到 100 字元以內 |

### Step 5: 用 Registry API 驗證

**發布前必做**：使用 `/validate` endpoint 確認格式正確：

```bash
cat server.json | curl -s -X POST "https://registry.modelcontextprotocol.io/v0.1/validate" \
  -H "Content-Type: application/json" -d @- | python3 -m json.tool
```

**預期輸出**：`{"valid": true, "issues": []}`

如果有錯誤，根據 `errors[].message` 和 `errors[].location` 修正後重新驗證。

---

## Phase 2: 認證與發布

### Step 1: 登入 GitHub

```bash
mcp-publisher login github
```

這會顯示 device code，需要在瀏覽器中前往 https://github.com/login/device 輸入。

**Namespace 規則**：
- GitHub 認證後，你的 namespace 是 `io.github.{username}`
- 例如：`io.github.kiki830621/che-ical-mcp`
- 只能發布到你的 namespace 下

**注意**：token 會過期，如果 publish 時收到 401 錯誤，重新 `mcp-publisher login github`。

### Step 2: 發布

```bash
mcp-publisher publish
```

CLI 會：
1. 讀取當前目錄的 `server.json`
2. 驗證格式
3. 上傳 metadata 到 Registry（Registry 只存 metadata，不存 binary）
4. 回傳發布結果

**預期輸出**：
```
Publishing to https://registry.modelcontextprotocol.io...
✓ Successfully published
✓ Server io.github.kiki830621/{project-name} version {version}
```

### Step 3: 驗證發布成功

```bash
curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?search=$PROJECT_NAME" | python3 -m json.tool
```

確認 `metadata.count` > 0 且內容正確。

---

## Phase 3: 更新專案文件

### Step 1: 將 server.json 加入版本控制

```bash
git add server.json
git commit -m "Add server.json for MCP Registry publishing

Published as io.github.kiki830621/{project-name} on the official MCP Registry.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push origin main
```

### Step 2: 更新 README.md

在 README 的 Installation 區塊加入：

```markdown
### MCP Registry

Published on the [Official MCP Registry](https://registry.modelcontextprotocol.io) as `io.github.kiki830621/{project-name}`.
```

**檢查**：如果 README 已有此資訊則跳過。所有語言版本的 README 都要同步更新。

### Step 3: 提交文件更新

```bash
git add README.md README_zh-TW.md 2>/dev/null
git commit -m "Add MCP Registry information to README

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push origin main
```

---

## Phase 4: 第三方目錄（可選）

使用 AskUserQuestion 詢問：
> 是否要提交到第三方 MCP 目錄？
> - 不需要（只發布到官方 Registry）
> - mcpservers.org（常見第三方目錄）
> - awesome-mcp-servers（GitHub Awesome List）

### 選項 A: mcpservers.org

```bash
open "https://mcpservers.org"
```

通常需要填寫表單或提交 PR。提示使用者手動完成。

### 選項 B: awesome-mcp-servers

```bash
open "https://github.com/punkpeye/awesome-mcp-servers"
```

Fork repo → 在對應分類加入條目 → 提交 PR。提示使用者手動完成。

---

## Phase 5: 完成報告

```markdown
# MCP Registry 發布完成

## 專案資訊
- 專案: {project-name}
- 版本: {version}
- Namespace: io.github.kiki830621/{project-name}

## Registry 連結
- 搜尋: https://registry.modelcontextprotocol.io/v0.1/servers?search={project-name}

## 已完成
- [x] server.json 已建立並驗證
- [x] mcp-publisher 認證完成
- [x] 發布到 MCP Registry
- [x] 驗證 Registry 可查詢
- [x] server.json 已提交
- [x] README 已更新
- [ ] 第三方目錄（{視選擇}）

## 後續版本更新
更新版本時：
1. 執行 `/mcp-tools:mcp-deploy` 部署新版本
2. 更新 `server.json`：
   - `version`（頂層）
   - `packages[].version`
   - `packages[].identifier`（URL 含版本號）
   - `packages[].fileSha256`（重新計算）
3. 用 `/validate` 驗證：`cat server.json | curl -s -X POST "https://registry.modelcontextprotocol.io/v0.1/validate" -H "Content-Type: application/json" -d @-`
4. 執行 `mcp-publisher publish` 更新 Registry
```

---

## 快速參考

### server.json 必要欄位

| 欄位 | 必要 | 說明 |
|------|:---:|------|
| `name` | ✅ | `io.github.{username}/{project}` 格式 |
| `description` | ✅ | 最多 100 字元 |
| `version` | ✅ | 語義化版本號（字串） |
| `packages` | ✅ | 至少一個套件 |
| `packages[].registryType` | ✅ | `mcpb`/`npm`/`pypi`/`nuget`/`oci` |
| `packages[].identifier` | ✅ | 套件識別符 |
| `packages[].transport` | ✅ | `{"type": "stdio"}` |
| `packages[].fileSha256` | 推薦 | MCPB 類型建議提供 |
| `repository` | 推薦 | `url` + `source` |

### mcp-publisher 命令

| 命令 | 說明 |
|------|------|
| `mcp-publisher init` | 生成 server.json 模板 |
| `mcp-publisher login github` | GitHub OAuth 認證（device code flow） |
| `mcp-publisher publish` | 發布到 Registry |
| `mcp-publisher logout` | 清除認證 |

### Registry API

| Endpoint | 說明 |
|----------|------|
| `GET /v0.1/servers?search={query}` | 搜尋 |
| `POST /v0.1/validate` | 驗證 server.json |

### Namespace 規則

| 認證方式 | Namespace |
|---------|-----------|
| GitHub | `io.github.{username}/*` |
| GitLab | `io.gitlab.{username}/*` |
| DNS | `{domain}/*` |

### 常見問題

| 問題 | 解決方案 |
|------|----------|
| `mcp-publisher` 找不到 | `brew install mcp-publisher` |
| 401 token expired | 重新 `mcp-publisher login github` |
| 422 validation failed | 用 `/validate` endpoint 查看具體錯誤 |
| `description` 太長 | 精簡到 100 字元以內 |
| `name` 格式錯誤 | 必須是 `namespace/project` 格式 |
| 缺少 `transport` | 加入 `"transport": {"type": "stdio"}` |
| snake_case 欄位被拒 | 全部改 camelCase（`registryType`、`fileSha256`） |
| 版本衝突 | 不能覆蓋已發布版本，需要新版本號 |
