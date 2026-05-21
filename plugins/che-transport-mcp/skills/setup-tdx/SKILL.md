---
name: setup-tdx
description: Guide user through obtaining TDX (運輸資料流通服務) credentials and seeding them into the macOS keychain so che-transport-mcp tools can authenticate. Use when user reports che-transport-mcp tools failing with "TDX auth failed" / "Missing TDX credentials" / "401" errors, when the SessionStart banner shows "⚠ TDX credentials missing", or when user explicitly asks to set up TDX / 註冊 TDX / 拿 TDX API key. The credentials live under keychain service "che-transport-tdx" with accounts "client_id" and "client_secret".
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Setup TDX credentials for che-transport-mcp

TDX 運輸資料流通服務 is the Taiwan government open-data API that all 23 tools in this plugin query. Free tier = 50 requests/min, no card needed.

## Step 1: Confirm credentials aren't already seeded

```bash
security find-generic-password -s che-transport-tdx -a client_id >/dev/null 2>&1 \
  && security find-generic-password -s che-transport-tdx -a client_secret >/dev/null 2>&1 \
  && echo "✓ already seeded" \
  || echo "⚠ missing — proceed to Step 2"
```

If both exist, you're done — restart Claude Code (Cmd+Q + reopen) and try a tool like `mcp__che-transport-mcp__rail_list_systems`.

## Step 2: Register a TDX account (user action)

Direct the user to:

> https://tdx.transportdata.tw/register

Free, no card, ~2 min. After signup the user needs to:

1. Log in to <https://tdx.transportdata.tw/>
2. Go to **會員中心 → API 金鑰**
3. Create an "API Key" — the page shows `client_id` and `client_secret`
4. Copy both somewhere reachable (Notes, password manager). The page won't redisplay client_secret after you leave.

**Do NOT** paste either value into the chat. The keychain seed step uses interactive `read` so credentials never appear in Claude Code's transcript.

## Step 3: Seed the keychain

The source repo ships `scripts/setup-tdx.sh` which prompts interactively. The user has two paths:

### Path A — source repo present

If the user has cloned `PsychQuant/che-transport-mcp` locally:

```bash
cd /path/to/che-transport-mcp
make setup-tdx
```

### Path B — keychain commands directly

If the user only has the installed plugin (no source repo), they can seed manually:

```bash
# In Terminal (NOT this chat) — the read -s flag keeps the secret invisible
read -p "client_id: " TDX_ID && \
  security add-generic-password -U -s che-transport-tdx -a client_id -w "$TDX_ID" && \
  read -s -p "client_secret: " TDX_SECRET && echo && \
  security add-generic-password -U -s che-transport-tdx -a client_secret -w "$TDX_SECRET" && \
  echo "✓ seeded"
unset TDX_ID TDX_SECRET
```

The `-U` flag updates an existing entry if present.

## Step 4: Verify

```bash
# Quick sanity check — does the binary accept the creds?
~/bin/CheTransportMCP --check-auth
```

Expected output: `✓ TDX credentials valid`.

If it errors:
- `auth failed: HTTP 401` → credentials wrong or keychain entry malformed. Re-run Step 3 carefully.
- `Network error` → check internet / TDX endpoint reachability.
- `Keychain item not found` → keychain seeding silently no-op'd. Re-run Step 3 in Terminal (the `read` command does not work inside Claude Code's chat).

## Step 5: Restart Claude Code

Even after `--check-auth` succeeds, the MCP server already spawned needs a restart to pick up the new creds. **Cmd+Q (fully quit)** + reopen Claude Code. Closing the window is not enough.

## When NOT to invoke this skill

- User reports tools returning empty arrays `{"matches": [], "trains": []}` — that's "empty ≠ error" by design, not a credential issue
- User reports `429 rate limit` — credentials are fine, slow down request rate
- User reports `Invalid station '...'` — credentials are fine, query format wrong (NSQL discipline applies: use `rail_search_stations` first to get IDs)
