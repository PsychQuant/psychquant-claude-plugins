---
description: 部署 MCP Server 專案（編譯、打包 mcpb、建立 GitHub Release）
argument-hint: [version]
allowed-tools: Read, Write, Edit, Bash(swift:*), Bash(lipo:*), Bash(file:*), Bash(git:*), Bash(gh:*), Bash(zip:*), Bash(rm:*), Bash(cp:*), Bash(mkdir:*), Bash(ls:*), Bash(npm:*), Bash(python:*), Bash(pip:*), Grep, Glob, AskUserQuestion
---

# MCP Deploy - 部署 MCP 專案

完整的 MCP 專案部署流程：編譯 → 打包 → 發布。

**建立新專案請用 `/mcp-tools:new-mcp-app`**

## 參數

- `$1` = 版本號（可選，如 `1.0.0`）

---

## Phase 0: 檢測專案

### Step 1: 確認目前在 MCP 專案目錄

檢查當前目錄是否為 MCP 專案：

```bash
pwd
ls -la
```

**必須存在的檔案/目錄**：
- `mcpb/` 目錄
- `mcpb/manifest.json`

如果不存在，提示使用者：
> 請先 `cd` 到 MCP 專案目錄，或使用 `/mcp-tools:new-mcp-app` 建立新專案

### Step 2: 識別語言類型

| 檔案 | 語言 |
|------|------|
| `Package.swift` | Swift |
| `pyproject.toml` 或 `setup.py` | Python |
| `package.json` + `tsconfig.json` | TypeScript |

### Step 3: 讀取當前版本

```bash
cat mcpb/manifest.json | grep '"version"'
```

### Step 4: 確認版本號

如果提供了 `$1`，使用該版本號。
否則使用 AskUserQuestion 詢問新版本號。

**版本號規則**（Semantic Versioning）：
- `MAJOR.MINOR.PATCH`
- 例：`1.0.0`、`0.8.1`、`2.1.0`

---

## Phase 1: 編譯

根據語言類型執行對應的編譯流程。

### 語言 A: Swift 編譯

#### A1: 清理舊 build（避免 Dropbox 衝突）

```bash
rm -rf .build 2>/dev/null || true
```

#### A2: 編譯兩種架構

```bash
swift build -c release --arch arm64
swift build -c release --arch x86_64
```

#### A3: 建立 Universal Binary

```bash
# 取得 binary 名稱（從 Package.swift）
BINARY_NAME=$(grep -A5 'executableTarget' Package.swift | grep 'name:' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')

lipo -create \
    .build/arm64-apple-macosx/release/$BINARY_NAME \
    .build/x86_64-apple-macosx/release/$BINARY_NAME \
    -output mcpb/server/$BINARY_NAME
```

#### A4: 驗證 Universal Binary

```bash
file mcpb/server/$BINARY_NAME
lipo -info mcpb/server/$BINARY_NAME
```

**預期輸出**：
```
mcpb/server/YourMCP: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64]
Architectures in the fat file: mcpb/server/YourMCP are: x86_64 arm64
```

---

### 語言 B: Python 打包

#### B1: 確認虛擬環境

```bash
python3 -m venv .venv 2>/dev/null || true
source .venv/bin/activate
pip install -e .
```

#### B2: 建立可執行腳本

```bash
# 建立 wrapper script
cat > mcpb/server/run.sh << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../.."
source .venv/bin/activate 2>/dev/null || true
python -m {project_name}
EOF
chmod +x mcpb/server/run.sh
```

**注意**：Python MCP 通常不打包成 binary，而是使用 wrapper script。

---

### 語言 C: TypeScript 編譯

#### C1: 安裝依賴

```bash
npm install
```

#### C2: 編譯

```bash
npm run build
```

#### C3: 建立可執行腳本

```bash
cat > mcpb/server/run.sh << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
node "$SCRIPT_DIR/../../dist/index.js"
EOF
chmod +x mcpb/server/run.sh
```

---

## Phase 2: 更新版本和打包

### Step 1: 更新 mcpb/manifest.json 版本

讀取並更新版本號：

```bash
# 使用 Edit 工具更新 "version": "x.x.x"
```

### Step 2: 更新 Server.swift / package.json 版本（如適用）

確保所有地方的版本號一致：
- `mcpb/manifest.json`
- Swift: `Server.swift` 中的 `version: "x.x.x"`
- Python: `pyproject.toml`
- TypeScript: `package.json`

### Step 3: 更新 CHANGELOG.md

在 CHANGELOG.md 頂部加入新版本：

```markdown
## [{version}] - {date}

### Added
- 新功能描述

### Changed
- 變更描述

### Fixed
- 修復描述
```

使用 AskUserQuestion 詢問這個版本的變更摘要。

### Step 4: 更新 README.md 版本歷史

**重要**：更新所有語言版本的 README（如 `README.md`、`README_zh-TW.md` 等）

需要更新的內容：
1. **Technical Details / 技術細節** 區塊的版本號
   - `Current Version: v{version}`
   - Framework 版本（如 MCP Swift SDK 版本）

2. **Version History / 版本歷史** 表格加入新版本：

```markdown
## Version History

| Version | Changes |
|---------|---------|
| v{version} | {change-summary} |
| ... | ... |
```

**檢查清單**：
- [ ] README.md 已更新
- [ ] README_zh-TW.md 已更新（如存在）
- [ ] 其他語言版本已更新（如存在）

如果 README.md 沒有 Version History 區塊，在 `## Installation` 之前加入。

### Step 5: 清理舊的 mcpb 檔案

```bash
rm -f mcpb/*.mcpb 2>/dev/null || true
```

### Step 6: 打包 MCPB

```bash
# 取得專案名稱
PROJECT_NAME=$(cat mcpb/manifest.json | grep '"id"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/' | tr -d ' ')

# 打包到 mcpb/ 目錄內
cd mcpb && zip -r ${PROJECT_NAME}.mcpb . -x ".*" -x "*.mcpb" && cd ..
```

### Step 7: 驗證 MCPB 套件

```bash
ls -lh mcpb/*.mcpb
unzip -l mcpb/*.mcpb | head -20
```

**必須包含**：
- `manifest.json`
- `PRIVACY.md`
- `server/` 目錄（含 binary 或 script）
- `icon.png`（推薦）

### Step 8: 驗證 manifest.json 格式

**重要**：manifest.json 必須符合 MCPB 0.3 規範，否則 Claude Desktop 會顯示 "Invalid manifest" 錯誤。

**必要欄位**：
```json
{
  "manifest_version": "0.3",
  "name": "{project-name}",
  "version": "{version}",
  "description": "{description}",
  "author": {
    "name": "Che Cheng"
  },
  "server": {
    "type": "binary",
    "entry_point": "server/{BinaryName}",
    "mcp_config": {
      "command": "${__dirname}/server/{BinaryName}",
      "args": [],
      "env": {}
    }
  }
}
```

**常見錯誤**：
| 錯誤格式 | 正確格式 |
|---------|---------|
| `"author": "Name"` | `"author": { "name": "Name" }` |
| `"repository": "url"` | `"repository": { "type": "git", "url": "..." }` |
| `"entrypoint": {...}` | `"server": {...}` |
| 缺少 `manifest_version` | `"manifest_version": "0.3"` |
| `"path": "..."` | `"entry_point": "..."` |

**不支援的欄位**（會導致錯誤）：
- ~~`id`~~ - 使用 `name`
- ~~`platforms`~~ - 不支援
- ~~`capabilities`~~ - 不支援
- ~~`display_name`~~ - 不支援
- ~~`tools`~~ - 工具從 Server 動態取得

---

## Phase 3: 發布到 GitHub

### Step 1: Git 狀態檢查

```bash
git status
```

### Step 2: 提交變更

```bash
git add -A
git commit -m "v{version}: {change-summary}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### Step 3: 推送到 GitHub

```bash
git push origin main
```

**注意**：如果使用 Git LFS，會自動上傳大型檔案。

### Step 4: 建立 GitHub Release

使用 AskUserQuestion 詢問：
1. Release 標題（預設：`v{version}`）
2. Release 說明（可從 CHANGELOG.md 複製）

#### 方法 A: 使用 gh release（推薦）

```bash
# 取得專案名稱和 binary 名稱
PROJECT_NAME=$(cat mcpb/manifest.json | grep '"name"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/' | tr -d ' ')
BINARY_NAME=$(ls mcpb/server/ | grep -v '.sh' | head -1)

gh release create v{version} \
  --title "v{version} - {title}" \
  --notes "{release-notes}" \
  mcpb/server/$BINARY_NAME
```

#### 方法 B: 使用 gh api（Fallback）

如果 `gh release create` 失敗（常見錯誤：`workflow scope may be required`），改用 API：

```bash
# Step 1: 建立 Release
gh api repos/{owner}/{repo}/releases --method POST \
  -f tag_name="v{version}" \
  -f name="v{version} - {title}" \
  -f body="{release-notes}" \
  -F draft=false \
  -F prerelease=false

# Step 2: 取得 Release ID（從上一步的回應中取得，或用以下命令）
RELEASE_ID=$(gh api repos/{owner}/{repo}/releases/tags/v{version} --jq '.id')

# Step 3: 上傳 Binary（使用 curl）
TOKEN=$(gh auth token)
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/octet-stream" \
  "https://uploads.github.com/repos/{owner}/{repo}/releases/$RELEASE_ID/assets?name=$BINARY_NAME" \
  --data-binary "@mcpb/server/$BINARY_NAME"
```

**注意**：`gh api` 不支援大型檔案上傳，必須用 `curl` 配合 `--data-binary`。

### Step 5: 複製 binary 到 ~/bin（本地安裝）

```bash
cp mcpb/server/$BINARY_NAME ~/bin/
chmod +x ~/bin/$BINARY_NAME
```

---

## Phase 4: 發布為 Claude Code Plugin（可選）

使用 AskUserQuestion 詢問：
> 是否要同時發布為 Claude Code Plugin？

如果選擇「否」，跳到 Phase 5。

### Step 1: 確認 Plugin 目錄存在

```bash
PLUGIN_DIR="/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/che-claude-plugins/plugins/{project-name}"
mkdir -p "$PLUGIN_DIR/.claude-plugin"
mkdir -p "$PLUGIN_DIR/bin"
```

### Step 2: 建立 .mcp.json

```bash
cat > "$PLUGIN_DIR/.mcp.json" << 'EOF'
{
  "{project-name}": {
    "type": "stdio",
    "command": "${CLAUDE_PLUGIN_ROOT}/bin/{project-name}-wrapper.sh",
    "description": "{description}"
  }
}
EOF
```

### Step 3: 建立 plugin.json

```bash
cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "{project-name}",
  "version": "{version}",
  "description": "{description}",
  "author": { "name": "Che Cheng" },
  "license": "MIT",
  "keywords": ["mcp", "{keywords}"]
}
EOF
```

### Step 4: 建立 wrapper script

```bash
cat > "$PLUGIN_DIR/bin/{project-name}-wrapper.sh" << 'EOF'
#!/bin/bash
# Wrapper script to find and execute {BinaryName} binary

LOCATIONS=(
    "$HOME/bin/{BinaryName}"
    "/usr/local/bin/{BinaryName}"
    "$HOME/.local/bin/{BinaryName}"
)

for loc in "${LOCATIONS[@]}"; do
    if [[ -x "$loc" ]]; then
        exec "$loc" "$@"
    fi
done

echo "ERROR: {BinaryName} binary not found!" >&2
echo "Please install from: https://github.com/kiki830621/{project-name}/releases" >&2
exit 1
EOF
chmod +x "$PLUGIN_DIR/bin/{project-name}-wrapper.sh"
```

### Step 5: 建立 README.md

從專案的 README.md 複製並簡化，或使用 manifest.json 中的資訊生成：

```markdown
# {project-name}

**{description}**

## 安裝

### 1. 編譯 Binary

\```bash
cd /path/to/{project-name}
swift build -c release
cp .build/release/{BinaryName} ~/bin/
\```

### 2. 安裝 Plugin

\```bash
claude /plugin {project-name}
\```

## 版本

- **當前版本**: {version}
- **GitHub**: https://github.com/kiki830621/{project-name}
```

### Step 6: 同步到已安裝的 plugins 目錄

```bash
INSTALLED_DIR="$HOME/.claude/plugins/marketplaces/che-claude-plugins/plugins/{project-name}"
mkdir -p "$INSTALLED_DIR/.claude-plugin"
mkdir -p "$INSTALLED_DIR/bin"
cp "$PLUGIN_DIR/.mcp.json" "$INSTALLED_DIR/.mcp.json"
cp "$PLUGIN_DIR/.claude-plugin/plugin.json" "$INSTALLED_DIR/.claude-plugin/plugin.json"
cp "$PLUGIN_DIR/bin/{project-name}-wrapper.sh" "$INSTALLED_DIR/bin/"
```

### Step 7: 提交 Plugin 變更

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/che-claude-plugins
git add plugins/{project-name}
git commit -m "Update {project-name} plugin to v{version}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
git push origin main
```

---

## Phase 5: 完成報告

```markdown
# MCP 部署完成

## 版本資訊
- 專案: {project-name}
- 版本: v{version}
- 語言: Swift / Python / TypeScript

## 發布的檔案
- Binary: `mcpb/server/{BinaryName}`
- MCPB: `{project-name}.mcpb`

## GitHub Release
- URL: https://github.com/kiki830621/{project-name}/releases/tag/v{version}

## 本地安裝
- Binary 已複製到: `~/bin/{BinaryName}`

## Claude Code Plugin（如有發布）
- Plugin 目錄: `che-claude-plugins/plugins/{project-name}`
- 已同步到: `~/.claude/plugins/marketplaces/che-claude-plugins/plugins/{project-name}`

## 下一步
- 測試: `claude mcp list` 確認 MCP 已連線
- 重啟 Claude Code 以載入新版本
```

---

## 快速參考

### 版本號建議

| 變更類型 | 版本變更 | 範例 |
|---------|---------|------|
| 新功能 | MINOR +1 | 1.0.0 → 1.1.0 |
| Bug 修復 | PATCH +1 | 1.0.0 → 1.0.1 |
| 破壞性變更 | MAJOR +1 | 1.0.0 → 2.0.0 |
| 文檔更新 | PATCH +1 | 1.0.0 → 1.0.1 |

### CHANGELOG 格式

```markdown
## [版本] - 日期

### Added（新功能）
### Changed（變更）
### Fixed（修復）
### Removed（移除）
```

### 常見問題

| 問題 | 解決方案 |
|------|----------|
| Dropbox 衝突導致 build 失敗 | `rm -rf .build` 後重新編譯 |
| lipo 失敗 | 確認兩種架構都編譯成功 |
| gh release 失敗（workflow scope） | 改用 `gh api` 方法（見 Step 4 方法 B） |
| gh release 失敗（其他） | 確認 `gh auth login` 已登入 |
| LFS 上傳失敗 | 確認 `.gitattributes` 設定正確 |
| curl 上傳 binary 失敗 | 確認 `gh auth token` 有效，檔案路徑正確 |

### MCP Server 對應表

| MCP Server | Binary 名稱 |
|------------|------------|
| che-things-mcp | CheThingsMCP |
| che-ical-mcp | CheICalMCP |
| che-apple-mail-mcp | CheAppleMailMCP |
| che-word-mcp | CheWordMCP |
