---
name: safari-github-star
description: Star a GitHub repository in Safari. Use when the user asks to star, favorite, or bookmark a GitHub repo via Safari and wants the action performed inside their own logged-in Safari session.
allowed-tools:
  - Bash(safari-browser:*)
  - Bash(safari-browser *)
---

# safari-github-star

Star a GitHub repository in the user's Safari session. Handles the logged-in / not-logged-in branch explicitly.

## When to use

Trigger phrases:
- "star this repo on GitHub"
- "star browser-use/browser-harness for me"
- "bookmark this GitHub project via Safari"

Do NOT trigger for:
- Un-starring a repo (different action — would need a separate `safari-github-unstar` playbook).
- Starring via API (`gh api ...`) — unrelated to Safari UI.
- Any Chrome-based GitHub automation — use a Chrome-targeted tool.

## Preconditions

The user MUST satisfy these:

1. **Safari is running** with at least one window.
2. **Repository URL known**: Either a full URL (`https://github.com/<owner>/<name>`) or an `<owner>/<name>` slug you can expand.
3. **Login state will be detected at runtime**: The user does NOT have to be logged in before invocation. If they are not, the playbook STOPS and reports the state — it does NOT attempt to type credentials.
4. **No interstitial pages**: Cookies / privacy banners on github.com must already be dismissed for the active profile, or the first real interaction will dismiss them.

## Steps

1. **Open or focus the repo URL**
   ```bash
   safari-browser open https://github.com/<owner>/<name>
   ```
   Expected: a Safari tab shows the repo page. safari-browser's default behaviour focuses an existing matching tab rather than opening a second one.

2. **Wait for the page to settle**
   ```bash
   safari-browser wait --for-url "github.com/<owner>/<name>" --url <owner>/<name>
   ```
   Expected: the URL resolver finds the GitHub tab and readyState reaches `complete`.

3. **Detect login state**
   ```bash
   safari-browser js "!!document.querySelector('a[href=\"/login\"], a[href^=\"/login?\"]')" --url <owner>/<name>
   ```
   Expected: `true` if a sign-in link is visible (user is NOT logged in), `false` otherwise.

   - If `true`: STOP. Report "not logged in — ask the user whether they want to sign in manually or skip." Do NOT type credentials.
   - If `false`: continue to step 4.

4. **Snapshot to locate the Star button**
   ```bash
   safari-browser snapshot -i --url <owner>/<name>
   ```
   Expected: a list of `@eN` refs. Look for an element labelled `Star` or `Unstar` with an `aria-label` containing "star this repository" or the repo name. Note its ref.

5. **Check current star state before clicking**

   Examine the snapshot output or run:
   ```bash
   safari-browser js "document.querySelector('form[action$=\"/star\"]')?.getAttribute('action') || document.querySelector('form[action$=\"/unstar\"]')?.getAttribute('action')" --url <owner>/<name>
   ```
   Expected: ends with `/star` if currently unstarred, `/unstar` if already starred.

   - If already starred: STOP and report "already starred — no action needed."
   - If unstarred: continue to step 6.

6. **Click the Star button**
   ```bash
   safari-browser click @eN --url <owner>/<name>
   ```
   Expected: button label flips to `Starred` within ~1 second.

## Error handling

- **User is not logged in** (step 3 returned `true`): Report and STOP. Typing credentials from an agent is a safety violation.
- **Repo not found** (404 or "This repository doesn't exist"): Report exactly what GitHub showed; STOP.
- **Rate limited by GitHub** (visible banner): STOP and surface the cooldown period shown on the page.
- **Star button not in snapshot**: GitHub occasionally ships A/B UI variants. Fall back to `safari-browser click button[aria-label*="star this repository" i] --url <owner>/<name>`; if that also fails, ask the user.
- **Private repo without access**: GitHub 404s these as if they do not exist; same handling as "not found".

## Verification

Success criteria — ALL must hold:

1. Re-run step 5's JS query and confirm the form action now ends with `/unstar`.
2. Re-run `safari-browser snapshot -i --url <owner>/<name>` and confirm a ref labelled `Starred` or `Unstar` is present near where the Star ref used to be.
3. Optionally, the star count near the button has incremented by 1 (not required — UI caches sometimes lag a second).

If criterion 1 fails, the star click did NOT register — do NOT claim success.

## Gotchas

- **GitHub reactive title**: GitHub updates `document.title` on client-side navigation, so a `🟢` marker set by safari-browser may be reset. Harmless but surprising.
- **Keyboard shortcuts inside the page**: GitHub's "s" keyboard shortcut focuses search. Don't use `press_key` to send "s" as a shortcut for star — use an explicit click.
- **Star vs Watch vs Sponsor**: All three buttons are clustered. A loose selector like `button[aria-label*="star" i]` can match "Unstar" or even "star" inside sponsor copy. Prefer `form[action$="/star"]` when disambiguating.
- **Enterprise GitHub**: `github.<company>.com` has the same DOM but different URL. Adjust the `--url` substring in every command accordingly — this playbook targets `github.com` by default.
- **Authenticated session vs device-flow**: Safari-based session auth is what this playbook relies on. Device-flow (`gh auth`) does not affect the web session; the two are independent.
