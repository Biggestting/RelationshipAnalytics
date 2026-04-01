import SwiftUI

struct NotesCard: View {
    let notes: [ContactNote]
    var onAddNote: (() -> Void)?

    var body: some View {
        GlassCard {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textSecondary)

                Text("Notes")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                if notes.isEmpty {
                    Text("Add a note")
                        .font(AppTheme.cardSubtitle)
                        .foregroundStyle(AppTheme.textMuted)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
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
        .background(AppTheme.background)
}
