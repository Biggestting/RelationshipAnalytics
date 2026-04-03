import SwiftUI

struct ContactDetailView: View {
    let contact: ContactProfile
    let messageStats: MessageStats
    let callStats: CallStats
    let rankData: RankData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.sectionSpacing) {
                    HeaderView(contact: contact)

                    NotesCard(notes: [])

                    SentReceivedCard(stats: messageStats)

                    EditedUnsentCard(stats: messageStats)

                    MessageActivityHeatmap(stats: messageStats)

                    // Side-by-side cards
                    HStack(spacing: AppTheme.sectionSpacing) {
                        ActiveStreakCard(
                            streak: messageStats.activeStreak,
                            bestStreak: messageStats.bestStreak
                        )

                        YouStartCard(percentage: messageStats.youStartPercentage)
                    }

                    ReplyTimeCard(stats: messageStats, contactName: contact.name)

                    VoiceMessagesCard(stats: messageStats.voiceMessages)

                    CallTimeCard(callStats: callStats)

                    RankOverTimeCard(rankData: rankData)

                    LongestConvoCard(convo: messageStats.longestConvo)

                    FirstMessagesCard(firstMessage: messageStats.firstMessageSent)

                    // Bottom spacer for safe area
                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        // Search action
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }

                    Button {
                        // More options
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(
            contact: MockDataProvider.contact,
            messageStats: MockDataProvider.messageStats,
            callStats: MockDataProvider.callStats,
            rankData: MockDataProvider.rankData
        )
    }
    .preferredColorScheme(.dark)
}
