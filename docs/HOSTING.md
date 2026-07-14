# Hosting & Distribution
## App: Streak (iOS Habit Tracker)
**Version:** 1.0  
**Date:** 2026-07-08  
**Status:** Draft

---

## 1. Distribution Strategy

**Method: AltStore / Sideloading via IPA**

The app is not distributed via the App Store. It is distributed as a signed `.ipa` file. Each user installs it on their own iPhone using their own Apple ID and AltStore.

This approach is:
- Completely free (no $99/year Apple Developer membership required for basic use)
- Open source (source on GitHub, anyone can build and sign their own copy)
- Private (no App Store review, no data collection)

---

## 2. How AltStore Works

AltStore is a third-party app store for iOS that exploits Apple's free developer certificate signing (the same mechanism used by Xcode's "Run on device" feature).

**Key facts:**
- Apple allows any Apple ID to sign apps for personal use
- Free Apple ID certificates expire every **7 days**
- AltStore re-signs apps automatically when the phone and Mac/PC are on the same Wi-Fi, or via AltServer running on a computer
- AltJIT (via AltStore) and AltServer handle certificate refresh
- No jailbreak required

**What each friend needs:**
1. A Mac or Windows PC with **AltServer** installed
2. An Apple ID (free — no payment required)
3. AltStore installed on their iPhone (via AltServer)
4. The `.ipa` file from the GitHub releases page

---

## 3. Build & Release Process

### 3.1 Building the IPA

```
# In Xcode:
Product → Archive → Distribute App → Ad Hoc or Development
```

Or via command line (CI/CD optional):

```bash
xcodebuild archive \
  -scheme Streak \
  -archivePath build/Streak.xcarchive

xcodebuild -exportArchive \
  -archivePath build/Streak.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist
```

`ExportOptions.plist` specifies `method: development` for sideload distribution.

### 3.2 GitHub Releases

- Source code lives in a public GitHub repository
- Each stable build gets a GitHub Release tag (e.g., `v1.0.0`)
- The `.ipa` file is attached as a release artifact
- Friends download the `.ipa` directly from GitHub Releases

**Repository structure:**
```
streak-ios/
├── docs/               ← this documentation suite
├── Streak/             ← Xcode project source
├── CHANGELOG.md
├── README.md           ← Install instructions for AltStore
└── .github/
    └── releases/       ← IPA artifacts
```

### 3.3 README Install Instructions (for friends)

The README will include step-by-step:
1. Install AltServer on your computer
2. Install AltStore on your iPhone via AltServer
3. Download `Streak.ipa` from the latest GitHub release
4. Open AltStore on iPhone → My Apps → + → choose the IPA
5. Trust the developer certificate in iPhone Settings
6. Keep AltServer running on Wi-Fi periodically (or manually re-sign every 7 days)

---

## 4. Signing Tiers

| Tier | Cost | Certificate lifetime | Required? |
|------|------|----------------------|-----------|
| Free Apple ID | $0 | 7 days | Each user uses their own |
| Apple Developer Program | $99/year | 1 year | Not required for personal use |

**Recommendation:** Free tier is sufficient. Friends re-sign via AltStore automatically when on same Wi-Fi as their computer running AltServer. This is a one-time setup, then automatic.

**If a friend wants to avoid the 7-day re-sign:** They can pay $99/year for a personal Apple Developer account and sign with their own cert for a full year. This is their individual choice.

---

## 5. App Entitlements

The app requires specific entitlements declared in the `.entitlements` file. These entitlements must be compatible with the free developer certificate.

| Entitlement | Required | Free cert compatible? | Notes |
|-------------|----------|----------------------|-------|
| App Groups | Yes | ✓ | For widget data sharing |
| Push Notifications | No | ✓ (local only) | Local notifications, no APNs |
| iCloud (CloudKit) | Optional | ✓ | For optional iCloud sync |
| HealthKit | No (future) | ✓ | Future module |
| Siri / App Intents | Yes | ✓ | For Shortcuts integration |
| Background App Refresh | Yes | ✓ | For midnight sweep task |

**Note on iCloud with free cert:** iCloud/CloudKit works with free developer accounts on personal devices. The CloudKit container is tied to the Apple ID used for signing, so each user's iCloud sync is independent.

---

## 6. App Group Configuration

The App Group identifier must be set before building:

**Format:** `group.com.[appleIDusername].streak`

Each user will have a different App Group ID based on their Apple ID. The App Group is used to share data between the main app and widget extensions.

This means:
- Each user's build has a different App Group ID
- This is normal for personal sideloaded apps
- The build script or Xcode project should have a clear placeholder to swap this value

---

## 7. No Backend Infrastructure

There is no server, no database, no API, no cloud service operated by the developer.

| Concern | Resolution |
|---------|-----------|
| Data storage | On-device SwiftData |
| Sync | Optional iCloud (Apple's infrastructure, user's account) |
| Notifications | Local (UNNotificationCenter, no push server) |
| Updates | GitHub Releases (manual download and re-install) |
| Analytics | None |
| Crash reporting | None (use Xcode Organizer for personal debugging) |
| Cost to run | $0 ongoing |

---

## 8. Update Process

When a new version is released:

1. Developer pushes new tag to GitHub, attaches new `.ipa` to release
2. Friends see update on GitHub (or are notified via group chat)
3. Friend downloads new `.ipa`, installs via AltStore (overwrites old install)
4. Data is preserved (SwiftData store is not touched by reinstall, as long as bundle ID stays the same)

**Data migration on update:**
- If schema changes between versions, `SwiftData`'s built-in migration handles it
- Complex migrations have a migration plan document in `docs/MIGRATIONS.md` (to be created per version)

---

## 9. Open Source License

Recommended: **MIT License**

- Anyone can fork and self-host
- No warranty or support obligation
- Friends can modify their own copy
- Consistent with the "personal tool" nature of the project
