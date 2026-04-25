# Release Guide

Everything you need to build and publish Moinsen Punch Cards to all platforms.

## Quick Release

```bash
# Bump version in pubspec.yaml first, then:
git tag v0.3.0
git push origin v0.3.0
```

This triggers the [release.yml](/.github/workflows/release.yml) workflow which builds and deploys all three platforms in parallel:

| Platform | Destination | Condition |
|----------|-------------|-----------|
| Web | GitHub Pages | Always runs |
| Android | Google Play (internal track) | Requires `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret |
| iOS | TestFlight / App Store Connect | Requires `APP_STORE_CONNECT_PRIVATE_KEY` secret |

You can also trigger it manually via GitHub Actions → "Release" → "Run workflow".

---

## GitHub Secrets Setup

All secrets are configured in **Settings → Secrets and variables → Actions**.

### Android Secrets

| Secret | Description | How to get it |
|--------|-------------|---------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded upload keystore | `base64 -i upload-keystore.jks \| pbcopy` |
| `ANDROID_STORE_PASSWORD` | Keystore password | From keystore creation |
| `ANDROID_KEY_PASSWORD` | Key alias password | From keystore creation |
| `ANDROID_KEY_ALIAS` | Key alias name | Usually `upload` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Service account JSON key | Google Play Console → Setup → API access |

### iOS Secrets

| Secret | Description | How to get it |
|--------|-------------|---------------|
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID | App Store Connect → Users & Access → Integrations → App Store Connect API |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID | Same page as above |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Full .p8 file contents | Downloaded when creating the API key |

---

## One-Time Setup

### 1. Android Keystore

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload -storetype JKS
```

Then upload the base64-encoded keystore as `ANDROID_KEYSTORE_BASE64`:

```bash
base64 -i upload-keystore.jks | pbcopy
```

### 2. Google Play Service Account

1. Go to [Google Play Console](https://play.google.com/console) → your app → Setup → API access
2. Link or create a Google Cloud project
3. Create a service account with "Release Manager" role
4. Download the JSON key file
5. Paste the full JSON content as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

### 3. App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → Users & Access → Integrations → App Store Connect API
2. Click "+" to create a key with "Admin" access
3. Note the **Issuer ID** and **Key ID**
4. Download the `.p8` file
5. Set `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_ID`, and `APP_STORE_CONNECT_PRIVATE_KEY` (full file contents)

### 4. ExportOptions.plist

Edit `ios/Runner/ExportOptions.plist` and replace `YOUR_TEAM_ID` with your Apple Developer Team ID (found at [developer.apple.com](https://developer.apple.com/account)).

---

## Local Builds (without CI)

### Web
```bash
flutter build web --base-href "/moinsen_punch_cards/"
# Output: build/web/
```

### Android
```bash
# Create android/key.properties with your signing info first
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ipa --release --export-options-plist=ios/Runner/ExportOptions.plist
# Output: build/ios/ipa/*.ipa
```

---

## Version Management

Version is defined in `pubspec.yaml`:

```yaml
version: 0.3.0+1
#           ^   ^
#           |   build number (must increment for each upload)
#           semantic version (used as versionName / CFBundleShortVersionString)
```

Increment the build number (`+1`, `+2`, ...) for every store upload, even if the semantic version hasn't changed.

---

## Architecture

```
.github/workflows/
├── flutter-gh-pages.yml   # Web-only deploy (runs on every push to main)
└── release.yml             # Full release (runs on v* tags)

android/fastlane/
├── Appfile                 # Package name
└── Fastfile                # build + deploy lanes

ios/fastlane/
├── Appfile                 # Bundle ID
└── Fastfile                # build + deploy lanes

ios/Runner/
└── ExportOptions.plist     # IPA export configuration
```
