import SwiftUI

struct ContactListView: View {
    let contacts: [ContactProfile]
    var cloudKitBundles: [ContactAnalyticsBundle] = []
    @EnvironmentObject var appearanceManager: AppearanceManager
    @State private var showAppearancePicker = false
    @State private var showImport = false
    @State private var showDataSources = false
    @State private var importedChats: [ImportResult] = []
    @State private var shortcutsImports: [String: ShortcutsImportEntry] = [:]

    private var hasAnyData: Bool {
        !contacts.isEmpty || !importedChats.isEmpty || !shortcutsImports.isEmpty || !cloudKitBundles.isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 2) {
                    // CloudKit-synced contacts (from macOS companion)
                    if !cloudKitBundles.isEmpty {
                        Text("SYNCED FROM MAC")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)

                        ForEach(cloudKitBundles) { bundle in
                            NavigationLink {
                                ContactDetailView(
                                    contact: bundle.contact,
                                    messageStats: bundle.messageStats,
                                    callStats: bundle.callStats,
                                    rankData: bundle.rankData
                                )
                            } label: {
                                ContactRow(contact: bundle.contact)
                            }
                        }
                    }

                    // Shortcuts-imported iMessage contacts
                    if !shortcutsImports.isEmpty {
                        Text("IMESSAGE")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)

                        ForEach(Array(shortcutsImports.keys.sorted()), id: \.self) { key in
                            if let entry = shortcutsImports[key] {
                                let stats = buildStatsFromShortcuts(entry)
                                let profile = ContactProfile(
                                    id: "shortcuts_\(key)",
                                    name: entry.contactName,
                                    initials: String(entry.contactName.prefix(1)).uppercased(),
                                    talkingSince: entry.messages.first?.date ?? Date(),
                                    identifiers: []
                                )
                                NavigationLink {
                                    ContactDetailView(
                                        contact: profile,
                                        messageStats: stats,
                                        callStats: emptyCallStats(),
                                        rankData: emptyRankData()
                                    )
                                } label: {
                                    ContactRow(contact: profile)
                                }
                            }
                        }
                    }

                    // CloudKit-synced contacts (from macOS companion)
                    if !contacts.isEmpty {
                        if !shortcutsImports.isEmpty {
                            Text("SYNCED")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                                .padding(.bottom, 4)
                        }

                        ForEach(contacts) { contact in
                            NavigationLink {
                                // These would come from CloudKit in production
                                ContactDetailView(
                                    contact: contact,
                                    messageStats: emptyMessageStats(contactId: contact.id),
                                    callStats: emptyCallStats(),
                                    rankData: emptyRankData()
                                )
                            } label: {
                                ContactRow(contact: contact)
                            }
                        }
                    }

                    // File-imported chats (WhatsApp, Messenger, etc.)
                    if !importedChats.isEmpty {
                        Text("IMPORTED")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                            .padding(.bottom, 4)

                        ForEach(importedChats, id: \.sourceFileName) { imported in
                            let stats = ImportManager.shared.convertToMessageStats(from: imported)
                            let profile = ContactProfile(
                                id: "import_\(imported.contactName)",
                                name: imported.contactName,
                                initials: String(imported.contactName.prefix(1)).uppercased(),
                                talkingSince: imported.dateRange?.start ?? Date(),
                                identifiers: []
                            )
                            NavigationLink {
                                ContactDetailView(
                                    contact: profile,
                                    messageStats: stats,
                                    callStats: emptyCallStats(),
                                    rankData: emptyRankData()
                                )
                            } label: {
                                ImportedContactRow(contact: profile, platform: imported.platform, messageCount: imported.totalMessages)
                            }
                        }
                    }

                    // Empty state
                    if !hasAnyData {
                        VStack(spacing: 20) {
                            Spacer().frame(height: 60)

                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.textMuted)

                            Text("NO CONTACTS YET")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("IMPORT YOUR MESSAGE HISTORY TO SEE\nRELATIONSHIP ANALYTICS FOR EACH CONTACT")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)

                            VStack(spacing: 10) {
                                EmptyStateButton(
                                    icon: "arrow.triangle.branch",
                                    title: "IMPORT FROM IMESSAGE",
                                    subtitle: "VIA SHORTCUTS (RECOMMENDED)",
                                    isHighlighted: true
                                ) {
                                    showDataSources = true
                                }

                                EmptyStateButton(
                                    icon: "square.and.arrow.down",
                                    title: "IMPORT CHAT FILE",
                                    subtitle: "WHATSAPP, MESSENGER, INSTAGRAM, X",
                                    isHighlighted: false
                                ) {
                                    showImport = true
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("CONTACTS")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button { showDataSources = true } label: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Button { showImport = true } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Button { showAppearancePicker = true } label: {
                        Image(systemName: appearanceIcon)
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAppearancePicker) {
            AppearancePickerSheet(manager: appearanceManager, isPresented: $showAppearancePicker)
                .presentationDetents([.height(220)])
        }
        .sheet(isPresented: $showImport, onDismiss: { loadData() }) {
            ImportView()
        }
        .sheet(isPresented: $showDataSources, onDismiss: { loadData() }) {
            DataSourcesView()
        }
        .onAppear { loadData() }
    }

    private var appearanceIcon: String {
        switch appearanceManager.mode {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }

    private func loadData() {
        importedChats = ImportManager.shared.loadAllImports()
        shortcutsImports = LiveDataStore.shared.getAllShortcutsImports()
    }

    // MARK: - Build stats from Shortcuts imports

    private func buildStatsFromShortcuts(_ entry: ShortcutsImportEntry) -> MessageStats {
        let messages = entry.messages
        let sent = messages.filter { $0.isFromMe }.count
        let received = messages.filter { !$0.isFromMe }.count

        let activity = buildDailyActivity(from: messages)
        let streak = calculateStreak(from: activity)

        return MessageStats(
            contactId: "shortcuts_\(entry.contactName)",
            totalSent: sent,
            totalReceived: received,
            totalMessages: messages.count,
            messageActivity: activity,
            activeStreak: streak.current,
            bestStreak: streak.best,
            youStartPercentage: calculateYouStart(from: messages),
            yourReplyTime: 0,
            theirReplyTime: 0,
            longestConvo: nil,
            firstMessageSent: messages.first.map { MessagePreview(text: $0.text, date: $0.date, isFromUser: $0.isFromMe) },
            firstMessageReceived: nil,
            messagesEdited: 0,
            messagesUnsent: 0,
            voiceMessages: nil,
            emojiStats: extractEmojis(from: messages)
        )
    }

    private func buildDailyActivity(from messages: [ShortcutsMessage]) -> [DayActivity] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for msg in messages {
            let day = calendar.startOfDay(for: msg.date)
            counts[day, default: 0] += 1
        }
        return counts.map { DayActivity(date: $0.key, count: $0.value) }.sorted { $0.date < $1.date }
    }

    private func calculateStreak(from activity: [DayActivity]) -> (current: Int, best: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let active = Set(activity.filter { $0.count > 0 }.map { calendar.startOfDay(for: $0.date) })
        var current = 0
        var check = today
        while active.contains(check) {
            current += 1
            check = calendar.date(byAdding: .day, value: -1, to: check)!
        }
        var best = 0, run = 0
        for day in activity.sorted(by: { $0.date < $1.date }) {
            if day.count > 0 { run += 1; best = max(best, run) } else { run = 0 }
        }
        return (current, best)
    }

    private func calculateYouStart(from messages: [ShortcutsMessage]) -> Double {
        guard !messages.isEmpty else { return 0 }
        let gap: TimeInterval = 4 * 3600
        var youStart = 0, total = 0
        var lastDate: Date?
        for msg in messages.sorted(by: { $0.date < $1.date }) {
            if lastDate == nil || msg.date.timeIntervalSince(lastDate!) > gap {
                total += 1
                if msg.isFromMe { youStart += 1 }
            }
            lastDate = msg.date
        }
        return total > 0 ? Double(youStart) / Double(total) * 100 : 0
    }

    private func extractEmojis(from messages: [ShortcutsMessage]) -> EmojiStats? {
        var counts: [String: (you: Int, them: Int)] = [:]
        for msg in messages {
            for scalar in msg.text.unicodeScalars where scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
                let e = String(scalar)
                var c = counts[e] ?? (0, 0)
                if msg.isFromMe { c.you += 1 } else { c.them += 1 }
                counts[e] = c
            }
        }
        guard !counts.isEmpty else { return nil }
        let sorted = counts.map { EmojiCount(emoji: $0.key, count: $0.value.you + $0.value.them, fromYou: $0.value.you, fromThem: $0.value.them) }.sorted { $0.count > $1.count }
        return EmojiStats(
            topEmojis: Array(sorted.prefix(10)),
            yourTopEmojis: Array(sorted.sorted { $0.fromYou > $1.fromYou }.prefix(3).map { EmojiCount(emoji: $0.emoji, count: $0.fromYou, fromYou: $0.fromYou, fromThem: 0) }),
            theirTopEmojis: Array(sorted.sorted { $0.fromThem > $1.fromThem }.prefix(3).map { EmojiCount(emoji: $0.emoji, count: $0.fromThem, fromYou: 0, fromThem: $0.fromThem) }),
            totalEmojisSent: counts.values.reduce(0) { $0 + $1.you },
            totalEmojisReceived: counts.values.reduce(0) { $0 + $1.them },
            uniqueEmojiCount: counts.count
        )
    }

    // MARK: - Empty data factories

    private func emptyMessageStats(contactId: String) -> MessageStats {
        MessageStats(contactId: contactId, totalSent: 0, totalReceived: 0, totalMessages: 0, messageActivity: [], activeStreak: 0, bestStreak: 0, youStartPercentage: 0, yourReplyTime: 0, theirReplyTime: 0, longestConvo: nil, firstMessageSent: nil, firstMessageReceived: nil, messagesEdited: 0, messagesUnsent: 0, voiceMessages: nil, emojiStats: nil)
    }

    private func emptyCallStats() -> CallStats {
        CallStats(contactId: "", totalCallTime: 0, totalCalls: 0, answeredCalls: 0, averageCallDuration: 0, lastAnsweredDate: nil, monthlyCallData: [], callRecords: [], hourlyCallPattern: [], missedStats: MissedCallStats(youMissed: 0, theyMissed: 0, totalMissed: 0, totalAnswered: 0, yourAnswerRate: 100, theirAnswerRate: 100, longestUnansweredStreak: 0), faceTimeStats: FaceTimeStats(videoCallCount: 0, audioCallCount: 0, regularCallCount: 0, videoTotalDuration: 0, audioFTDuration: 0, regularDuration: 0, lastFaceTimeDate: nil))
    }

    private func emptyRankData() -> RankData {
        RankData(contactId: "", currentRank: 0, bestRank: 0, currentRankDate: Date(), bestRankDate: Date(), rankHistory: [])
    }
}

// MARK: - Empty State Button

struct EmptyStateButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isHighlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isHighlighted ? AppTheme.accentRed : AppTheme.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .strokeBorder(isHighlighted ? AppTheme.accentRed.opacity(0.3) : AppTheme.cardBorder, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Reusable Components

struct AppearancePickerSheet: View {
    @ObservedObject var manager: AppearanceManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("APPEARANCE")
                .font(AppTheme.cardTitle)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.top, 20)

            HStack(spacing: 12) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Button {
                        manager.mode = mode
                        isPresented = false
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: iconFor(mode))
                                .font(.system(size: 24))
                                .foregroundStyle(manager.mode == mode ? AppTheme.accentRed : AppTheme.textSecondary)
                            Text(mode.rawValue)
                                .font(AppTheme.caption)
                                .foregroundStyle(manager.mode == mode ? AppTheme.textPrimary : AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                .fill(AppTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                        .strokeBorder(
                                            manager.mode == mode ? AppTheme.accentRed.opacity(0.5) : AppTheme.cardBorder,
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func iconFor(_ mode: AppearanceMode) -> String {
        switch mode {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}

struct ContactRow: View {
    let contact: ContactProfile

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                Text(contact.initials)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name.uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 6) {
                    Text(contact.talkingSinceFormatted.uppercased())
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                    if contact.identifiers.count > 1 {
                        Text("\(contact.identifiers.count) NUMBERS")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 2).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
        )
    }
}

struct ImportedContactRow: View {
    let contact: ContactProfile
    let platform: ChatPlatform
    let messageCount: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                Image(systemName: platform.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(contact.name.uppercased())
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(platform.rawValue)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 3).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                }
                Text("\(messageCount) MESSAGES")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
        )
    }
}

#Preview {
    NavigationStack {
        ContactListView(contacts: [], cloudKitBundles: [])
            .environmentObject(AppearanceManager())
    }
}
