import SwiftUI

struct FaceTimeCard: View {
    let stats: FaceTimeStats

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("FACETIME VS PHONE")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    if let lastFT = stats.lastFaceTimeFormatted {
                        Text("LAST FT \(lastFT.uppercased())")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(stats.videoCallCount)")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("VIDEO")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                        Text(stats.videoDurationFormatted)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(AppTheme.cardBorder)
                        .frame(width: 1, height: 70)

                    VStack(spacing: 6) {
                        Image(systemName: "phone.arrow.up.right.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(stats.audioCallCount)")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("FT AUDIO")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                        Text(stats.audioFTDurationFormatted)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(AppTheme.cardBorder)
                        .frame(width: 1, height: 70)

                    VStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(stats.regularCallCount)")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("PHONE")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                        Text(stats.regularDurationFormatted)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                GeometryReader { geometry in
                    let total = Double(stats.videoCallCount + stats.audioCallCount + stats.regularCallCount)
                    let videoW = total > 0 ? geometry.size.width * Double(stats.videoCallCount) / total : 0
                    let audioW = total > 0 ? geometry.size.width * Double(stats.audioCallCount) / total : 0

                    HStack(spacing: 1) {
                        if videoW > 0 {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(AppTheme.textPrimary)
                                .frame(width: videoW)
                        }
                        if audioW > 0 {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(AppTheme.barFill)
                                .frame(width: audioW)
                        }
                        RoundedRectangle(cornerRadius: 1)
                            .fill(AppTheme.barEmpty)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

#Preview {
    FaceTimeCard(stats: MockDataProvider.callStats.faceTimeStats)
        .padding()
        .background(AppTheme.background)
}
