import SwiftUI

struct MacContentView: View {
    @EnvironmentObject var syncManager: SyncManager

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.primaryPink)

                    Text("Relationship Analytics")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Sync your iMessage data to your iPhone")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 40)

                // Status
                if syncManager.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppTheme.primaryPink)

                        Text(syncManager.syncProgress)
                            .font(AppTheme.bodyText)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding()
                } else if let error = syncManager.error {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.yellow)

                        Text(error)
                            .font(AppTheme.bodyText)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        if error.contains("Full Disk Access") {
                            Button("Open System Settings") {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.primaryPink)
                        }
                    }
                    .padding()
                } else if !syncManager.contacts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.successGreen)

                        Text("\(syncManager.contacts.count) contacts synced")
                            .font(AppTheme.bodyText)
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("Last sync: \(syncManager.lastSyncFormatted)")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                // Sync button
                Button {
                    Task { await syncManager.syncAll() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(syncManager.isLoading ? "Syncing..." : "Sync Now")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.primaryPink)
                    )
                }
                .buttonStyle(.plain)
                .disabled(syncManager.isLoading)

                // Permissions info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Required Permissions")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)

                    PermissionRow(
                        icon: "lock.shield.fill",
                        title: "Full Disk Access",
                        description: "To read iMessage history"
                    )

                    PermissionRow(
                        icon: "phone.fill",
                        title: "Call History",
                        description: "To read phone call logs"
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.primaryPink)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.bodyText)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }
}

#Preview {
    MacContentView()
        .environmentObject(SyncManager())
        .frame(width: 500, height: 600)
}
