import SwiftUI

struct MacContentView: View {
    @EnvironmentObject var syncManager: SyncManager
    @State private var searchText = ""

    private var filteredContacts: [ContactProfile] {
        if searchText.isEmpty { return syncManager.contacts }
        return syncManager.contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.accentRed)

                        Text("RELATIONSHIP ANALYTICS")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(.top, 20)

                    // Step 1: Load contacts
                    if syncManager.contacts.isEmpty && !syncManager.isFetchingContacts {
                        Button {
                            Task { await syncManager.fetchContactList() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("LOAD CONTACTS")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppTheme.accentRed.opacity(0.15))
                                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AppTheme.accentRed.opacity(0.4), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)

                        Text("READS YOUR IMESSAGE DATABASE TO FIND ALL CONTACTS")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    if syncManager.isFetchingContacts {
                        ProgressView()
                            .controlSize(.small)
                            .tint(AppTheme.accentRed)
                        Text(syncManager.syncProgress)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    // Step 2: Contact picker
                    if !syncManager.contacts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            // Search + select controls
                            HStack {
                                // Search
                                HStack(spacing: 6) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppTheme.textMuted)
                                    TextField("SEARCH", text: $searchText)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .textFieldStyle(.plain)
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.cardBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                                )

                                Spacer()

                                Button("ALL") { syncManager.selectAll() }
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppTheme.textSecondary)

                                Button("NONE") { syncManager.deselectAll() }
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppTheme.textSecondary)

                                Button("TOP 20") {
                                    syncManager.deselectAll()
                                    let top = syncManager.contacts.prefix(20).map { $0.id }
                                    syncManager.selectedContactIds = Set(top)
                                }
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(AppTheme.textSecondary)
                            }

                            // Selection count
                            HStack {
                                Text("\(syncManager.selectedCount) SELECTED OF \(syncManager.contacts.count)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Spacer()

                                if syncManager.selectedCount > 50 {
                                    Text("LARGE SELECTION — MAY TAKE A FEW MINUTES")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(AppTheme.accentRed)
                                }
                            }

                            // Contact list (scrollable, max height)
                            ScrollView {
                                LazyVStack(spacing: 1) {
                                    ForEach(filteredContacts) { contact in
                                        ContactPickerRow(
                                            contact: contact,
                                            isSelected: syncManager.selectedContactIds.contains(contact.id),
                                            hasSynced: syncManager.contactStats[contact.id] != nil,
                                            messageCount: syncManager.contactStats[contact.id]?.messageStats.totalMessages
                                        ) {
                                            syncManager.toggleContact(contact.id)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 300)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppTheme.cardBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                            )

                            // Sync button
                            Button {
                                Task { await syncManager.syncSelected() }
                            } label: {
                                HStack(spacing: 8) {
                                    if syncManager.isLoading {
                                        ProgressView()
                                            .controlSize(.small)
                                            .tint(AppTheme.textPrimary)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text(syncManager.isLoading ? "SYNCING \(syncManager.processedCount)/\(syncManager.totalCount)..." : "SYNC \(syncManager.selectedCount) CONTACTS")
                                }
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(syncManager.selectedCount > 0 ? AppTheme.textPrimary : AppTheme.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(syncManager.selectedCount > 0 ? AppTheme.accentRed.opacity(0.15) : AppTheme.cardBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(syncManager.selectedCount > 0 ? AppTheme.accentRed.opacity(0.4) : AppTheme.cardBorder, lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(syncManager.isLoading || syncManager.selectedCount == 0)

                            // Progress
                            if syncManager.isLoading, syncManager.totalCount > 0 {
                                ProgressView(value: Double(syncManager.processedCount), total: Double(syncManager.totalCount))
                                    .tint(AppTheme.accentRed)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                        )
                    }

                    // Synced results
                    if !syncManager.contactStats.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(syncManager.contactStats.count) CONTACTS SYNCED")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()

                                Button {
                                    exportToFile()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 10))
                                        Text("EXPORT")
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    }
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            // Synced contact summaries
                            ForEach(Array(syncManager.contactStats.values.sorted { $0.messageStats.totalMessages > $1.messageStats.totalMessages }.prefix(20)), id: \.contact.id) { bundle in
                                HStack(spacing: 8) {
                                    Text(bundle.contact.initials)
                                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .frame(width: 20, height: 20)
                                        .background(Circle().strokeBorder(AppTheme.cardBorder, lineWidth: 1))

                                    Text(bundle.contact.name.uppercased())
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text("\(bundle.messageStats.totalMessages)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Text("MSGS")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(AppTheme.textMuted)

                                    if bundle.messageStats.emojiStats != nil {
                                        Text(bundle.messageStats.emojiStats!.top3String)
                                            .font(.system(size: 10))
                                    }

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.green.opacity(0.6))
                                }
                                .padding(.vertical, 3)
                            }

                            if syncManager.contactStats.count > 20 {
                                Text("+ \(syncManager.contactStats.count - 20) MORE")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .frame(maxWidth: .infinity)
                            }

                            Text("VIEW FULL ANALYTICS ON YOUR IPHONE. EXPORT FILE TO TRANSFER WITHOUT ICLOUD.")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                                .lineSpacing(2)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                        )
                    }

                    // Status
                    if !syncManager.syncProgress.isEmpty && !syncManager.isFetchingContacts {
                        Text(syncManager.syncProgress)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(syncManager.syncProgress.contains("Done") ? Color.green : AppTheme.textSecondary)
                    }

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

                        if error.contains("Full Disk Access") || error.contains("not found") {
                            Button("OPEN PRIVACY SETTINGS") {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                            }
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accentRed)
                        }
                    }

                    if syncManager.lastSync != nil {
                        Text("LAST SYNC: \(syncManager.lastSyncFormatted)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    // Permissions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SETUP")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                        PermissionRow(icon: "lock.shield.fill", title: "Full Disk Access", description: "System Settings → Privacy → Full Disk Access → Enable this app")
                        PermissionRow(icon: "phone.fill", title: "Call History", description: "Included with Full Disk Access")
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

    private func exportToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "RelationshipAnalytics_Export.json"
        panel.title = "Export Synced Data"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let exportData = syncManager.contactStats.values.map { bundle in
                ExportBundle(
                    contact: bundle.contact,
                    messageStats: bundle.messageStats,
                    callStats: bundle.callStats,
                    rankData: bundle.rankData
                )
            }

            if let data = try? encoder.encode(exportData) {
                try? data.write(to: url)
                syncManager.syncProgress = "Exported to \(url.lastPathComponent)"
            }
        }
    }
}

/// Codable wrapper for export
private struct ExportBundle: Codable {
    let contact: ContactProfile
    let messageStats: MessageStats
    let callStats: CallStats
    let rankData: RankData
}

struct ContactPickerRow: View {
    let contact: ContactProfile
    let isSelected: Bool
    let hasSynced: Bool
    let messageCount: Int?
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? AppTheme.accentRed : AppTheme.textMuted)

                Text(contact.initials)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 22, height: 22)
                    .background(Circle().strokeBorder(AppTheme.cardBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 1) {
                    Text(contact.name.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)

                    if let phone = contact.phoneNumber {
                        Text(phone)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                Spacer()

                if let count = messageCount {
                    Text("\(count) MSGS")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                }

                if hasSynced {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.green.opacity(0.6))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? AppTheme.accentRed.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
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
