---
name: setup-tdx
description: Guide user through obtaining TDX (運輸資料流通服務) credentials and seeding them into the macOS keychain so che-transport-mcp tools can authenticate. Use when user reports che-transport-mcp tools failing with "TDX auth failed" / "Missing TDX credentials" / "401" errors, when the SessionStart banner shows "⚠ TDX credentials missing", or when user explicitly asks to set up TDX / 註冊 TDX / 拿 TDX API key / 設定憑證. The credentials live under keychain service "che-transport-tdx" with accounts "client_id" and "client_secret".
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Setup TDX credentials for che-transport-mcp

TDX 運輸資料流通服務 is the Taiwan government open-data API that all 23 tools in this plugin query. Free tier = 50 requests/min, no card needed.

This skill **launches the binary's interactive `--setup` flow in a real Terminal window**. That is deliberate: `CheTransportMCP --setup` reads `client_secret` via `getpass()` so the secret never echoes and never enters Claude Code's transcript. Do NOT try to seed the keychain via the Bash tool with the secret inline — that would leak it into the conversation log.

The actual setup logic lives in the **signed + notarized Swift binary** (`CheTransportMCP --setup`) — interactive prompt, keychain write, and a live OAuth verification all in one code path that shares the keychain module with credential *reads*. The plugin ships a tiny `bin/setup-tdx.sh` whose only job is to be an `open`-able entry point that forwards to `wrapper --setup` (the wrapper auto-downloads the binary first if needed).

## Step 1: Check if already seeded

```bash
security find-generic-password -s che-transport-tdx -a client_id  >/dev/null 2>&1 \
  && security find-generic-password -s che-transport-tdx -a client_secret >/dev/null 2>&1 \
  && echo "SEEDED" || echo "MISSING"
```

If `SEEDED`: tell the user credentials already exist. Ask if they want to re-run setup anyway (e.g. credentials rotated / wrong). If they don't, stop here — just remind them to `Cmd+Q` + reopen Claude Code if tools still fail.

If `MISSING`: proceed.

## Step 2: Locate the launcher

The launcher shim ships inside this plugin at `bin/setup-tdx.sh`. Find it (the version path segment changes between releases, so glob it):

```bash
SETUP=$(ls ~/.claude/plugins/cache/*/che-transport-mcp/*/bin/setup-tdx.sh 2>/dev/null | sort -V | tail -1)
echo "$SETUP"
```

If empty, fall back to a broader search:

```bash
find ~/.claude/plugins -path '*che-transport-mcp*/bin/setup-tdx.sh' -type f 2>/dev/null | sort -V | tail -1
```

If still nothing, the plugin install is broken — tell the user to re-run `/plugin install che-transport-mcp@psychquant-claude-plugins`.

## Step 3: Launch in a real Terminal window

```bash
open -a Terminal "$SETUP"
```

This opens a **separate Terminal window** running `wrapper --setup`, which:

1. Auto-downloads the `CheTransportMCP` binary if it isn't installed yet
2. Runs `CheTransportMCP --setup` — prints the TDX register URL, prompts for `client_id` (visible) and `client_secret` (hidden via `getpass`)
3. Writes both to keychain service `che-transport-tdx` via the binary's `Auth.save`
4. Verifies with a real OAuth round-trip against TDX
5. Prints a reminder to restart Claude Code

Tell the user clearly:

> 已幫你開了一個 Terminal 視窗。請在**那個視窗**裡完成設定 — client_secret 全程不會經過這裡的對話記錄。完成後回來這裡告訴我。

Then wait for the user to report back.

## Step 4: Confirm result

After the user says they're done, re-check:

```bash
security find-generic-password -s che-transport-tdx -a client_id  >/dev/null 2>&1 \
  && security find-generic-password -s che-transport-tdx -a client_secret >/dev/null 2>&1 \
  && echo "SEEDED ✓" || echo "STILL MISSING"
```

If still missing, the user likely aborted or hit an error in the script window — ask what the script printed, and walk them through re-running `bash "$SETUP"`.

## Step 5: Restart reminder

Even after credentials verify, the MCP server already spawned by the current Claude Code session won't see them. The user must **fully quit Claude Code (Cmd+Q)** and reopen. Closing the window is not enough — MCP server processes outlive a closed window.

## Fallback: no Terminal.app available

If `open -a Terminal` is unavailable (SSH session, headless), tell the user to run the binary's `--setup` directly in whatever interactive shell they have. Emphasize: run it in a **terminal, not in Claude Code chat** — the secret prompt needs a TTY.

```bash
~/bin/CheTransportMCP --setup
```

Same interactive flow, no shell-script middleman. If the binary isn't at `~/bin/CheTransportMCP` yet, run the wrapper instead (it downloads then forwards):

```bash
~/.claude/plugins/cache/*/che-transport-mcp/*/bin/che-transport-mcp-wrapper.sh --setup
```

## When NOT to invoke this skill

- User reports tools returning empty arrays `{"matches": [], "trains": []}` — that's "empty ≠ error" by design, not a credential issue
- User reports `429 rate limit` — credentials are fine, slow down request rate
- User reports `Invalid station '...'` — credentials are fine, query format wrong (use `rail_search_stations` first to get IDs)
