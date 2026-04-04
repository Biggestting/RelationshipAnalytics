import SwiftUI

struct MacContentView: View {
    @EnvironmentObject var syncManager: SyncManager

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.accentRed)

                        Text("RELATIONSHIP ANALYTICS")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("READS YOUR IMESSAGE & CALL DATA, SYNCS TO IPHONE VIA ICLOUD")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)

                    // Sync button
                    Button {
                        Task { await syncManager.syncAll() }
                    } label: {
                        HStack(spacing: 8) {
                            if syncManager.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(AppTheme.textPrimary)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(syncManager.isLoading ? "SYNCING..." : "SYNC NOW")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: 250)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.accentRed.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(AppTheme.accentRed.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(syncManager.isLoading)

                    // Progress
                    if syncManager.isLoading {
                        VStack(spacing: 8) {
                            if syncManager.totalCount > 0 {
                                ProgressView(value: Double(syncManager.processedCount), total: Double(syncManager.totalCount))
                                    .tint(AppTheme.accentRed)
                                    .frame(maxWidth: 300)
                            }

                            Text(syncManager.syncProgress)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    // Status
                    if !syncManager.isLoading {
                        VStack(spacing: 6) {
                            if let error = syncManager.error {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.yellow)
                                    Text(error)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.yellow.opacity(0.05))
                                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1))
                                )

                                if syncManager.error?.contains("Full Disk Access") == true || syncManager.error?.contains("not found") == true {
                                    Button("OPEN PRIVACY SETTINGS") {
                                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                                    }
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .buttonStyle(.borderedProminent)
                                    .tint(AppTheme.accentRed)
                                }
                            } else if !syncManager.syncProgress.isEmpty {
                                Text(syncManager.syncProgress)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(syncManager.syncProgress.contains("complete") ? Color.green : AppTheme.textSecondary)
                            }

                            if let lastSync = syncManager.lastSync {
                                Text("LAST SYNC: \(syncManager.lastSyncFormatted)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                    }

                    // Contact list
                    if !syncManager.contacts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(syncManager.contacts.count) CONTACTS")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text("SORTED BY RECENT")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                            }

                            ForEach(Array(syncManager.contacts.prefix(30).enumerated()), id: \.element.id) { index, contact in
                                HStack(spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(AppTheme.textMuted)
                                        .frame(width: 20, alignment: .trailing)

                                    Text(contact.initials)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().strokeBorder(AppTheme.cardBorder, lineWidth: 1))

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(contact.name.uppercased())
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundStyle(AppTheme.textPrimary)

                                        if let phone = contact.phoneNumber {
                                            Text(phone)
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundStyle(AppTheme.textMuted)
                                        }
                                    }

                                    Spacer()

                                    // Show stats if available
                                    if let bundle = syncManager.contactStats[contact.id] {
                                        Text("\(bundle.messageStats.totalMessages) MSGS")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundStyle(AppTheme.textMuted)
                                    }

                                    Image(systemName: "checkmark.icloud")
                                        .font(.system(size: 10))
                                        .foregroundStyle(syncManager.lastSync != nil ? Color.green.opacity(0.6) : AppTheme.textMuted)
                                }
                                .padding(.vertical, 4)
                            }

                            if syncManager.contacts.count > 30 {
                                Text("+ \(syncManager.contacts.count - 30) MORE")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                        )
                    }

                    // Permissions card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REQUIRED PERMISSIONS")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)

                        PermissionRow(icon: "lock.shield.fill", title: "Full Disk Access", description: "System Settings → Privacy → Full Disk Access → Enable this app")
                        PermissionRow(icon: "phone.fill", title: "Call History", description: "Included with Full Disk Access")
                        PermissionRow(icon: "icloud.fill", title: "iCloud", description: "Sign in to iCloud to sync with iPhone")
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                    )

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.accentRed)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description.uppercased())
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }
}

#Preview {
    MacContentView()
        .environmentObject(SyncManager())
        .frame(width: 500, height: 700)
}
