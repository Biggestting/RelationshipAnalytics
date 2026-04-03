import SwiftUI

struct ContactListView: View {
    let contacts: [ContactProfile]
    @EnvironmentObject var appearanceManager: AppearanceManager
    @State private var showAppearancePicker = false
    @State private var showImport = false
    @State private var importedChats: [ImportResult] = []

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 2) {
                    // iMessage contacts
                    ForEach(contacts) { contact in
                        NavigationLink {
                            ContactDetailView(
                                contact: contact,
                                messageStats: MockDataProvider.messageStats,
                                callStats: MockDataProvider.callStats,
                                rankData: MockDataProvider.rankData
                            )
                        } label: {
                            ContactRow(contact: contact)
                        }
                    }

                    // Imported chats section
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
                                phoneNumber: nil,
                                email: nil
                            )
                            NavigationLink {
                                ContactDetailView(
                                    contact: profile,
                                    messageStats: stats,
                                    callStats: MockDataProvider.callStats,
                                    rankData: MockDataProvider.rankData
                                )
                            } label: {
                                ImportedContactRow(contact: profile, platform: imported.platform, messageCount: imported.totalMessages)
                            }
                        }
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
        .sheet(isPresented: $showImport, onDismiss: { loadImports() }) {
            ImportView()
        }
        .onAppear { loadImports() }
    }

    private var appearanceIcon: String {
        switch appearanceManager.mode {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }

    private func loadImports() {
        importedChats = ImportManager.shared.loadAllImports()
    }
}

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
                    .overlay(
                        Circle()
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                Text(contact.initials)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name.uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(contact.talkingSinceFormatted.uppercased())
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                )
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
                    .overlay(
                        Circle()
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

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
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
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
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        ContactListView(contacts: MockDataProvider.contacts)
            .environmentObject(AppearanceManager())
    }
}
