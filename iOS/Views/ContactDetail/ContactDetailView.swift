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

                    VisualInsightsCard(
                        stats: messageStats,
                        callStats: callStats,
                        contactName: contact.name
                    )

                    NotesCard(notes: [], contactId: contact.id)

                    SentReceivedCard(stats: messageStats)

                    EditedUnsentCard(stats: messageStats)

                    MessageActivityHeatmap(stats: messageStats, contactName: contact.name)

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

                    MissedCallsCard(stats: callStats.missedStats, contactName: contact.name)

                    FaceTimeCard(stats: callStats.faceTimeStats)

                    CallPatternsCard(hourlyData: callStats.hourlyCallPattern)

                    CallLogCard(records: callStats.callRecords)

                    RankOverTimeCard(rankData: rankData)

                    PhotosTogetherCard(contactName: contact.name)

                    LongestConvoCard(convo: messageStats.longestConvo)

                    FirstMessagesCard(firstMessage: messageStats.firstMessageSent)

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Button {
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textPrimary)
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
