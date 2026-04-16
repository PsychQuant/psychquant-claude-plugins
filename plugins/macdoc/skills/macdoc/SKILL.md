---
name: macdoc
description: |
  macOS 原生文件處理 CLI 工具的使用指南。
  當需要做格式轉換（SRT→HTML、MD→HTML、DOCX→MD）、
  VLM OCR（PDF/圖片→文字）、或 SRT 逐字稿處理時使用。
  觸發詞：「macdoc」「轉換格式」「OCR」「逐字稿轉HTML」
  「手寫筆記辨識」「PDF轉文字」
---

# macdoc — macOS 原生文件處理 CLI

安裝位置：`~/bin/macdoc`（或 `/usr/local/bin/macdoc`）
原始碼：`/Users/che/Developer/macdoc`

## 子命令總覽

| 子命令 | 用途 | 常用場景 |
|--------|------|---------|
| `convert` | 格式轉換 | SRT→HTML、MD→HTML、DOCX→MD |
| `ocr` | VLM OCR | PDF/圖片→文字（手寫筆記辨識） |
| `config` | 設定管理 | AI CLI 工具、OCR host/model 預設值 |
| `pdf` | PDF→LaTeX | 學術 PDF 處理（較少用） |
| `bib` | BibLaTeX→APA | 參考文獻格式轉換 |

---

## convert — 格式轉換

```bash
macdoc convert --to <format> [options] <input>
```

### 支援格式

| --to | 說明 | 範例 |
|------|------|------|
| `html` | 轉 HTML | SRT→逐字稿網頁、MD→講義網頁 |
| `md` | 轉 Markdown | DOCX→MD |
| `docx` | 轉 Word | MD→DOCX |
| `pdf` | 轉 PDF | MD→PDF（透過 textutil） |
| `json` | 轉 JSON | SRT→結構化 JSON |

### 常用選項

| 選項 | 說明 |
|------|------|
| `--output <path>` | 輸出檔案路徑 |
| `--full` | 輸出完整 HTML 文件（含 `<head>`），不只是 fragment |
| `--css light` | SRT 轉 HTML 時用淺色主題 |
| `--css dark` | SRT 轉 HTML 時用深色主題 |
| `--hard-breaks` | 軟換行視為硬換行 |
| `--frontmatter` | 包含 YAML frontmatter |
| `--html-extensions` | MD 中保留 `<u>/<sup>/<sub>/<mark>` |

### 常用工作流

#### SRT → 可搜尋的逐字稿 HTML

```bash
# 1. 轉換
macdoc convert --to html --css light --full --output transcript.html input.srt

# 2. 注入搜尋和說話者篩選功能（需要 inject-search.py）
python3 inject-search.py transcript.html --speakers "鄭老師:鄭老師,學生名:學生名"
```

`inject-search.py` 位於每個 handout 目錄下。

#### MD → 講義 HTML

```bash
macdoc convert --to html --full --output lecture.html notes.md
```

產出的是裸 HTML，需要手動替換 `<head>` 加入 CSS 連結和 lecture-header。

#### DOCX → Markdown

```bash
macdoc convert --to md --output output.md input.docx
```

---

## ocr — VLM OCR

```bash
macdoc ocr <input> [options]
```

用 Vision Language Model 做 OCR，支援手寫筆記、印刷文件、截圖。

### Backend 選擇

| Backend | 選項 | 說明 |
|---------|------|------|
| **Ollama**（預設） | `--backend ollama` | 透過 Ollama HTTP API，需要先啟動 Ollama |
| **MLX**（本地） | `--backend mlx` | 用 mlx-swift-lm 本地推理（⚠️ 目前有 upstream bug） |

### Ollama host 設定（v1.1+）

**推薦流程**：用 `config ocr` 設定好 host profile，之後就不用每次傳 `--host`。

```bash
# 一次性設定（本機或遠端 Kyle）
macdoc config ocr add-host kyle localhost:11435   # 先建 SSH tunnel 到 kyle
macdoc config ocr add-host local localhost:11434  # 本機 Ollama
macdoc config ocr set-default kyle                # 設為預設

# 之後直接 OCR，不用 --host
macdoc ocr handwritten.pdf
```

**`--host` 解析規則**：先當 profile 名查 config，找不到才當原始地址。

```bash
macdoc ocr file.pdf                       # 用 default profile
macdoc ocr file.pdf --host local          # 切換到 local profile
macdoc ocr file.pdf --host 192.168.1.50:11434  # 不是 profile,當原始地址
```

### SSH tunnel 到 Kyle

Kyle 的 Mac Studio（M4 Max/128GB）上有 Ollama + glm-ocr：

```bash
# 建 SSH tunnel（Kyle's Ollama 預設只聽 localhost）
ssh -fN -L 11435:localhost:11434 kyle

# 確認連線
curl -s http://localhost:11435/api/tags | python3 -m json.tool

# OCR（如果已設 default=kyle）
macdoc ocr notes.pdf --output notes.md

# 長時間 OCR 記得用 caffeinate 防電腦睡眠（SSH tunnel 會斷）
caffeinate -i -- macdoc ocr large.pdf --output large.md
```

### 可用模型

| 模型 | 用途 | --model 值 |
|------|------|-----------|
| **glm-ocr**（預設） | 中文手寫/印刷 OCR | `glm-ocr` |
| qwen3-vl | 多語言 VLM | `qwen3-vl` |
| minicpm-v | 輕量 VLM | `minicpm-v` |

### 常用範例

```bash
# 手寫筆記 PDF（指定頁碼）
macdoc ocr notes.pdf --pages 1-3 --output notes.md

# 大型 PDF 分段 OCR(避免長時間 tunnel 斷線)
macdoc ocr big.pdf --pages 1-60  --output part1.md
macdoc ocr big.pdf --pages 61-120 --output part2.md
cat part1.md part2.md > full.md

# 單張圖片
macdoc ocr screenshot.png

# 指定模型(覆寫 config default)
macdoc ocr document.pdf --model qwen3-vl
```

### 已知問題

- **MLX backend crash**：mlx-swift-lm 有 upstream bug（ml-explore/mlx-swift-lm#191），所有 VLM 模型都會 crash。暫時只能用 Ollama。
- **SSH tunnel 長時間會斷**：連線超過 2-3 小時會 timeout。解法是分段 OCR（`--pages`）或用 `caffeinate -i`。
- **大頁面**：超過 8000px 的頁面會被自動縮小。

---

## config — 設定管理

設定檔存在 `~/.config/macdoc/config.json`。

### config ai — AI CLI 工具設定

```bash
macdoc config ai detect                  # 偵測本機已安裝的 codex/claude/gemini
macdoc config ai list                    # 顯示目前設定
macdoc config ai set transcription codex # 設定 one-shot 轉寫預設後端
macdoc config ai set agent claude        # 設定 agentic 後端
```

### config ocr — OCR host/model 設定（v1.1+）

| 子命令 | 用途 |
|--------|------|
| `list` | 顯示目前 OCR 設定（含 profile 列表） |
| `add-host <name> <addr>` | 新增/更新 host profile |
| `remove-host <name>` | 移除 profile |
| `set-default <name>` | 設定預設 host |
| `set-model <model>` | 設定預設模型（如 glm-ocr） |
| `set-backend <ollama\|mlx>` | 設定預設後端 |

```bash
# 完整範例：設定 kyle 遠端 + local 兩個 profile
ssh -fN -L 11435:localhost:11434 kyle  # 建 tunnel
macdoc config ocr add-host kyle localhost:11435
macdoc config ocr add-host local localhost:11434
macdoc config ocr set-default kyle
macdoc config ocr set-model glm-ocr

# 查看
macdoc config ocr list
# === OCR 設定 ===
# backend: ollama
# model:   glm-ocr
# default host: kyle → localhost:11435
#
# === Host Profiles ===
#   kyle → localhost:11435 ★
#   local → localhost:11434
```

---

## 與其他工具的搭配

| 場景 | 工具組合 |
|------|---------|
| 手寫筆記 → TikZ 圖 | `macdoc ocr` → 辨識內容 → 寫 TikZ → `xelatex` 編譯 |
| SRT → handout 網頁 | `macdoc convert --to html` → `inject-search.py` |
| PDF 筆記 → PNG | `pdftoppm -png -r 200`（不是 macdoc，是 poppler） |
| 學生作業 .docx → 閱讀 | 用 che-word-mcp 的 `get_document_text`（不需要 macdoc） |

---

## 版本紀錄

- **1.1.0**：新增 `config ocr` 子命令組,支援具名 host profile(`--host kyle` 等),預設 host/model 可存 config
- **1.0.0**：初版
