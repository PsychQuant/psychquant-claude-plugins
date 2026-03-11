# che-creative-suite

協調 **che-svg-mcp**（向量）與 **che-pixel-mcp**（點陣）的圖形處理工作流。

本 plugin 不包含 MCP server，而是提供 skill 和 agent 來智慧路由圖形任務。

## 依賴

需要安裝以下 plugin 之一或兩者：

| Plugin | 功能 | 工具數 |
|--------|------|--------|
| `che-svg-mcp` | 向量圖形（SVG 編輯、路徑、形狀） | 33 |
| `che-pixel-mcp` | 點陣圖形（濾鏡、色彩、合成） | 36 |

## 提供的功能

### Skill: creative-router
Auto-triggered — 當使用者提到圖形編輯、設計、影像處理時自動路由到正確的 MCP server。

### Agent: creative-agent
用於複合任務（例如：建立 SVG logo → 匯出 PNG → 加濾鏡 → 合成到照片上）。

## 安裝

```bash
# 安裝完整套件
/plugin install che-svg-mcp@PsychQuant/psychquant-claude-plugins
/plugin install che-pixel-mcp@PsychQuant/psychquant-claude-plugins
/plugin install che-creative-suite@PsychQuant/psychquant-claude-plugins
```
