# Relationship Analytics

A native iOS + macOS app that analyzes your iMessage and phone call data to provide beautiful relationship insights for each contact.

## Features

### iOS App (Display)
- **Sent vs Received** — message balance with visual progress bar
- **Message Activity Heatmap** — GitHub-style contribution grid
- **Active Streak** — consecutive days of messaging
- **Conversation Initiator** — who starts conversations more
- **Reply Time** — average response time comparison
- **Call Time** — monthly call duration chart
- **Rank Over Time** — contact ranking history
- **Longest Conversation** — your longest chat session
- **First Messages** — how your conversation started
- **Notes** — personal notes for each contact

### macOS App (Data Sync)
- Reads iMessage database (`chat.db`) via SQLite
- Reads call history from CallHistory database
- Syncs analytics to iOS via CloudKit
- Menu bar quick-sync option

## Architecture

```
RelationshipAnalytics/
├── Shared/           # Models, theme, CloudKit sync (shared between iOS & macOS)
├── iOS/              # SwiftUI views, iOS app target
├── macOS/            # Data reader services, macOS app target
└── project.yml       # XcodeGen project configuration
```

## Requirements

- **iOS 17.0+** (iPhone)
- **macOS 14.0+** (for data reader)
- Xcode 16+
- Swift 5.9+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Setup

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Set your Apple Developer Team ID in `project.yml` under
   `settings.base.DEVELOPMENT_TEAM`.

3. Generate the Xcode project:
   ```bash
   cd RelationshipAnalytics
   xcodegen generate
   ```

4. Open `RelationshipAnalytics.xcodeproj` in Xcode.

5. Add app icons:
   - iOS: drop a 1024×1024 PNG into `iOS/Resources/Assets.xcassets/AppIcon.appiconset/`.
   - macOS: populate `macOS/Resources/Assets.xcassets/AppIcon.appiconset/` with the
     full Mac icon size set (16/32/128/256/512 @ 1x and 2x).

6. **macOS app**: Grant Full Disk Access in System Settings > Privacy & Security.

7. **CloudKit**: In the Apple Developer portal, create the container
   `iCloud.com.relationshipanalytics` and enable it on both App IDs. On the
   iOS App ID also enable **Background Modes** (Background fetch, Background
   processing).

## Distribution

This project ships on two different tracks — they are not symmetric.

### iOS — TestFlight / App Store

Supported. The iOS target is configured with:

- `iOS/RelationshipAnalytics.entitlements` (iCloud + CloudKit for
  `iCloud.com.relationshipanalytics`)
- `UIBackgroundModes: fetch, processing` so the declared
  `BGTaskScheduler` identifier registers at runtime
- `CODE_SIGN_STYLE: Automatic`

To ship: Xcode → Product → Archive → Distribute App → App Store Connect →
upload → TestFlight.

### macOS — Developer ID + notarization (NOT TestFlight)

The macOS app reads `~/Library/Messages/chat.db`, which requires
**Full Disk Access** granted by the user. That is fundamentally incompatible
with **App Sandbox**, which the Mac App Store and macOS TestFlight both
require. Submissions will be rejected.

The macOS target is instead configured for Developer ID distribution:

- App Sandbox intentionally disabled
- Hardened Runtime enabled (required for notarization)
- CloudKit entitlements present

To ship: Xcode → Product → Archive → Distribute App → **Developer ID** →
Upload for notarization → staple → distribute the `.app` directly (website,
DMG, etc.).

## How It Works

1. **macOS app** reads your local iMessage database and call history
2. Processes analytics (message counts, reply times, streaks, rankings, etc.)
3. Syncs processed data to CloudKit (Apple's cloud database)
4. **iOS app** fetches the synced data and displays beautiful analytics

## Privacy

- All data stays in your personal iCloud account
- No data is sent to any third-party servers
- The macOS app only reads data — it never modifies your messages or call history
- Full Disk Access is required solely to read the iMessage database
- The iOS app is a display client — it never reads local message data on
  the phone (iOS does not expose `chat.db` to third-party apps)

## Tech Stack

- **SwiftUI** — declarative UI framework
- **Swift Charts** — native charting
- **SQLite3** — direct database reading
- **CloudKit** — Apple's cloud sync
- **XcodeGen** — project file generation

## Screenshots

*Coming soon*

## License

MIT
