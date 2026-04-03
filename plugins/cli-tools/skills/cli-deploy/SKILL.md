---
name: cli-deploy
description: 部署 Swift CLI 工具（編譯 universal binary、建立 GitHub Release、安裝到 ~/bin）。在 Swift CLI 專案目錄中使用。
argument-hint: [version]
allowed-tools: Read, Write, Edit, Bash(swift:*), Bash(lipo:*), Bash(file:*), Bash(shasum:*), Bash(git:*), Bash(gh:*), Bash(rm:*), Bash(cp:*), Bash(mkdir:*), Bash(ls:*), Bash(chmod:*), Bash(codesign:*), Bash(xattr:*), Grep, Glob, AskUserQuestion
disable-model-invocation: true
---

# CLI Deploy — 部署 Swift CLI 工具

完整的 CLI 工具部署流程：編譯 universal binary → 版本更新 → GitHub Release。

## 參數

- `$1` = 版本號（可選，如 `1.0.0`）

---

## Phase 0: 檢測專案

### Step 1: 確認 Swift CLI 專案

```bash
pwd
ls Package.swift
```

**必須存在**：`Package.swift` 且包含 `executableTarget`

### Step 2: 取得 Binary 名稱

```bash
BINARY_NAME=$(grep -A5 'executableTarget\|\.executable' Package.swift | grep 'name:' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
echo "Binary: $BINARY_NAME"
```

### Step 3: 取得當前版本

搜尋版本號來源（依優先順序）：

1. `Sources/*/Version.swift` — 找 `static let current = "x.x.x"` 或類似
2. 最新 git tag：`git describe --tags --abbrev=0 2>/dev/null`
3. 如果都沒有，預設 `0.1.0`

### Step 4: 確認新版本號

如果提供了 `$1`，使用該版本。否則用 AskUserQuestion 詢問，預設 patch bump。

---

## Phase 1: 編譯 Universal Binary

### Step 1: 清理舊 build

```bash
rm -rf .build 2>/dev/null || true
```

### Step 2: 編譯兩種架構

```bash
swift build -c release --arch arm64
swift build -c release --arch x86_64
```

### Step 3: 建立 Universal Binary

```bash
mkdir -p .release
lipo -create \
    .build/arm64-apple-macosx/release/$BINARY_NAME \
    .build/x86_64-apple-macosx/release/$BINARY_NAME \
    -output .release/$BINARY_NAME

# 清除 xattr 汙染（Dropbox 目錄 build 的 binary 帶 com.dropbox.attrs）
xattr -cr .release/$BINARY_NAME

# 重新簽名（lipo 破壞原始 code signature）
codesign --force --sign - .release/$BINARY_NAME
```

### Step 4: 驗證

```bash
file .release/$BINARY_NAME
lipo -info .release/$BINARY_NAME
```

**預期**：`Mach-O universal binary with 2 architectures: [x86_64] [arm64]`

---

## Phase 2: 更新版本與文檔

### Step 1: 更新版本號

找到版本號所在的檔案並更新：

- `Sources/*/Version.swift` — 更新版本字串
- 其他可能的位置由 Step 0.3 決定

### Step 2: 更新 CHANGELOG.md

在 CHANGELOG.md 頂部加入新版本（如果檔案存在）：

```markdown
## [{version}] - {date}

### Added
- ...

### Changed
- ...

### Fixed
- ...
```

用 AskUserQuestion 詢問變更摘要。

### Step 3: 更新 README.md（如適用）

如果 README.md 有 Version History 區塊，加入新版本。

---

## Phase 3: 發布到 GitHub

### Step 1: Commit + Push

```bash
git add -A
git commit -m "v{version}: {change-summary}"
git push origin main
```

### Step 2: 建立 GitHub Release

```bash
OWNER_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# 建立 Release
RELEASE_ID=$(gh api repos/$OWNER_REPO/releases --method POST \
  -f tag_name="v{version}" \
  -f target_commitish="main" \
  -f name="v{version}" \
  -f body="{release-notes}" \
  -F draft=false \
  -F prerelease=false \
  --jq '.id')

echo "Release created: ID=$RELEASE_ID"

# 上傳 Binary（用 curl，支援進度條）
TOKEN=$(gh auth token)
curl -L -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/octet-stream" \
  "https://uploads.github.com/repos/$OWNER_REPO/releases/$RELEASE_ID/assets?name=$BINARY_NAME" \
  --data-binary "@.release/$BINARY_NAME" \
  --progress-bar -o /dev/null -w "Upload: HTTP %{http_code}, %{size_upload} bytes\n"

# 驗證
gh release view v{version} --json assets --jq '.assets[] | "\(.name) (\(.size) bytes)"'
```

Release Notes 模板：

```markdown
## Install

\```bash
curl -fsSL https://github.com/{owner}/{repo}/releases/latest/download/{binary} -o ~/bin/{binary} && chmod +x ~/bin/{binary}
\```

---

{CHANGELOG 內容}
```

### Step 3: 安裝到本地

```bash
cp .release/$BINARY_NAME ~/bin/$BINARY_NAME
chmod +x ~/bin/$BINARY_NAME
```

驗證：

```bash
~/bin/$BINARY_NAME version 2>/dev/null || ~/bin/$BINARY_NAME --version 2>/dev/null
```

### Step 4: 清理

```bash
rm -rf .release
```

---

## Phase 4: 完成報告

```markdown
# CLI Deploy 完成

- **專案**: {project-name}
- **版本**: v{version}
- **Binary**: {binary-name} (universal: arm64 + x86_64)
- **Release**: https://github.com/{owner}/{repo}/releases/tag/v{version}
- **本地**: ~/bin/{binary-name}

安裝指令（其他使用者）：
curl -fsSL https://github.com/{owner}/{repo}/releases/latest/download/{binary} -o ~/bin/{binary} && chmod +x ~/bin/{binary}
```

---

## 快速參考

### 版本號建議

| 變更類型 | 版本變更 | 範例 |
|---------|---------|------|
| 新功能 | MINOR +1 | 1.0.0 → 1.1.0 |
| Bug 修復 | PATCH +1 | 1.0.0 → 1.0.1 |
| 破壞性變更 | MAJOR +1 | 1.0.0 → 2.0.0 |

### 常見問題

| 問題 | 解決方案 |
|------|----------|
| Dropbox 衝突導致 build 失敗 | `rm -rf .build` 後重新編譯 |
| lipo 失敗 | 確認兩種架構都編譯成功 |
| gh release create 卡住 | 用 `gh api` + `curl` 分步驟上傳 |
| codesign 失敗 | `codesign --force --sign -` 用 ad-hoc 簽名 |
