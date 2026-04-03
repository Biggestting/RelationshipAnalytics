import SwiftUI

struct DataSourcesView: View {
    @StateObject private var callTracker = CallTracker.shared
    @StateObject private var messageTracker = MessageTracker.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
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

                                Text("USE AN IOS SHORTCUT TO EXPORT YOUR IMESSAGE HISTORY DIRECTLY FROM THE MESSAGES APP. THIS IS THE MOST COMPLETE WAY TO GET YOUR DATA WITHOUT A MAC.")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .lineSpacing(3)

                                Rectangle().fill(AppTheme.divider).frame(height: 1)

                                Text(ShortcutsIntegration.shortcutInstructions)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineSpacing(2)

                                Button {
                                    if let url = ShortcutsIntegration.shared.shortcutInstallURL {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("OPEN SHORTCUTS APP")
                                    }
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                            .strokeBorder(AppTheme.textSecondary, lineWidth: 1)
                                    )
                                }
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
