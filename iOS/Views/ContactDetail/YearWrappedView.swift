import SwiftUI

struct YearWrappedView: View {
    let stats: MessageStats
    let callStats: CallStats
    let contactName: String

    @State private var currentPage = 0

    private var cards: [WrappedCard] {
        buildCards()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Swipeable cards
            TabView(selection: $currentPage) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    WrappedCardView(card: card)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<cards.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? AppTheme.textPrimary : AppTheme.textMuted.opacity(0.4))
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.top, 10)

            // Swipe hint
            Text("SWIPE TO EXPLORE")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.top, 6)
        }
    }

    private func buildCards() -> [WrappedCard] {
        var result: [WrappedCard] = []

        // Card 1: Total messages
        result.append(WrappedCard(
            topLabel: "THIS YEAR WITH \(contactName.uppercased())",
            bigStat: "\(stats.totalMessages)",
            statLabel: "MESSAGES EXCHANGED",
            detail: "\(stats.totalSent) SENT · \(stats.totalReceived) RECEIVED",
            accentStat: false
        ))

        // Card 2: Who texts first
        let initiator = stats.youStartPercentage > 50 ? "YOU" : contactName.uppercased()
        result.append(WrappedCard(
            topLabel: "WHO STARTS THE CONVERSATION?",
            bigStat: "\(Int(stats.youStartPercentage))%",
            statLabel: "OF THE TIME, YOU TEXT FIRST",
            detail: initiator == "YOU"
                ? "YOU'RE THE INITIATOR IN THIS RELATIONSHIP"
                : "\(contactName.uppercased()) USUALLY REACHES OUT FIRST",
            accentStat: false
        ))

        // Card 3: Reply speed
        let youFaster = stats.yourReplyTime < stats.theirReplyTime
        result.append(WrappedCard(
            topLabel: "RESPONSE TIME",
            bigStat: stats.theirReplyTimeFormatted,
            statLabel: "\(contactName.uppercased()) REPLIES IN",
            detail: youFaster
                ? "YOU'RE FASTER AT \(stats.yourReplyTimeFormatted) AVG"
                : "YOU TAKE \(stats.yourReplyTimeFormatted) ON AVERAGE",
            accentStat: false
        ))

        // Card 4: Streak
        if stats.bestStreak > 0 {
            result.append(WrappedCard(
                topLabel: "LONGEST STREAK",
                bigStat: "\(stats.bestStreak)",
                statLabel: "CONSECUTIVE DAYS TALKING",
                detail: stats.activeStreak > 0
                    ? "CURRENTLY ON A \(stats.activeStreak)-DAY STREAK"
                    : "YOUR CURRENT STREAK IS \(stats.activeStreak) DAYS",
                accentStat: true
            ))
        }

        // Card 5: Longest conversation
        if let convo = stats.longestConvo {
            result.append(WrappedCard(
                topLabel: "YOUR LONGEST CONVERSATION",
                bigStat: convo.durationFormatted,
                statLabel: "STRAIGHT",
                detail: "\(convo.messageCount) MESSAGES ON \(convo.dateRangeFormatted.uppercased())",
                accentStat: false
            ))
        }

        // Card 6: Call time
        if callStats.totalCalls > 0 {
            result.append(WrappedCard(
                topLabel: "ON THE PHONE",
                bigStat: callStats.totalCallTimeFormatted,
                statLabel: "TOTAL CALL TIME",
                detail: "\(callStats.answeredCalls) CALLS · \(callStats.averageCallFormatted) AVERAGE",
                accentStat: false
            ))
        }

        // Card 7: Top emojis
        if let emoji = stats.emojiStats, !emoji.topEmojis.isEmpty {
            let top3 = emoji.topEmojis.prefix(3).map { $0.emoji }.joined(separator: "  ")
            result.append(WrappedCard(
                topLabel: "YOUR TOP EMOJIS TOGETHER",
                bigStat: top3,
                statLabel: "\(emoji.totalEmojis) EMOJIS SENT",
                detail: "\(emoji.uniqueEmojiCount) UNIQUE EMOJIS · YOU SENT \(emoji.totalEmojisSent) · THEY SENT \(emoji.totalEmojisReceived)",
                accentStat: false
            ))
        }

        // Card 8: Edited & unsent
        if stats.messagesEdited > 0 || stats.messagesUnsent > 0 {
            result.append(WrappedCard(
                topLabel: "SECOND THOUGHTS",
                bigStat: "\(stats.messagesEdited + stats.messagesUnsent)",
                statLabel: "MESSAGES EDITED OR UNSENT",
                detail: "\(stats.messagesEdited) EDITED · \(stats.messagesUnsent) UNSENT",
                accentStat: true
            ))
        }

        // Card 8: Summary
        let balance = abs(stats.sentPercentage - 50)
        let balanceLabel: String
        if balance < 5 { balanceLabel = "PERFECTLY BALANCED" }
        else if balance < 15 { balanceLabel = "FAIRLY BALANCED" }
        else { balanceLabel = stats.sentPercentage > 50 ? "YOU DO MOST OF THE TALKING" : "\(contactName.uppercased()) DOES MOST OF THE TALKING" }

        result.append(WrappedCard(
            topLabel: "YOUR RELATIONSHIP IN A WORD",
            bigStat: balanceLabel.count > 20 ? "ACTIVE" : balanceLabel,
            statLabel: "",
            detail: "\(stats.totalMessages) MESSAGES · \(callStats.totalCalls) CALLS · \(stats.bestStreak)-DAY BEST STREAK",
            accentStat: false
        ))

        return result
    }
}

struct WrappedCard: Identifiable {
    let id = UUID()
    let topLabel: String
    let bigStat: String
    let statLabel: String
    let detail: String
    let accentStat: Bool
}

struct WrappedCardView: View {
    let card: WrappedCard

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Top label
            Text(card.topLabel)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer().frame(height: 24)

            // Big stat
            Text(card.bigStat)
                .font(.system(size: card.bigStat.count > 10 ? 28 : 52, weight: .bold, design: .monospaced))
                .foregroundStyle(card.accentStat ? AppTheme.accentRed : AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 16)

            if !card.statLabel.isEmpty {
                Spacer().frame(height: 8)

                Text(card.statLabel)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 24)

            // Detail line
            Text(card.detail)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineSpacing(3)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
    }
}

#Preview {
    YearWrappedView(
        stats: MockDataProvider.messageStats,
        callStats: MockDataProvider.callStats,
        contactName: "Nina"
    )
    .padding()
    .background(Color.black)
}
