# R Shiny Debugger

功能測試導向的 R Shiny App Debug 工具。

## 特色

- **功能測試導向** — 測試「做 A 應該發生 B」，不只是看 app 能不能跑
- **前後端整合** — 同時觀察 UI 變化和 R console 輸出
- **自然語言測試** — 用口語描述測試目標
- **E2E 腳本生成** — Debug 完成後可自動產生 shinytest2 E2E 測試腳本

## 前置需求

```bash
# agent-browser
npm install -g agent-browser
agent-browser install

# R + Shiny
# 確保已安裝 R 和 shiny 套件
```

## 使用

```bash
# 互動模式
/shiny-debug

# 指定測試
/shiny-debug 上傳 CSV 後圖表會更新
```

## 命令

| 命令 | 說明 |
|------|------|
| `/shiny-debug` | 啟動功能測試工作流程 |
