# cli-tools Plugin

Swift CLI tool lifecycle management — build, deploy, install, upgrade via GitHub Releases.

Counterpart to `mcp-tools` (for MCP servers), this plugin handles CLI tools.

## Skills

| Skill | Purpose |
|-------|---------|
| `/cli-tools:cli-deploy` | Build universal binary + GitHub Release + install to ~/bin/ |
| `/cli-tools:cli-new-app` | Scaffold new Swift CLI project (Package.swift + ArgumentParser) |
| `/cli-tools:cli-install` | Install CLI tool from GitHub Release to ~/bin/ |
| `/cli-tools:cli-upgrade` | Check for updates and upgrade installed CLI tools |

## Workflow

```
cli-new-app → develop → cli-deploy → cli-install (other users)
                                    → cli-upgrade (existing users)
```

## Known CLI Tools

| Binary | Repo | Description |
|--------|------|-------------|
| gfh | PsychQuant/GiftHub | Git LFS backend with Google Drive |
