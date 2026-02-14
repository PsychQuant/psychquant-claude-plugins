---
description: Scan and exclude build artifacts from Dropbox sync
argument-hint: [path]
allowed-tools: Bash(*)
---

# Dropbox Ignore

Scan for build artifact directories and exclude them from Dropbox sync using `com.dropbox.ignored` xattr.

## Usage

- `/dropbox-ignore` — scan current working directory
- `/dropbox-ignore ~/Library/CloudStorage/Dropbox` — scan a specific path

## Instructions

Run the dropbox-ignore binary with the provided path argument (or current directory if none given):

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/dropbox-ignore" "${ARGUMENTS:-$PWD}"
```

Display the output to the user. If directories were newly excluded, explain what was done. If the path is not under Dropbox, inform the user.
