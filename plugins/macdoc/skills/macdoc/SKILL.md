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

### Ollama 設定

本機有 Ollama 的話直接用：
```bash
macdoc ocr handwritten.pdf --backend ollama --pages 1-3
```

如果本機沒有 Ollama（或 GPU 不夠），用 SSH tunnel 連到遠端機器：
```bash
# 建立 SSH tunnel（Kyle's Mac Studio, M4 Max/128GB）
ssh -f -N -L 11434:localhost:11434 kyle

# 然後正常使用（macdoc 預設連 localhost:11434）
macdoc ocr handwritten.pdf --backend ollama
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

# 單張圖片
macdoc ocr screenshot.png

# 指定模型
macdoc ocr document.pdf --model qwen3-vl

# 輸出到 stdout（預設）
macdoc ocr page.png
```

### 已知問題

- **MLX backend crash**：mlx-swift-lm 有 upstream bug（ml-explore/mlx-swift-lm#191），所有 VLM 模型都會 crash。暫時只能用 Ollama。
- **大頁面**：超過 8000px 的頁面會被自動縮小。

---

## SSH 遠端設定

Kyle 的 Mac Studio 上已安裝 Ollama 和多個模型：

```bash
# ~/.ssh/config 已設定
Host kyle
  HostName 172.22.18.70
  User kylelin

# 建 tunnel
ssh -f -N -L 11434:localhost:11434 kyle

# 確認連線
curl -s http://localhost:11434/api/tags | python3 -m json.tool
```

---

## 與其他工具的搭配

| 場景 | 工具組合 |
|------|---------|
| 手寫筆記 → TikZ 圖 | `macdoc ocr` → 辨識內容 → 寫 TikZ → `xelatex` 編譯 |
| SRT → handout 網頁 | `macdoc convert --to html` → `inject-search.py` |
| PDF 筆記 → PNG | `pdftoppm -png -r 200`（不是 macdoc，是 poppler） |
| 學生作業 .docx → 閱讀 | 用 che-word-mcp 的 `get_document_text`（不需要 macdoc） |
