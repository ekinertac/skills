---
name: macos-notarize
description: Signs, notarizes, and staples a macOS .app for distribution. Covers Developer ID codesigning, notarytool submission, stapling, packaging for GitHub Releases, and diagnosing common Apple notarization errors. Trigger phrases: "notarize", "sign the app", "release macos app", "codesign", "notarization".
allowed-tools: [Bash, Read, Edit]
---

# macOS App Signing & Notarization

Handles Developer ID signing, notarization via `notarytool`, stapling, and CI/CD setup for macOS app distribution outside the App Store.

## Prerequisites

- Xcode command-line tools (`xcode-select --install`)
- Developer ID Application certificate in Keychain
- Apple Developer Program membership (paid)
- An app-specific password from appleid.apple.com (NOT your Apple ID password)

## Key concepts

**Signing** — `codesign` embeds your identity into the `.app`. Requires hardened runtime (`--options runtime`) for notarization to accept it.

**Notarization** — Apple scans the binary for malware. Submit via `notarytool`, wait for approval, then staple.

**Stapling** — `xcrun stapler staple` attaches the notarization ticket to the `.app` so it passes Gatekeeper offline.

**Bundle structure** — `codesign` requires all content inside `Contents/`. Files at the `.app` root (outside `Contents/`) cause `unsealed contents present in the bundle root`.

---

## 1 — Find your signing identity

```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
# → "Developer ID Application: Your Name (TEAMID)"
```

The string in quotes is your `SIGNING_IDENTITY`. The 10-char code in parentheses is your `TEAM_ID`.

## 2 — Sign the app

```bash
codesign --force --deep --sign "Developer ID Application: Your Name (TEAMID)" \
  --entitlements path/to/App.entitlements \
  --options runtime \
  App.app
```

**Entitlements**: at minimum you need `com.apple.security.app-sandbox = false` if the app spawns processes (terminals, shells). Add `com.apple.security.cs.allow-jit` and `allow-unsigned-executable-memory` if needed.

Verify signing:
```bash
codesign --verify --deep --strict App.app && echo "OK"
spctl --assess --type execute App.app  # simulates Gatekeeper
```

## 3 — Notarize

```bash
# Zip first — notarytool accepts .zip, .dmg, or .pkg
ditto -c -k --sequesterRsrc --keepParent App.app App.zip

xcrun notarytool submit App.zip \
  --apple-id  "you@example.com" \
  --password  "xxxx-xxxx-xxxx-xxxx" \
  --team-id   "TEAMID" \
  --wait
```

Test credentials without submitting:
```bash
xcrun notarytool history \
  --apple-id "you@example.com" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  --team-id  "TEAMID"
```

If notarization is rejected, fetch the full log:
```bash
xcrun notarytool log <submission-id> \
  --apple-id "you@example.com" --password "xxxx-xxxx-xxxx-xxxx" --team-id "TEAMID"
```

## 4 — Staple

```bash
xcrun stapler staple App.app
# Then re-zip for distribution
ditto -c -k --sequesterRsrc --keepParent App.app App-final.zip
```

---

## GitHub Actions CI setup

### Secrets required

| Secret | How to get |
|--------|------------|
| `DEVELOPER_ID_CERT_P12` | Export from Keychain → base64 encode |
| `DEVELOPER_ID_CERT_PASSWORD` | Password set on export |
| `DEVELOPER_ID_IDENTITY` | Full string from `security find-identity` |
| `NOTARY_APPLE_ID` | Apple ID email |
| `NOTARY_APP_PASSWORD` | App-specific password from appleid.apple.com |
| `NOTARY_TEAM_ID` | 10-char team ID |

### Export certificate and set secrets via CLI

```bash
# Generate a random password for the .p12
CERT_PASS=$(openssl rand -hex 16)

# Export all Developer ID identities
security export \
  -k ~/Library/Keychains/login.keychain-db \
  -t identities -f pkcs12 \
  -P "$CERT_PASS" \
  -o /tmp/cert.p12

# Set secrets (run from inside the repo)
gh secret set DEVELOPER_ID_CERT_P12      --body "$(base64 -i /tmp/cert.p12)"
gh secret set DEVELOPER_ID_CERT_PASSWORD --body "$CERT_PASS"
gh secret set DEVELOPER_ID_IDENTITY      --body "$(security find-identity -v -p codesigning | grep 'Developer ID Application' | sed 's/.*\"\(.*\)\"/\1/')"
gh secret set NOTARY_TEAM_ID             --body "$(security find-identity -v -p codesigning | grep -o '([A-Z0-9]*))' | tr -d '()')"

rm /tmp/cert.p12
```

### Workflow snippet (import cert + sign + notarize)

```yaml
- name: Import Developer ID certificate
  env:
    CERT_P12:  ${{ secrets.DEVELOPER_ID_CERT_P12 }}
    CERT_PASS: ${{ secrets.DEVELOPER_ID_CERT_PASSWORD }}
  run: |
    KEYCHAIN=$RUNNER_TEMP/signing.keychain-db
    KC_PASS=$(openssl rand -hex 16)
    security create-keychain -p "$KC_PASS" "$KEYCHAIN"
    security set-keychain-settings -lut 21600 "$KEYCHAIN"
    security unlock-keychain -p "$KC_PASS" "$KEYCHAIN"
    echo "$CERT_P12" | base64 -d > "$RUNNER_TEMP/cert.p12"
    security import "$RUNNER_TEMP/cert.p12" -P "$CERT_PASS" \
      -A -t cert -f pkcs12 -k "$KEYCHAIN"
    security set-key-partition-list -S apple-tool:,apple: \
      -s -k "$KC_PASS" "$KEYCHAIN"
    security list-keychain -d user -s "$KEYCHAIN"

- name: Sign
  env:
    SIGNING_IDENTITY: ${{ secrets.DEVELOPER_ID_IDENTITY }}
  run: |
    codesign --force --deep --sign "$SIGNING_IDENTITY" \
      --entitlements App.entitlements --options runtime App.app

- name: Notarize
  env:
    APPLE_ID: ${{ secrets.NOTARY_APPLE_ID }}
    APP_PASS: ${{ secrets.NOTARY_APP_PASSWORD }}
    TEAM_ID:  ${{ secrets.NOTARY_TEAM_ID }}
  run: |
    ditto -c -k --sequesterRsrc --keepParent App.app App.zip
    xcrun notarytool submit App.zip \
      --apple-id "$APPLE_ID" --password "$APP_PASS" --team-id "$TEAM_ID" --wait
    xcrun stapler staple App.app

- name: Clean up keychain
  if: always()
  run: security delete-keychain "$RUNNER_TEMP/signing.keychain-db" || true
```

---

## Common errors

**`unsealed contents present in the bundle root`**
Files exist outside `Contents/` inside the `.app`. Move everything into `Contents/MacOS/`, `Contents/Resources/`, or `Contents/Frameworks/`.

**`HTTP 403 — required agreement`**
Accept the Apple Developer Program License Agreement at both developer.apple.com and appstoreconnect.apple.com. Can take a few minutes to propagate after accepting.

**`Unable to decode the provided data`**
The `DEVELOPER_ID_CERT_P12` secret is empty or not valid base64. Re-export and re-set the secret.

**`The signature of the binary is invalid`**
Binary was modified after signing. Ensure nothing touches the `.app` between `codesign` and `notarytool submit`.

**Notarization approved but Gatekeeper still blocks**
Stapling was skipped or failed. Run `xcrun stapler staple App.app` and re-distribute.
