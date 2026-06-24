---
name: apple-agreement-accept
description: |
  Unblock Apple notarization / signed releases when blocked by an updated or
  expired Apple Developer Program License Agreement (the notarytool / Transporter
  HTTP 403 "A required agreement is missing or has expired"). Accepts the pending
  agreement on developer.apple.com via Safari + AppleScript, then re-verifies and
  resumes the release.
  Use when: `xcrun notarytool` / `make release-signed` fails with 403 "required
  agreement", or user says "notarization blocked", "公證被擋", "Apple 協議過期",
  "accept apple agreement", "Program License Agreement", "notary 403", "release
  卡在 Apple 協議".
  Do NOT use for 401 "Invalid credentials" (that is an app-specific-password /
  key problem — re-run `xcrun notarytool store-credentials`, a user-only action).
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Apple Agreement Accept — unblock notarization

When Apple updates the **Apple Developer Program License Agreement**, notarization
stops with **HTTP 403 "A required agreement is missing or has expired"** until the
account holder accepts the new version. The Developer ID certificate and the
keychain notary profile are fine — only the legal agreement is stale. This skill
drives the acceptance via Safari (which holds the logged-in developer session),
then resumes the release.

> **The single most important gotcha**: after you accept, notarytool's 403 can
> persist for **several minutes** (Apple's notary service caches agreement status
> and lags the portal). **Poll — do not conclude failure on the first 403.** This
> nearly caused a false "you must fix it manually" verdict during the discovery run.

## Step 0 — Triage the error (don't guess)

```bash
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" 2>&1 | head -3
```

| Output | Meaning | Action |
|--------|---------|--------|
| `Successfully received submission history.` | Agreements fine | Nothing to do — go straight to the release |
| `HTTP status code: 403 ... required agreement ... missing or has expired` | **Agreement stale** | This skill |
| `HTTP status code: 401 ... Invalid credentials` | App-specific password / API key revoked or expired | NOT this skill — user re-runs `xcrun notarytool store-credentials <profile>` (user-only; never echo the password) |

Only continue past Step 0 on a **403 agreement** error.

## Step 1 — Open the developer account + check login

```bash
safari-browser open "https://developer.apple.com/account"
sleep 3
safari-browser documents | grep -i apple.com
```

- URL ends at `developer.apple.com/account` (title "Account - Apple Developer") → **logged in**, continue.
- URL is `idmsa.apple.com/IDMSWebAuth/signin...` → **not logged in**. Login (Apple ID + password + **2FA**) is **user-only** — ask the user to log in in that Safari tab, then continue. Never handle the Apple password or 2FA code.

## Step 2 — Find the agreement banner (use JS, not just snapshot)

The "Review agreement" banner is rendered async by an SPA and is effectively
**one-shot**: it shows on the first post-login load and often will NOT re-render on
reloads after you've entered the review flow once. `snapshot -i` / `get text` can
miss it — query the **live DOM** instead:

```bash
safari-browser js --url-endswith "/account" '
(function(){
  var out=[];
  document.querySelectorAll("button,a,[role=button]").forEach(function(e){
    var t=(e.innerText||e.textContent||"").trim();
    if(/review agreement|agree/i.test(t)&&t.length<40)out.push(e.tagName+"["+t+"]");
  });
  var hasBanner=/program license agreement has been updated|regain access/i.test(document.body.innerText||"");
  return "banner="+hasBanner+" | "+(out.join(" ;; ")||"NONE");
})()'
```

- Banner present + a "Review agreement" control → Step 3.
- Banner gone but notarytool still 403 → Step 5 (re-trigger), or the agreement may already be accepted and only propagation is pending (Step 4).

## Step 3 — Review → Agree

1. Click "Review agreement" (grab a fresh ref each time — refs shift):
   ```bash
   REF=$(safari-browser snapshot -i --url-endswith "/account" | grep -i '"Review agreement"' | grep -oE '@e[0-9]+' | head -1)
   safari-browser click "$REF" --url-endswith "/account"
   sleep 3
   ```
   This lands on `developer.apple.com/account/agree/<token>/terms` with an **Agree**
   button. (Acceptance per Apple's own terms = clicking "Agree"; the only checkboxes
   on the page are **marketing email opt-ins** — leave them unchecked.)
2. **Transparency / consent**: this is a legal acceptance on the user's behalf.
   Surface *which* agreement (read the page heading) and **confirm before clicking
   Agree** via AskUserQuestion — UNLESS the user has already explicitly authorized
   you to accept it.
3. Click Agree (verify the ref is non-empty first — an empty ref silently no-ops):
   ```bash
   AREF=$(safari-browser snapshot -i --url "developer.apple.com/account/agree" | grep -iE '"Agree"' | grep -i submit | grep -oE '@e[0-9]+' | head -1)
   [ -n "$AREF" ] && safari-browser click "$AREF" --url "developer.apple.com/account/agree"
   ```

## Step 4 — Poll notarytool until the 403 clears (THE gotcha)

Acceptance propagates to the notary service with a lag. Poll, don't give up:

```bash
for i in $(seq 1 10); do
  if xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" 2>&1 | grep -q "Successfully received"; then
    echo "✅ agreement effective — notarization unblocked"; break
  fi
  echo "still 403 (propagation lag), retry $i/10..."; sleep 45
done
```

A reliable secondary signal that the portal side is satisfied: the **Certificates**
page loads without an agreement gate (`developer.apple.com/account/resources/certificates/list`).

## Step 5 — If the banner won't surface

- **Hit a gated resource** to re-trigger the acceptance interstitial:
  `safari-browser open "https://developer.apple.com/account/resources/certificates/list"` then re-check Step 2's JS. (If Certificates loads cleanly with no gate, the portal agreement is likely already satisfied → it's a Step 4 propagation lag, keep polling.)
- **Re-login** (log out / back in) re-triggers the first-load banner — user-only.
- **Multi-tab `--url` ambiguity**: repeated `safari-browser open` spawns duplicate
  tabs; `--url developer.apple.com/account` then matches several and errors. Use
  `--url-endswith "/account"`, or `safari-browser close --url "..." --first-match`
  to collapse duplicates first.

## Step 6 — Resume the release

Once Step 4 shows "Successfully received", continue where the release left off:

```bash
export DEVELOPER_ID="<sha1>"; export NOTARY_PROFILE="<profile>"
make release-signed VERSION=vX.Y.Z   # build → sign → notarize → tag → upload
```

## Iron rules

- **Never** handle the Apple ID password or 2FA — login is user-only.
- **Confirm before the Agree click** unless the user explicitly authorized acceptance — it is an irreversible legal action.
- **Never** do an unsigned/ad-hoc release to "work around" this — on macOS 26 an
  ad-hoc binary cannot trigger TCC grants and breaks Full Disk Access for users.
  The agreement must be accepted so notarization can complete.
- **Poll for propagation** (Step 4) — a single 403 right after acceptance is not failure.
