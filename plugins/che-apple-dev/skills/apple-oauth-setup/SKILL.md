---
name: apple-oauth-setup
description: |
  Set up Apple Sign In for Web on Apple Developer Portal via Safari + AppleScript.
  Use when user says "Apple Sign In", "Apple OAuth", "設定 Apple 登入",
  "建立 Services ID", "generate .p8 key", "Apple client secret",
  "developer.apple.com 設定", or needs to configure Apple OAuth for Supabase/web apps.
  Also handles JWT client secret generation from .p8 keys.
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
---

# Apple OAuth Setup

Automate Apple Sign In for Web configuration via Safari + AppleScript.
Covers the full chain: App ID → Services ID → Key (.p8) → JWT client secret.

## Prerequisites

- Apple Developer Program (paid, $99/year) — Personal Team won't work
- Safari logged into developer.apple.com (user handles 2FA manually)
- Python 3 with `PyJWT` for JWT generation (`pip install pyjwt`)

## Overview

Apple Sign In for Web requires four things registered on Apple Developer Portal:

1. **App ID** — with Sign In with Apple capability enabled
2. **Services ID** — the `client_id` for web OAuth
3. **Key** (.p8 file) — used to generate JWT client secrets
4. **JWT client secret** — what your OAuth backend (Supabase, etc.) actually uses

## Step 1: Open Apple Developer Portal

```applescript
tell application "Safari" to activate
tell application "Safari" to open location "https://developer.apple.com/account"
```

Wait for user to complete login + 2FA, then verify:

```applescript
tell application "Safari" to do JavaScript "document.title" in front document
```

Should contain "Account - Apple Developer" or similar.

## Step 2: Get Team Info

```bash
# From Xcode provisioning
defaults read com.apple.dt.Xcode IDEProvisioningTeams 2>/dev/null
# Or from signing identity
security find-identity -v -p codesigning 2>/dev/null
```

Note the **Team ID** (10-character alphanumeric like `6W377FS7BS`).

## Step 3: Create App ID

Navigate to register App ID:

```applescript
tell application "Safari" to set URL of front document to "https://developer.apple.com/account/resources/identifiers/add/bundleId"
```

Select "App IDs" → "App" type → Continue. Then fill the form:

```javascript
// Fill Description and Bundle ID using native setter (framework-safe)
(function() {
  var setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set;

  var desc = document.getElementById("description");
  setter.call(desc, "YOUR_APP_NAME");
  desc.dispatchEvent(new InputEvent("input", {bubbles: true, inputType: "insertText"}));
  desc.dispatchEvent(new Event("change", {bubbles: true}));

  var ident = document.getElementById("identifier");
  setter.call(ident, "com.yourdomain.appname");
  ident.dispatchEvent(new InputEvent("input", {bubbles: true, inputType: "insertText"}));
  ident.dispatchEvent(new Event("change", {bubbles: true}));
})();
```

Enable **Sign In with Apple** in the capabilities list:

```javascript
(function() {
  var checkboxes = document.querySelectorAll("input[type=checkbox]");
  for (var i = 0; i < checkboxes.length; i++) {
    var row = checkboxes[i].closest("tr, li, div");
    if (row && row.textContent.includes("Sign In with Apple")) {
      checkboxes[i].click();
      return "enabled";
    }
  }
  return "not found";
})();
```

Click Continue → Register.

## Step 4: Create Services ID

Navigate:

```applescript
tell application "Safari" to set URL of front document to "https://developer.apple.com/account/resources/identifiers/add/serviceId"
```

On the type selection page, select "Services IDs" (radio index 1 in `ul.form-radio-list`):

```javascript
(function() {
  var lis = document.querySelectorAll("ul.form-radio-list > li");
  var radio = lis[1].querySelector("input[type=radio]"); // Services IDs
  radio.click();
})();
```

Click Continue, then fill:
- **Description**: e.g. "My App Sign In with Apple"
- **Identifier**: e.g. "com.yourdomain.auth" (this becomes the OAuth `client_id`)

Register, then click into the new Services ID to edit. Enable Sign In with Apple checkbox, click Configure.

### Configure Web Authentication

The Configure dialog uses a React Select dropdown for Primary App ID:

```javascript
// Open the dropdown
(function() {
  var input = document.getElementById("react-select-2-input");
  input.focus();
  input.dispatchEvent(new KeyboardEvent("keydown", {bubbles: true, key: "ArrowDown", keyCode: 40}));
})();
```

Then select the first option:

```javascript
(function() {
  var option = document.getElementById("react-select-2-option-0");
  if (option) { option.click(); return option.textContent.trim(); }
  return "no option";
})();
```

Fill domain and return URL (the native setter + InputEvent pattern is required because the form uses a JS framework):

```javascript
(function() {
  var setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set;

  var domain = document.getElementById("domainsInput");
  setter.call(domain, "YOUR_SUPABASE_REF.supabase.co");
  domain.dispatchEvent(new InputEvent("input", {bubbles: true, inputType: "insertText"}));
  domain.dispatchEvent(new Event("change", {bubbles: true}));

  var urls = document.getElementById("urlsInput");
  setter.call(urls, "https://YOUR_SUPABASE_REF.supabase.co/auth/v1/callback");
  urls.dispatchEvent(new InputEvent("input", {bubbles: true, inputType: "insertText"}));
  urls.dispatchEvent(new Event("change", {bubbles: true}));
})();
```

Click Next → Done → Continue → Save.

## Step 5: Create Key (.p8)

Navigate:

```applescript
tell application "Safari" to set URL of front document to "https://developer.apple.com/account/resources/authkeys/add"
```

Fill key name, enable Sign In with Apple, Configure (select App ID via React Select as above), then Continue → Register.

### Download the Key

The download page appears once. Click Download — Safari will show a permission dialog "要允許在 developer.apple.com 上下載嗎？". Handle it with AppleScript:

```applescript
tell application "System Events"
  tell process "Safari"
    set allElems to entire contents of window 1
    repeat with elem in allElems
      try
        if class of elem is button and name of elem is "允許" then
          click elem
          exit repeat
        end if
      end try
    end repeat
  end tell
end tell
```

**Important**: Standard `sheet` or `group` traversal won't find this button — `entire contents` is required.

Verify download:

```bash
ls -lt ~/Downloads/AuthKey_*.p8 | head -1
```

Backup the key:

```bash
mkdir -p ~/.appstoreconnect/private_keys/
cp ~/Downloads/AuthKey_KEYID.p8 ~/.appstoreconnect/private_keys/
```

### If Download Missed

If the download page shows "Downloaded" but the file isn't there, click Done, go to Keys list, click the key name to view details — the Download button is still available from the detail page.

## Step 6: Generate JWT Client Secret

Apple OAuth backends (Supabase, Firebase, etc.) need a JWT client secret generated from the .p8 key. This JWT expires every 6 months — set a reminder to regenerate.

```python
python3 -c "
import jwt, time

with open('PATH_TO_P8_FILE', 'r') as f:
    private_key = f.read()

headers = {'kid': 'KEY_ID', 'alg': 'ES256'}
payload = {
    'iss': 'TEAM_ID',
    'iat': int(time.time()),
    'exp': int(time.time()) + 86400 * 180,  # 6 months
    'aud': 'https://appleid.apple.com',
    'sub': 'SERVICES_ID'  # e.g. com.yourdomain.auth
}
print(jwt.encode(payload, private_key, algorithm='ES256', headers=headers))
"
```

Replace:
- `PATH_TO_P8_FILE` — path to the downloaded .p8 key
- `KEY_ID` — from the Keys page (10-character ID)
- `TEAM_ID` — your Apple Developer Team ID
- `SERVICES_ID` — the Services ID identifier (e.g. `com.yourdomain.auth`)

## Step 7: Configure OAuth Backend

### Supabase

Navigate to Supabase Dashboard → Authentication → Providers → Apple. Use Safari AppleScript to fill the fields:

The provider accordion rows have class `cursor-pointer`:

```javascript
// Click Apple row to expand
(function() {
  var rows = document.querySelectorAll("div.cursor-pointer");
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].textContent.includes("Apple")) {
      rows[i].click();
      return "expanded";
    }
  }
})();
```

Enable the toggle and fill credentials:

```javascript
(function() {
  // Enable toggle
  var toggle = document.getElementById("EXTERNAL_APPLE_ENABLED");
  if (toggle) toggle.click();

  var setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set;

  // Client ID = Services ID
  var clientId = document.getElementById("EXTERNAL_APPLE_CLIENT_ID");
  setter.call(clientId, "SERVICES_ID");
  clientId.dispatchEvent(new InputEvent("input", {bubbles: true, inputType: "insertText"}));
  clientId.dispatchEvent(new Event("change", {bubbles: true}));

  // Secret = JWT from Step 6
  var secret = document.getElementById("EXTERNAL_APPLE_SECRET");
  setter.call(secret, "JWT_CLIENT_SECRET");
  secret.dispatchEvent(new InputEvent("input", {bubbles: true, inputType: "insertText"}));
  secret.dispatchEvent(new Event("change", {bubbles: true}));
})();
```

Click Save. Verify the toast says "Successfully updated settings" and Apple shows "Enabled".

## Common Issues

| Problem | Solution |
|---------|----------|
| "No App ID is available" in Services ID config | Create an App ID with Sign In with Apple enabled first (Step 3) |
| Safari download dialog blocks .p8 download | Use `entire contents` AppleScript pattern (Step 5) |
| `Unsupported provider: provider is not enabled` | Apple provider not enabled in Supabase Dashboard |
| JWT generation fails with `No module named 'jwt'` | `pip install pyjwt` (not `pip install jwt`) |
| Personal Team shown in Xcode | Need paid Apple Developer Program ($99/year) |
| React Select dropdown won't open | Focus input first, dispatch ArrowDown KeyboardEvent |
| Form values don't persist after setting | Use `Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set` + InputEvent, not direct `.value =` |

## Credential Summary Template

After setup, save this info for future reference:

```
Team ID:        ___________
App ID:         com.________
Services ID:    com.________  (this is the OAuth client_id)
Key ID:         ___________
Key backup:     ~/.appstoreconnect/private_keys/AuthKey_KEYID.p8
JWT expires:    YYYY-MM-DD (6 months from generation)
```
