import SwiftUI

struct NotesCard: View {
    let notes: [ContactNote]
    var onAddNote: (() -> Void)?

    var body: some View {
        GlassCard {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)

                Text("NOTES")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                if notes.isEmpty {
                    Text("ADD A NOTE")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .onTapGesture {
            onAddNote?()
        }
    }
}

#Preview {
    NotesCard(notes: [])
        .padding()
        .background(Color.black)
}
