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

2. Generate the Xcode project:
   ```bash
   cd RelationshipAnalytics
   xcodegen generate
   ```

3. Open `RelationshipAnalytics.xcodeproj` in Xcode

4. Set your development team in signing settings

5. **macOS app**: Grant Full Disk Access in System Settings > Privacy & Security

6. **CloudKit**: Set up a CloudKit container `iCloud.com.relationshipanalytics` in your Apple Developer account

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
