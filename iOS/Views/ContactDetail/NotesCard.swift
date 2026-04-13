import SwiftUI

struct NotesCard: View {
    let notes: [ContactNote]
    let contactId: String

    @State private var showEditor = false
    @State private var noteText: String = ""

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text("NOTES")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Button {
                        noteText = loadNote()
                        showEditor = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(hasNote() ? "EDIT" : "ADD A NOTE")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }

                // Show saved note preview
                if hasNote() {
                    Text(loadNote())
                        .font(AppTheme.bodyText)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NoteEditorSheet(
                contactId: contactId,
                noteText: $noteText,
                isPresented: $showEditor
            )
        }
    }

    private func hasNote() -> Bool {
        let saved = UserDefaults.standard.string(forKey: "note_\(contactId)") ?? ""
        return !saved.isEmpty
    }

    private func loadNote() -> String {
        UserDefaults.standard.string(forKey: "note_\(contactId)") ?? ""
    }
}

struct NoteEditorSheet: View {
    let contactId: String
    @Binding var noteText: String
    @Binding var isPresented: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    TextEditor(text: $noteText)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                .fill(AppTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                )
                        )
                        .focused($isFocused)

                    Text("ADD PERSONAL NOTES ABOUT THIS CONTACT")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .padding(16)
            }
            .navigationTitle("NOTES")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("CANCEL") {
                        isPresented = false
                    }
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("SAVE") {
                        UserDefaults.standard.set(noteText, forKey: "note_\(contactId)")
                        isPresented = false
                    }
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

