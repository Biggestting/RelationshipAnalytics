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

                // Three-way split
                HStack(spacing: 0) {
                    // FaceTime Video
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
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: 70)

                    // FaceTime Audio
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
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: 70)

                    // Regular Phone
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

                // Proportion bar
                GeometryReader { geometry in
                    let total = Double(stats.videoCallCount + stats.audioCallCount + stats.regularCallCount)
                    let videoW = total > 0 ? geometry.size.width * Double(stats.videoCallCount) / total : 0
                    let audioW = total > 0 ? geometry.size.width * Double(stats.audioCallCount) / total : 0

                    HStack(spacing: 1) {
                        if videoW > 0 {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: videoW)
                        }
                        if audioW > 0 {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.5))
                                .frame(width: audioW)
                        }
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.2))
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
        .background(Color.black)
}
