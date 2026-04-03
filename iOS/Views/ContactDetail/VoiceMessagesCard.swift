import SwiftUI

struct VoiceMessagesCard: View {
    let stats: VoiceMessageStats?

    var body: some View {
        if let stats {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)

                        Text("VOICE MESSAGES")
                            .font(AppTheme.cardTitle)
                            .foregroundStyle(AppTheme.textPrimary)

                        Spacer()

                        Button {
                            jumpToConversation()
                        } label: {
                            HStack(spacing: 4) {
                                Text("JUMP")
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.textMuted)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                    }

                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("\(stats.sentCount)")
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("SENT")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(AppTheme.cardBorder)
                            .frame(width: 1, height: 44)

                        VStack(spacing: 4) {
                            Text("\(stats.receivedCount)")
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("RECEIVED")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Rectangle()
                        .fill(AppTheme.divider)
                        .frame(height: 1)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TOTAL")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Text(stats.totalDurationFormatted)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .center, spacing: 4) {
                            Text("AVG")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Text(stats.averageDurationFormatted)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("LONGEST")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Text(stats.longestDurationFormatted)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }

                    Text("\(stats.totalCount) VOICE MESSAGES TOTAL")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private func jumpToConversation() {
        if let phone = stats?.contactPhoneNumber,
           let encoded = phone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "sms://\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    VoiceMessagesCard(stats: MockDataProvider.messageStats.voiceMessages)
        .padding()
        .background(AppTheme.background)
}
