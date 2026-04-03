import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlatform: ChatPlatform?
    @State private var userName: String = ""
    @State private var showFilePicker = false
    @State private var importResult: ImportResult?
    @State private var error: String?
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 32))
                                .foregroundStyle(AppTheme.textSecondary)

                            Text("IMPORT CHAT HISTORY")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("IMPORT EXPORTED CHAT FILES FROM OTHER PLATFORMS")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Platform selector
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SELECT PLATFORM")
                                .font(AppTheme.cardTitle)
                                .foregroundStyle(AppTheme.textPrimary)

                            ForEach(importablePlatforms, id: \.rawValue) { platform in
                                PlatformRow(
                                    platform: platform,
                                    isSelected: selectedPlatform == platform,
                                    onTap: { selectedPlatform = platform }
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // Your name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR NAME IN CHAT")
                                .font(AppTheme.cardTitle)
                                .foregroundStyle(AppTheme.textPrimary)

                            TextField("", text: $userName, prompt: Text("YOUR DISPLAY NAME").foregroundStyle(AppTheme.textMuted))
                                .font(AppTheme.bodyText)
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                        .fill(AppTheme.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                        )
                                )

                            Text("ENTER YOUR NAME AS IT APPEARS IN THE EXPORT")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .padding(.horizontal, 16)

                        // Import button
                        Button {
                            showFilePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text(isImporting ? "IMPORTING..." : "SELECT FILE")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                    .fill(AppTheme.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                            .strokeBorder(selectedPlatform != nil && !userName.isEmpty
                                                          ? AppTheme.textSecondary : AppTheme.cardBorder, lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(selectedPlatform == nil || userName.isEmpty || isImporting)
                        .padding(.horizontal, 16)

                        // Error
                        if let error {
                            Text(error)
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.accentRed)
                                .padding(.horizontal, 16)
                        }

                        // Success result
                        if let result = importResult {
                            ImportSuccessCard(result: result)
                                .padding(.horizontal, 16)
                        }

                        // Instructions
                        ExportInstructionsView(platform: selectedPlatform)
                            .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("DONE") { dismiss() }
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: allowedTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private var importablePlatforms: [ChatPlatform] {
        [.whatsapp, .messenger, .instagram, .twitter]
    }

    private var allowedTypes: [UTType] {
        [.plainText, .json, .data, UTType(filenameExtension: "js") ?? .data]
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first, let platform = selectedPlatform else { return }
            isImporting = true
            error = nil

            guard url.startAccessingSecurityScopedResource() else {
                error = "Cannot access this file."
                isImporting = false
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let imported = try ImportManager.shared.importFile(
                    data: data,
                    fileName: url.lastPathComponent,
                    platform: platform,
                    userName: userName
                )
                importResult = imported
            } catch {
                self.error = error.localizedDescription
            }
            isImporting = false

        case .failure(let err):
            error = err.localizedDescription
        }
    }
}

struct PlatformRow: View {
    let platform: ChatPlatform
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? AppTheme.accentRed : AppTheme.textSecondary)
                    .frame(width: 24)

                Text(platform.rawValue)
                    .font(AppTheme.bodyText)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text(fileTypeLabel(platform))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(AppTheme.textMuted)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.accentRed)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .strokeBorder(isSelected ? AppTheme.accentRed.opacity(0.4) : AppTheme.cardBorder, lineWidth: 1)
                    )
            )
        }
    }

    private func fileTypeLabel(_ platform: ChatPlatform) -> String {
        switch platform {
        case .whatsapp: return ".TXT"
        case .messenger: return ".JSON"
        case .instagram: return ".JSON"
        case .twitter: return ".JS"
        case .imessage: return ""
        }
    }
}

struct ImportSuccessCard: View {
    let result: ImportResult

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("IMPORT SUCCESSFUL")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                }

                HStack {
                    StatPill(label: "MESSAGES", value: "\(result.totalMessages)")
                    StatPill(label: "SENT", value: "\(result.sentCount)")
                    StatPill(label: "RECEIVED", value: "\(result.receivedCount)")
                }

                Text("CONTACT: \(result.contactName.uppercased())")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}

struct ExportInstructionsView: View {
    let platform: ChatPlatform?

    var body: some View {
        if let platform {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HOW TO EXPORT FROM \(platform.rawValue)")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(Array(instructions(for: platform).enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                                .frame(width: 16, alignment: .trailing)
                            Text(step)
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func instructions(for platform: ChatPlatform) -> [String] {
        switch platform {
        case .whatsapp:
            return [
                "OPEN THE CHAT YOU WANT TO EXPORT",
                "TAP THE CONTACT NAME AT THE TOP",
                "SCROLL DOWN AND TAP 'EXPORT CHAT'",
                "CHOOSE 'WITHOUT MEDIA'",
                "SAVE THE .TXT FILE AND IMPORT IT HERE",
            ]
        case .messenger:
            return [
                "GO TO FACEBOOK.COM/DYI (DOWNLOAD YOUR INFORMATION)",
                "SELECT 'MESSAGES' ONLY",
                "CHOOSE FORMAT: JSON, DATE RANGE: ALL TIME",
                "DOWNLOAD AND UNZIP THE ARCHIVE",
                "FIND THE message_1.json IN YOUR CONTACT'S FOLDER",
            ]
        case .instagram:
            return [
                "GO TO INSTAGRAM SETTINGS > YOUR ACTIVITY",
                "TAP 'DOWNLOAD YOUR INFORMATION'",
                "SELECT 'MESSAGES' ONLY, FORMAT: JSON",
                "DOWNLOAD AND UNZIP THE ARCHIVE",
                "FIND THE message_1.json IN YOUR CONTACT'S FOLDER",
            ]
        case .twitter:
            return [
                "GO TO SETTINGS > YOUR ACCOUNT > DOWNLOAD AN ARCHIVE",
                "REQUEST AND DOWNLOAD YOUR DATA ARCHIVE",
                "UNZIP AND FIND data/direct-messages.js",
                "IMPORT THAT .JS FILE HERE",
            ]
        case .imessage:
            return []
        }
    }
}

#Preview {
    ImportView()
}
