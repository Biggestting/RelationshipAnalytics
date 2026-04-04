import SwiftUI

struct DataSourcesView: View {
    @StateObject private var callTracker = CallTracker.shared
    @StateObject private var messageTracker = MessageTracker.shared
    @StateObject private var syncManager = AutoSyncManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Auto-sync status
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("AUTO SYNC")
                                        .font(AppTheme.cardTitle)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    Button {
                                        syncManager.autoSyncEnabled.toggle()
                                    } label: {
                                        Text(syncManager.autoSyncEnabled ? "ON" : "OFF")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(syncManager.autoSyncEnabled ? AppTheme.textPrimary : AppTheme.textMuted)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(syncManager.autoSyncEnabled ? AppTheme.accentRed.opacity(0.2) : Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .strokeBorder(syncManager.autoSyncEnabled ? AppTheme.accentRed.opacity(0.4) : AppTheme.cardBorder, lineWidth: 1)
                                                    )
                                            )
                                    }
                                }

                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("LAST SYNC")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundStyle(AppTheme.textMuted)
                                        Text(syncManager.formattedSyncDate)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundStyle(syncManager.isStale ? AppTheme.accentRed : AppTheme.textPrimary)
                                    }

                                    if syncManager.isSyncing {
                                        ProgressView()
                                            .tint(AppTheme.textMuted)
                                    }

                                    Spacer()

                                    Button {
                                        if syncManager.shortcutInstalled {
                                            Task { await syncManager.performSync(source: "manual") }
                                        } else {
                                            // No shortcut installed — guide user
                                            syncManager.syncStatus = "SET UP SHORTCUT FIRST (SEE BELOW)"
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: syncManager.shortcutInstalled ? "arrow.triangle.2.circlepath" : "exclamationmark.triangle")
                                                .font(.system(size: 8))
                                            Text(syncManager.shortcutInstalled ? "SYNC NOW" : "SETUP NEEDED")
                                        }
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                            )
                                    }
                                    .disabled(syncManager.isSyncing)
                                }

                                if !syncManager.syncStatus.isEmpty {
                                    Text(syncManager.syncStatus)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(AppTheme.textMuted)
                                }

                                Text("SYNCS AUTOMATICALLY EVERY FEW HOURS VIA BACKGROUND REFRESH. ALSO SYNCS WHEN YOU OPEN THE APP IF DATA IS OLDER THAN 4 HOURS.")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .lineSpacing(2)
                            }
                        }

                        // Shortcuts automation guide
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.accentRed)
                                    Text("INSTANT SYNC (RECOMMENDED)")
                                        .font(AppTheme.cardTitle)
                                        .foregroundStyle(AppTheme.textPrimary)
                                }

                                Text("SET UP A SHORTCUTS AUTOMATION SO YOUR DATA SYNCS EVERY TIME YOU OPEN THE MESSAGES APP. ONE-TIME SETUP, FULLY AUTOMATIC AFTER.")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .lineSpacing(3)

                                Rectangle().fill(AppTheme.divider).frame(height: 1)

                                VStack(alignment: .leading, spacing: 6) {
                                    AutomationStep(number: 1, text: "OPEN SHORTCUTS APP → TAP + TO CREATE NEW SHORTCUT")
                                    AutomationStep(number: 2, text: "ADD ACTION: 'FIND MESSAGES' (NO FILTER — GETS ALL CONTACTS)")
                                    AutomationStep(number: 3, text: "ADD 'REPEAT WITH EACH' → INSIDE ADD 'TEXT' WITH:\n{\"sender\":\"[SENDER]\",\"text\":\"[TEXT]\",\"date\":\"[DATE SENT]\",\"is_from_me\":[IS FROM ME]}")
                                    AutomationStep(number: 4, text: "AFTER REPEAT: ADD 'COMBINE TEXT' (COMMA) → THEN 'TEXT': [ + COMBINED + ]")
                                    AutomationStep(number: 5, text: "ADD 'IMPORT MESSAGES' (FROM RELATIONSHIP ANALYTICS) → SET JSON TO THE TEXT")
                                    AutomationStep(number: 6, text: "NAME IT 'EXPORT MESSAGES TO RA' → DONE\nRUN IT ONCE TO IMPORT ALL CONTACTS AT ONCE")
                                }

                                Button {
                                    if let url = URL(string: "shortcuts://create-automation") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "bolt.badge.clock")
                                        Text("OPEN AUTOMATIONS")
                                    }
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                            .fill(AppTheme.accentRed.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                                    .strokeBorder(AppTheme.accentRed.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }

                        // Tracking status
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("LIVE TRACKING")
                                    .font(AppTheme.cardTitle)
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text("TRACKING SINCE \(formattedStartDate)")
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.textMuted)

                                Rectangle().fill(AppTheme.divider).frame(height: 1)

                                // Call tracking toggle
                                TrackingRow(
                                    icon: "phone.fill",
                                    title: "CALL TRACKING",
                                    description: "MONITORS INCOMING AND OUTGOING CALLS IN REAL TIME",
                                    isEnabled: callTracker.isTracking,
                                    onToggle: {
                                        if callTracker.isTracking {
                                            callTracker.stopTracking()
                                        } else {
                                            callTracker.startTracking()
                                        }
                                    }
                                )

                                Rectangle().fill(AppTheme.divider).frame(height: 1)

                                // Message notification tracking
                                TrackingRow(
                                    icon: "message.fill",
                                    title: "MESSAGE NOTIFICATIONS",
                                    description: "COUNTS INCOMING MESSAGES VIA NOTIFICATIONS (FOREGROUND ONLY)",
                                    isEnabled: messageTracker.isTracking,
                                    onToggle: {
                                        if messageTracker.isTracking {
                                            // Can't really stop UNUserNotificationCenter delegate
                                        } else {
                                            messageTracker.startTracking()
                                        }
                                    }
                                )
                            }
                        }

                        // Live stats
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("TRACKED DATA")
                                    .font(AppTheme.cardTitle)
                                    .foregroundStyle(AppTheme.textPrimary)

                                let calls = LiveDataStore.shared.getAllCalls()
                                let messages = LiveDataStore.shared.getAllMessageCounts()
                                let imports = LiveDataStore.shared.getAllShortcutsImports()

                                HStack(spacing: 0) {
                                    StatColumn(value: "\(calls.count)", label: "CALLS")
                                    Rectangle().fill(AppTheme.cardBorder).frame(width: 1, height: 36)
                                    StatColumn(value: "\(messages.count)", label: "CONTACTS")
                                    Rectangle().fill(AppTheme.cardBorder).frame(width: 1, height: 36)
                                    StatColumn(value: "\(imports.count)", label: "IMPORTS")
                                }
                            }
                        }

                        // Shortcuts integration
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "arrow.triangle.branch")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Text("SHORTCUTS INTEGRATION")
                                        .font(AppTheme.cardTitle)
                                        .foregroundStyle(AppTheme.textPrimary)
                                }

                                Text("EXPORT YOUR FULL IMESSAGE HISTORY WITH ONE TAP. OUR PRE-BUILT SHORTCUT READS YOUR MESSAGES AND SENDS THEM DIRECTLY TO THE APP.")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .lineSpacing(3)

                                Rectangle().fill(AppTheme.divider).frame(height: 1)

                                // One-tap install buttons
                                Button {
                                    ShortcutBuilder.openAppShortcutsGallery()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.app")
                                            .font(.system(size: 16))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("GET SHORTCUT")
                                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                            Text("OPENS SHORTCUTS APP WITH OUR PRE-BUILT ACTIONS")
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundStyle(AppTheme.textMuted)
                                        }
                                    }
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                            .fill(AppTheme.accentRed.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                                    .strokeBorder(AppTheme.accentRed.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }

                                Button {
                                    ShortcutBuilder.shareShortcut()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 14))
                                        Text("SHARE SHORTCUT FILE")
                                            .font(.system(size: 11, design: .monospaced))
                                    }
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                    )
                                }

                                // Available intents
                                Rectangle().fill(AppTheme.divider).frame(height: 1)

                                Text("AVAILABLE APP ACTIONS")
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.textMuted)

                                IntentRow(icon: "bubble.left.and.bubble.right", name: "IMPORT MESSAGES", description: "BULK IMPORT FULL CHAT HISTORY")
                                IntentRow(icon: "message", name: "LOG MESSAGE", description: "TRACK INDIVIDUAL SENT/RECEIVED")
                                IntentRow(icon: "phone", name: "LOG CALL", description: "RECORD A PHONE CALL EVENT")
                            }
                        }

                        // macOS companion
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "desktopcomputer")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Text("MACOS COMPANION")
                                        .font(AppTheme.cardTitle)
                                        .foregroundStyle(AppTheme.textPrimary)
                                }

                                Text("FOR THE MOST COMPLETE DATA, INSTALL THE MACOS COMPANION APP ON YOUR MAC. IT READS YOUR FULL IMESSAGE AND CALL HISTORY AND SYNCS IT TO THIS DEVICE VIA ICLOUD.")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .lineSpacing(3)

                                HStack(spacing: 0) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(Color.green)
                                        Text("ALL IMESSAGE\nHISTORY")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundStyle(AppTheme.textMuted)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)

                                    VStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(Color.green)
                                        Text("CALL\nLOGS")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundStyle(AppTheme.textMuted)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)

                                    VStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(Color.green)
                                        Text("EMOJI\nANALYSIS")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundStyle(AppTheme.textMuted)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)

                                    VStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(Color.green)
                                        Text("AUTO\nSYNC")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundStyle(AppTheme.textMuted)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }

                        // Data sources comparison
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DATA SOURCE COMPARISON")
                                    .font(AppTheme.cardTitle)
                                    .foregroundStyle(AppTheme.textPrimary)

                                DataSourceComparisonRow(source: "LIVE TRACKING", features: "CALLS + NOTIFICATIONS", coverage: "FROM INSTALL DATE")
                                DataSourceComparisonRow(source: "SHORTCUTS", features: "FULL IMESSAGE HISTORY", coverage: "ALL TIME")
                                DataSourceComparisonRow(source: "CHAT IMPORT", features: "WHATSAPP/IG/FB/X", coverage: "ALL TIME")
                                DataSourceComparisonRow(source: "MACOS COMPANION", features: "EVERYTHING", coverage: "ALL TIME + AUTO SYNC")
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("DATA SOURCES")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("DONE") { dismiss() }
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }

    private var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: LiveDataStore.shared.trackingStartDate).uppercased()
    }
}

struct TrackingRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isEnabled ? AppTheme.textPrimary : AppTheme.textMuted)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTheme.bodyText)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineSpacing(2)
            }

            Spacer()

            Button(action: onToggle) {
                Text(isEnabled ? "ON" : "OFF")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(isEnabled ? AppTheme.textPrimary : AppTheme.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isEnabled ? AppTheme.accentRed.opacity(0.2) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(isEnabled ? AppTheme.accentRed.opacity(0.4) : AppTheme.cardBorder, lineWidth: 1)
                            )
                    )
            }
        }
    }
}

struct AutomationStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.accentRed)
                .frame(width: 16, alignment: .trailing)
            Text(text)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(2)
        }
    }
}

struct IntentRow: View {
    let icon: String
    let name: String
    let description: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }
}

struct DataSourceComparisonRow: View {
    let source: String
    let features: String
    let coverage: String

    var body: some View {
        HStack {
            Text(source)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 100, alignment: .leading)

            Text(features)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text(coverage)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
        }
    }
}

#Preview {
    DataSourcesView()
}
